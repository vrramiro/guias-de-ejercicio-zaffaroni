use Comercial;

/*
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