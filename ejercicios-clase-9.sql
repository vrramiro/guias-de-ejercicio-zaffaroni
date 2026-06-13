-- a

/*
1. Crear la tabla CustomerStatistics con los siguientes campos customer_num
(entero y pk), ordersQty (entero), maxDate (date), productsQty (entero)
*/

create table CustomerStatistics (
	customer_num smallint primary key,
	ordersQty int,
	maxDate date,
	productsQty int
)
go

/*
2. Crear un procedimiento ‘CustomerStatisticsUpdate’ que reciba el parámetro
fecha_DES (date) y que en base a los datos de la tabla Customer, inserte (si
no existe) o actualice el registro de la tabla CustomerStatistics con la
siguiente información:
ordersqty: cantidad de órdenes (si no existe la fila para ese cliente)
+ la cantidad de órdenes con fecha mayor o igual a fecha_DES (si ya existe)
maxDate: fecha de la última órden del cliente.
productsQty: cantidad única de productos adquiridos por cada
cliente histórica
*/

-- hay cosas que estan mal
-- El calculo de la cantidad de productos distintos
-- Cambiar el where de la query para obtener los de fecha mayor o igual desde el principio

create procedure CustomerStatisticsUpdate(@fecha_DES date)
as
	declare @customer_num smallint, @ordersQty int, @ordersFromDateQty int, @maxDate date, @productsQty int

	declare curCustomer cursor for
	select
	c.customer_num,
	count(distinct o.order_num),
	max(o.order_date),
	count(distinct i.stock_num)
	from customer c
	join orders o on o.customer_num = c.customer_num
	join items i on i.order_num = o.order_num
	group by c.customer_num

	open curCustomer

	fetch curCustomer into @customer_num, @ordersQty, @maxDate, @productsQty
	while(@@FETCH_STATUS = 0)
	begin
		if(exists (select 1 from CustomerStatistics where customer_num = @customer_num))
		begin
			select @ordersFromDateQty = count(distinct order_num) 
			from orders 
			where customer_num = @customer_num
				and order_date >= @fecha_DES 

			update CustomerStatistics
			set 
			ordersQty = ordersQty + @ordersFromDateQty,
			maxDate = @maxDate,
			productsQty = @productsQty
			where customer_num = @customer_num
		end
		else
		begin
			insert into CustomerStatistics(customer_num, ordersQty, maxDate, productsQty)
			values (@customer_num, @ordersQty, @maxDate, @productsQty)
		end

		fetch curCustomer into @customer_num, @ordersQty, @maxDate, @productsQty
	end
	
	close curCustomer
	deallocate curCustomer 
go

/*
alter procedure CustomerStatisticsUpdate(@fecha_DES date) as
begin
    declare @customer_num smallint, @ordersQty int, 
         @maxDate date, @productsQty int

    declare curCustomer cursor for
         select c.customer_num, count(o.order_num), max(o.order_date)
           from customer c join orders o on o.customer_num = c.customer_num
          where o.order_date >= @fecha_DES 
          group by c.customer_num;

    open curCustomer
    fetch curCustomer into @customer_num, @ordersQty, @maxDate
    while(@@FETCH_STATUS = 0)
    begin
        SELECT @productsQty = COUNT(*) 
          FROM (SELECT DISTINCT i.stock_num, i.manu_code 
                  FROM orders o JOIN items i ON o.order_num = i.order_num
                 where o.customer_num = @customer_num) AUX;
        if exists (select 1 from CustomerStatistics 
                    where customer_num = @customer_num)
        begin
            update CustomerStatistics
              set ordersQty = ordersQty + @ordersQty,
                  maxDate = @maxDate,
                  productsQty = @productsQty
            where customer_num = @customer_num;
        end
        else
        begin
            insert into CustomerStatistics(customer_num, ordersQty, maxDate, productsQty)
            values (@customer_num, @ordersQty, @maxDate, @productsQty)
        end
        fetch curCustomer into @customer_num, @ordersQty, @maxDate
    end
    close curCustomer
    deallocate curCustomer 
end;
*/

select * from orders;
exec CustomerStatisticsUpdate '2015-05-17 00:00:00.000';

select * from CustomerStatistics;

-- b

/*
3.Crear la tabla informeStock con los siguientes campos: fechaInforme (date),
stock_num (entero), manu_code (char(3)), cantOrdenes (entero), UltCompra
(date), cantClientes (entero), totalVentas (decimal). PK (fechaInforme,
stock_num, manu_code)
*/

drop table informeStock;

create table informeStock (
	fechaInforme date,
	stock_num smallint,
	manu_code char(3),
	cantOrdenes int,
	ultCompra date,
	cantClientes int,
	totalVentas decimal(10,2),
	constraint PK_informeStock primary key (fechaInforme, stock_num, manu_code)
)
go

alter table informeStock 
alter column totalVentas decimal(10, 2);

/*
4. Crear un procedimiento ‘generarInformeGerencial’ que reciba un parámetro
fechaInforme y que en base a los datos de la tabla PRODUCTS de todos los
productos existentes, inserte un registro de la tabla informeStock con la
siguiente información:

	fechaInforme: fecha pasada por parámetro
	stock_num: número de stock del producto
	manu_code: código del fabricante
	cantOrdenes: cantidad de órdenes que contengan el producto.
	UltCompra: fecha de última orden para el producto evaluado.
	cantClientes: cantidad de clientes únicos que hayan comprado el
	producto.
	totalVentas: Sumatoria de las ventas de ese producto (p x q)

Validar que no exista en la tabla informeStock un informe con la misma
fechaInforme recibida por parámetro.
*/

alter procedure generarInformeGerencial(@fechaInforme date)
as
begin
	
	if exists (select 1 from informeStock where fechaInforme = @fechaInforme)
	begin;
		throw 51000, 'Ya existe este informe.', 1;		
	end

	insert into informeStock 
	(fechaInforme, stock_num, manu_code, cantOrdenes, ultCompra, cantClientes, totalVentas)
	select
	@fechaInforme,
	p.stock_num, 
	p.manu_code,
	coalesce(count(o.order_num), 0),
	max(o.order_date),
	coalesce(count(distinct o.customer_num), 0),
	(select coalesce(sum(i2.quantity * i2.unit_price), 0) from items i2 where i2.manu_code = p.manu_code and i2.stock_num = p.stock_num)
	from products p
	left join items i on i.stock_num = p.stock_num and i.manu_code = p.manu_code
	left join orders o on o.order_num = i.order_num
	-- es necesario proque si el item es nulo, el inner join elimina la fila por no tener orden para le item
	-- quiero la fila de todas formas
	group by p.stock_num, p.manu_code

end
go

/*
	insert into informeStock 
	(fechaInforme, stock_num, manu_code, cantOrdenes, ultCompra, cantClientes, totalVentas)
	select
	@fechaInforme,
	i.stock_num, 
	i.manu_code,
	count(o.order_num),
	max(o.order_date),
	count(distinct o.customer_num),
	(select sum(i2.quantity * i2.unit_price) from items i2 where i2.manu_code = i.manu_code and i2.stock_num = i.stock_num)
	from items i
	join orders o on o.order_num = i.order_num
	group by i.stock_num, i.manu_code

	Este insert está mal, no estoy teniendo en cuenta los productos que NUNCA SE VENDIERON
*/

execute generarInformeGerencial '2025-08-02'

select * from informeStock