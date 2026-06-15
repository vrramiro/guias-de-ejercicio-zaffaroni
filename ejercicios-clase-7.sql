use Comercial;

/*
a- 
Stored Procedures
Crear la siguiente tabla CustomerStatistics con los siguientes campos
customer_num (entero y pk), ordersqty (entero), maxdate (date), uniqueProducts
(entero)
Crear un procedimiento ‘actualizaEstadisticas’ que reciba dos parámetros
customer_numDES y customer_numHAS y que en base a los datos de la tabla
customer cuyo customer_num estén en en rango pasado por parámetro, inserte (si
no existe) o modifique el registro de la tabla CustomerStatistics con la siguiente
información:
Ordersqty contedrá la cantidad de órdenes para cada cliente.
Maxdate contedrá la fecha máxima de la última órde puesta por cada cliente.
uniqueProducts contendrá la cantidad única de tipos de productos adquiridos
por cada cliente.
*/

drop table CustomerStatistics; 
go

create table CustomerStatistics (
	customer_num integer primary key,
	ordersqty integer,
	maxdate date,
	uniqueProducts integer
);
go

alter procedure actualizaEstadisticas2(@customer_numDES integer, @customer_numHAS integer)
as
begin

	declare customerCursor cursor for
		select 
		c.customer_num,
		count(distinct o.order_num),
		max(o.order_date),
		count(distinct i.stock_num)
		from customer c
		join orders o on c.customer_num = o.customer_num
		join items i on o.order_num = i.order_num
		where c.customer_num between @customer_numDES and @customer_numHAS
		group by c.customer_num
	
	declare @customer_num integer
	declare @ordersqty integer
	declare @maxdate date
	declare @uniqueProducts integer

	open customerCursor
	fetch customerCursor into @customer_num, @ordersqty, @maxdate, @uniqueProducts
	while(@@FETCH_STATUS = 0)
		begin
			if @customer_num not in (select customer_num from CustomerStatistics)
				begin
					insert into CustomerStatistics (customer_num, ordersqty, maxdate, uniqueProducts)
					values (@customer_num, @ordersqty, @maxdate, @uniqueProducts)
				end
			else
				begin
					update CustomerStatistics
					set
						ordersqty = @ordersqty,
						maxdate = @maxdate,
						uniqueProducts = @uniqueProducts
					where customer_num = @customer_num
				end
			fetch customerCursor into @customer_num, @ordersqty, @maxdate, @uniqueProducts
		end
		close customerCursor
		deallocate customerCursor
end
go

execute actualizaEstadisticas2 101, 128;

-- usando un merge
begin transaction

merge CustomerStatistics as d
using (
	select c.customer_num customer_num,
	count(distinct o.order_num) ordersqty,
	max(o.order_date) maxdate,
	count(distinct i.stock_num) uniqueProducts
	from customer c
	join orders o on o.customer_num = c.customer_num
	join items i on i.order_num = o.order_num
	group by c.customer_num
) as s
on d.customer_num = s.customer_num
when matched then
	update set d.ordersqty = s.ordersqty, d.maxdate = s.maxdate, d.uniqueProducts = s.uniqueProducts
when not matched then
	insert (customer_num, ordersqty, maxdate, uniqueProducts) values (s.customer_num, s.ordersqty, s.maxdate, s.uniqueProducts);

select * from CustomerStatistics

commit transaction
rollback transaction

select * from customer
go
/*
b-
Crear un procedimiento ‘migraClientes’ que reciba dos parámetros
customer_numDES y customer_numHAS y que dependiendo el tipo de cliente y la
cantidad de órdenes los inserte en las tablas clientesCalifornia, clientesNoCaBaja,
clienteNoCAAlta.

• El procedimiento deberá migrar de la tabla customer todos los
clientes de California a la tabla clientesCalifornia, los clientes que no
son de California pero tienen más de 999u$ en OC en
clientesNoCaAlta y los clientes que tiene menos de 1000u$ en OC en
la tablas clientesNoCaBaja.
• Se deberá actualizar un campo status en la tabla customer con valor
‘P’ Procesado, para todos aquellos clientes migrados.
• El procedimiento deberá contemplar toda la migración como un lote,
en el caso que ocurra un error, se deberá informar el error ocurrido y
abortar y deshacer la operación.
*/

