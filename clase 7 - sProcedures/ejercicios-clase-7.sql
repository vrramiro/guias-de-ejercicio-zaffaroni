use Comercial;

/*
a- 
Stored Procedures
Crear la siguiente tabla CustomerStatistics con los siguientes campos
customer_num (entero y pk), ordersqty (entero), maxdate (date), uniqueProducts
(entero)
Crear un procedimiento �actualizaEstadisticas� que reciba dos par�metros
customer_numDES y customer_numHAS y que en base a los datos de la tabla
customer cuyo customer_num est�n en en rango pasado por par�metro, inserte (si
no existe) o modifique el registro de la tabla CustomerStatistics con la siguiente
informaci�n:
Ordersqty contedr� la cantidad de �rdenes para cada cliente.
Maxdate contedr� la fecha m�xima de la �ltima �rde puesta por cada cliente.
uniqueProducts contendr� la cantidad �nica de tipos de productos adquiridos
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
Crear un procedimiento �migraClientes� que reciba dos par�metros
customer_numDES y customer_numHAS y que dependiendo el tipo de cliente y la
cantidad de �rdenes los inserte en las tablas clientesCalifornia, clientesNoCaBaja,
clienteNoCAAlta.

� El procedimiento deber� migrar de la tabla customer todos los
clientes de California a la tabla clientesCalifornia, los clientes que no
son de California pero tienen m�s de 999u$ en OC en
clientesNoCaAlta y los clientes que tiene menos de 1000u$ en OC en
la tablas clientesNoCaBaja.
� Se deber� actualizar un campo status en la tabla customer con valor
�P� Procesado, para todos aquellos clientes migrados.
� El procedimiento deber� contemplar toda la migraci�n como un lote,
en el caso que ocurra un error, se deber� informar el error ocurrido y
abortar y deshacer la operaci�n.
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

execute migrarClientes 100, 140;

select * from clientesCalifornia;
go

/*
c.
Crear un procedimiento �actualizaPrecios� que reciba como par�metros
manu_codeDES, manu_codeHAS y porcActualizacion que dependiendo del tipo de
cliente y la cantidad de �rdenes genere las siguientes tablas listaPrecioMayor y
listaPreciosMenor. Ambas tienen las misma estructura que la tabla Productos.
� El procedimiento deber� tomar de la tabla stock todos los productos que
correspondan al rango de fabricantes asignados por par�metro.
Por cada producto del fabricante se evaluar� la cantidad (quantity) comprada.
Si la misma es mayor o igual a 500 se grabar� el producto en la tabla
listaPrecioMayor y el unit_price deber� ser actualizado con (unit_price *
(porcActualizaci�n *0,80)),
Si la cantidad comprada del producto es menor a 500 se actualizar� (o insertar�)
en la tabla listaPrecioMenor y el unit_price se actualizar� con (unit_price *
porcActualizacion)
� Asimismo, se deber� actualizar un campo status de la tabla stock con valor �A�
Actualizado, para todos aquellos productos con cambio de precio actualizado.
� El procedimiento deber� contemplar todas las operaciones de cada fabricante
como un lote, en el caso que ocurra un error, se deber� informar el error ocurrido
y deshacer la operaci�n de ese fabricante.
*/

-- como se tiene que contemplar las operaciones DE CADA FABRICANTE como un lote
-- entonces por cada uno de los manufact se abre una transaccion
-- eso me permite rollbackear solo la transacción del manufact en ese momento
-- y no la de todos los demás

create table listaPrecioMayor (
	stock_num smallint,
	manu_code char(3),
	unit_price decimal(6,2),
	unit_code smallint,
	status char(1)
)

create table listaPrecioMenor (
	stock_num smallint,
	manu_code char(3),
	unit_price decimal(6,2),
	unit_code smallint,
	status char(1)
)
go

create procedure actualizarPrecios(@manu_codeDES char(3), @manu_codeHAS char(3), @porcActualizacion decimal(6, 2))
as 
begin

	declare manufactCursor cursor for
	select m.manu_code 
	from manufact m
	where m.manu_code between @manu_codeDES and @manu_codeHAS

	declare @manu_code char(3)

	open manufactCursor
	fetch manufactCursor into @manu_code
	while @@FETCH_STATUS = 0
	begin
		begin transaction
		begin try
			insert into listaPrecioMayor (stock_num, manu_code, unit_price, unit_code, status)
			select
			p.stock_num, p.manu_code, p.unit_price, p.unit_code, 'A'
			from products p
			join items i on i.stock_num = p.stock_num and i.manu_code = p.manu_code
			where p.manu_code = @manu_code
			group by p.stock_num, p.manu_code, p.unit_price, p.unit_code, p.[status]
			having sum(i.quantity) >= 500

			insert into listaPrecioMenor (stock_num, manu_code, unit_price, unit_code, status)
			select
			p.stock_num, p.manu_code, p.unit_price, p.unit_code, 'A'
			from products p
			join items i on i.stock_num = p.stock_num and i.manu_code = p.manu_code
			where p.manu_code = @manu_code
			group by p.stock_num, p.manu_code, p.unit_price, p.unit_code, p.[status]
			having sum(i.quantity) < 500

			update products
			set unit_price = unit_price * @porcActualizacion * 0.8, status = 'A'
			where manu_code = @manu_code 
			and stock_num in (select stock_num from listaPrecioMayor lpm where lpm.manu_code = @manu_code)

			update products
			set unit_price = unit_price * @porcActualizacion, status = 'A'
			where manu_code = @manu_code
			and stock_num in (select stock_num from listaPrecioMenor lpm where lpm.manu_code = @manu_code)
		end try
		begin catch
			rollback transaction
		end catch
		commit transaction
		fetch manufactCursor into @manu_code
	end
	close manufactCursor
	deallocate manufactCursor

end

select * from manufact

execute actualizarPrecios 'ANZ', 'KAR', 0.2

select * from listaPrecioMenor
select * from products where status = 'A'