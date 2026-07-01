-- PUNTO 1
--Las diferencias entre funciones y stored procedures:
--Las funciones no pueden cambiar el estado interno de valores y que retorna una tabla con n valores siendo n >= 0.
--Son usados para integrar consultas SQL, mientras que los stored procedures para secuencias de operaciones de instrucciones.

---- PUNTO 2 

--Triggers: se puede hacer validaciones correspondientes para asegurarse de que los valores ingresados no sean distintos
--a supuestos valores almacenados en la columna.
--PK: por propiedad de univocavidad permite que no haya un valor en esa columna de esa tabla igual.
--FK: debe referir a una PK de otra tabla y genera una dependencia donde se debe eliminar en un cierto orden.
--Mantiene la integridad de esa forma.

-- PUNTO 3
--Crear una consulta que muestre de las tres Estados que tengan la mayor cantidad de VENTAS (no
--compras): Nombre del Estado, monto total vendido en ese Estado, nombre del fabricante y cantidad vendida total de ese fabricante en esa provincia.
--Solo se deberán mostrar en la consulta los fabricantes cuyas ventas totales superen el 15% de las ventas de su provincia.
--Ordenar el resultado por el monto total vendido del Estado de mayor a menor y por monto vendido del fabricante de manera descendente.
--Notas: Se puede utilizar SOLO UN subquery. No usar Store procedures, ni funciones de usuarios, ni tablas temporales.

-- tengo que obtener las 3 provincias con mas ventas

-- si lo encaro así necesito dos subquerys xq despues tengo que resolver el having con el total y el total de la provincia, a parte el total que estoy mostrando
-- es el completo, no de la provincia

select
s.[state] estado,
s.sname nombre_estado,
s.monto_tota_provincia,
m.manu_name nombre_fabricante,
sum(i.quantity) total_fabricante,
sum(i.quantity*i.unit_price) monto_total_fabricante
from manufact m
join (select top 3
ss.[state],
ss.sname,
sum(ii.quantity) total_provincia,
sum(ii.quantity*ii.unit_price) monto_tota_provincia
from state ss  
join manufact mm on mm.[state] = ss.[state]
join items ii on ii.manu_code = mm.manu_code
group by ss.[state], ss.sname
order by total_provincia desc) s on s.[state] = m.[state]
join items i on i.manu_code = m.manu_code
group by s.[state], m.manu_name, s.total_provincia, s.monto_tota_provincia, s.sname
having sum(i.quantity) > 0.15*s.total_provincia
order by s.monto_tota_provincia desc, monto_total_fabricante desc

-- PUNTO 4

--Crear un procedimiento ResumenMensualPR que reciba una fecha como parámetro. Este
--Procedure deberá guardar en una tabla VENTASxMES el Monto total y las cantidades totales
--de unidades vendidas de productos para el Año y mes (yyyymm) de la fecha ingresada como
--parámetro.
--Dependiendo del atributo unit correspondiente a la unidad del producto las cantidades
--deberán ser “ajustadas” según la siguiente tabla:
--		Box: Se multiplica la cantidad x 12
--		Case: Se multiplica la cantidad x 6
--		Pair: Se multiplica la cantidad x 2
--		Each: Las cantidades no se ajustan.

--Tabla VENTASxMES
--	anioMes varchar(6) PK
--	stock_num smallint PK
--	manu_code char(3) PK
--	Cantidad int
--	Monto decimal(10,2)
--El procedimiento debe manejar TODO el proceso en una transacción y deshacer todas
--las operaciones en caso de error.

create table ventasPorMes (
    anioMes varchar(6),
	stock_num smallint,
	manu_code char(3),
	cantidad int,
	monto decimal(10,2),
    constraint PK_ventapormes primary key (anioMes, stock_num, manu_code)
)

select * from units
go

alter procedure ResumenMensualPR(@fecha date)
as 
begin
    begin transaction
        begin try

            declare cursorProductos cursor for
            select
            cast(year(o.order_date) as varchar(4)) + cast(month(o.order_date) as varchar(2)),
            p.stock_num,
            p.manu_code,
            sum(i.quantity),
            sum(i.quantity * i.unit_price),
            u.unit
            from items i
            join products p on i.stock_num = p.stock_num and i.manu_code = p.manu_code
            join orders o on o.order_num = i.order_num
            join units u on u.unit_code = p.unit_code
            where year(o.order_date) = year(@fecha) and month(o.order_date) = month(@fecha)
            group by p.stock_num, p.manu_code, u.unit, month(o.order_date), year(o.order_date)

            declare @anioMes varchar(6), @stock_num smallint, @manu_code char(3), @cantidad int, @monto decimal(10,2), @unit char(4)
            open cursorProductos
            fetch cursorProductos into @anioMes, @stock_num, @manu_code, @cantidad, @monto, @unit
            while @@FETCH_STATUS = 0
            begin
                if @unit = 'box' begin set @cantidad = @cantidad * 12 end
                if @unit = 'case' begin set @cantidad = @cantidad * 6 end
                if @unit = 'pair' begin set @cantidad = @cantidad * 2 end

                insert into ventasPorMes (anioMes, stock_num, manu_code, cantidad, monto) values 
                (@anioMes, @stock_num, @manu_code, @cantidad, @monto)

                fetch cursorProductos into @anioMes, @stock_num, @manu_code, @cantidad, @monto, @unit
            end
            close cursorProductos
            deallocate cursorProductos
        end try
        begin catch
            rollback transaction
            ;throw
        end catch
    commit transaction
end

execute ResumenMensualPR '2015-07-05'
select * from ventasPorMes
go

---- PUNTO 5
--Se cuenta con una tabla PermisosxProducto que contiene por cada customer_num los
--productos que este cliente puede comprar.
--La estructura de la tabla es la siguiente:
--(Customer_num, Manu_code, Stock_num)
--Se pide crear un trigger que ante la inserción de una o varias filas en la tabla ítems,
--valide que el customer_num de la orden a la que pertenece cada ítem tenga permiso de
--compra sobre el producto asociado a dicho ítem (manu_code+stock_num).

--En caso que el cliente (customer_num) no tenga permisos (no exista un registro en la
--tabla permisosPorProducto) se deberá cancelar la inserción enviando un mensaje de
--error y deshacer todas las operaciones realizadas
--Nota: Las inserciones pueden ser masivas.

create table permisosPorProducto (
    customer_num smallint,
    manu_code char(3),
    stock_num smallint
)
go

create trigger controlDePermisosItems
on items
instead of insert
as
begin
    begin transaction
        if exists (select 1 from inserted i 
        join orders o on o.order_num = i.order_num
        join customer c on c.customer_num = o.customer_num
        where not exists (select 1 from permisosPorProducto ppp 
                        where ppp.customer_num = c.customer_num 
                        and ppp.manu_code = i.item_num 
                        and ppp.stock_num = i.stock_num))
        begin
            delete from orders where order_num in (select i.order_num from inserted i)
            ;throw 50001, 'No hay permisos para esta compra', 1
        end

        insert into items
        select * from inserted
    commit transaction
end
go 

create trigger controlDePermisosItems2
on items
instead of insert
as
begin
    begin transaction
        if exists (select o.customer_num, i.stock_num, i.manu_code from inserted i join orders o on o.order_num = i.order_num
                   except
                   select p.customer_num, p.stock_num, p.manu_code from permisosPorProducto p)
        begin
            rollback transaction
            ;throw 50001, 'No hay permisos para esta compra', 1
        end

        insert into items
        select * from inserted
    commit transaction
end