create table clientesCalifornia (
	customer_num smallint primary key,
	fname varchar(15),
	lname varchar(15),
	company varchar(20),
	address1 varchar(20),
	address2 varchar(20),
	city varchar(15),
	state char(2),
	zipcode char(5),
	phone varchar(18),
	customer_num_referedBy smallint
	constraint state_cli_ca_FK foreign key (state) references state(state),
	constraint customer_num_referedBy1_FK foreign key (customer_num_referedBy) references customer(customer_num)
);


create table clientesNoCaBaja (
	customer_num smallint primary key,
	fname varchar(15),
	lname varchar(15),
	company varchar(20),
	address1 varchar(20),
	address2 varchar(20),
	city varchar(15),
	state char(2),
	zipcode char(5),
	phone varchar(18),
	customer_num_referedBy smallint
	constraint state_cli_no_ca_baja_FK foreign key (state) references state(state),
	constraint customer_num_referedBy2_FK foreign key (customer_num_referedBy) references customer(customer_num)
);

create table clientesNoCaAlta (
	customer_num smallint primary key,
	fname varchar(15),
	lname varchar(15),
	company varchar(20),
	address1 varchar(20),
	address2 varchar(20),
	city varchar(15),
	state char(2),
	zipcode char(5),
	phone varchar(18),
	customer_num_referedBy smallint
	constraint state_cli_no_ca_alta_FK foreign key (state) references state(state),
	constraint customer_num_referedBy3_FK foreign key (customer_num_referedBy) references customer(customer_num)
);
go

drop table clientesCalifornia;
drop table clientesNoCaAlta;
drop table clientesNoCaBaja;
go

alter procedure migrarClientes (@customer_numDES smallint, @customer_numHAS smallint)
as
begin

	begin transaction
	begin try
		insert into clientesCalifornia
		select
		c.customer_num,
		c.fname,
		c.lname,
		c.company,
		c.address1,
		c.address2,
		c.city,
		c.state,
		c.zipcode,
		c.phone,
		c.customer_num_referedBy
		from customer c
		where state = 'CA' 
		and customer_num >= @customer_numDES 
		and customer_num <= @customer_numHAS

		insert into clientesNoCaAlta
		select
		c.customer_num,
		c.fname,
		c.lname,
		c.company,
		c.address1,
		c.address2,
		c.city,
		c.state,
		c.zipcode,
		c.phone,
		c.customer_num_referedBy
		from customer c 
		join orders o on o.customer_num = c.customer_num 
		join items i on i.order_num = o.order_num
		where c.state <> 'CA'
		and c.customer_num >= @customer_numDES 
		and c.customer_num <= @customer_numHAS
		group by c.customer_num, c.fname, c.lname, c.company, c.address1, c.address2, c.city, c.state, c.zipcode, c.phone, c.customer_num_referedBy
		having c.state <> 'CA' and sum(i.quantity * i.unit_price) > 999

		insert into clientesNoCaBaja
		select
		c.customer_num,
		c.fname,
		c.lname,
		c.company,
		c.address1,
		c.address2,
		c.city,
		c.state,
		c.zipcode,
		c.phone,
		c.customer_num_referedBy
		from customer c 
		join orders o on o.customer_num = c.customer_num 
		join items i on i.order_num = o.order_num
		where c.state <> 'CA'
		and c.customer_num >= @customer_numDES 
		and c.customer_num <= @customer_numHAS
		group by c.customer_num, c.fname, c.lname, c.company, c.address1, c.address2, c.city, c.state, c.zipcode, c.phone, c.customer_num_referedBy
		having sum(i.quantity * i.unit_price) < 1000

		update customer
		set status = 'P'
		where customer_num in (
			select customer_num
			from clientesCalifornia
			union
			select customer_num
			from clientesNoCaAlta
			union
			select customer_num
			from clientesNoCaBaja
			
		)
		commit transaction
	end try
	begin catch
		rollback transaction
		throw;
	end catch 

end
go

execute migrarClientes 100, 140

select * from clientesCalifornia