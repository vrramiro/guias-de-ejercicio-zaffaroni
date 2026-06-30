/*
1. Dada la tabla Products de la base de datos stores7 se requiere crear una tabla Products_historia_precios 
y crear un trigger que registre los cambios de precios que se hayan producido en la tabla Products.

Tabla Products_historia_precios
	 Stock_historia_Id Identity (PK)
	 Stock_num
	 Manu_code
	 fechaHora (grabar fecha y hora del evento)
	 usuario (grabar usuario que realiza el cambio de precios)
	 unit_price_old
	 unit_price_new
	 estado char default ‘A’ check (estado IN (‘A’,’I’)
*/

create table Products_historia_precios (
	stock_historia_id int identity(1, 1) primary key,
	stock_num smallint,
	manu_code char(3),
	fechaHora datetime default sysdatetime(),
	usuario varchar(50) default system_user,
	unit_price_old decimal(6,2),
	unit_price_new decimal(6,2),
	estado char default('A'),
	constraint estado_in check(estado in ('A', 'I'))
);
go

drop table Products_historia_precios;
go

alter trigger registrar_cambio_precio 
on products
after update
as
begin

	/*
	declare @stock_num smallint, @manu_code char(3), @unit_price_old decimal(6,2), @unit_price_new decimal(6,2)

	select
		@stock_num = i.stock_num,
		@manu_code = i.manu_code,
		@unit_price_old = d.unit_price,
		@unit_price_new = i.unit_price
	from deleted d
	join inserted i on i.stock_num = d.stock_num and i.manu_code = d.manu_code
	where d.unit_price <> i.unit_price

	insert into Products_historia_precios(stock_num, manu_code, fechaHora, unit_price_old, unit_price_new)
	values (@stock_num, @manu_code, getdate(), @unit_price_old, @unit_price_new)

	Hacerlo así rompe con un update masivo, dado que se está haciendo una asignación de variables que corresponde
	solo a un único registro. Debemos usar necesariamente un insert select, salvo que se desee usar un cursos (aunque
	no es recomendable).
	*/

	insert into Products_historia_precios 
		(stock_num, manu_code, unit_price_old, unit_price_new)
	select
		i.stock_num,
		i.manu_code,
		d.unit_price,
		i.unit_price
	from deleted d
	join inserted i on i.stock_num = d.stock_num and i.manu_code = i.manu_code
	where i.unit_price <> d.unit_price
end;
go

select * from products;

update products
set unit_price = 700.0
where stock_num in (1, 2);

select * from Products_historia_precios;
go

/*
2. Crear un trigger sobre la tabla Products_historia_precios que ante un delete sobre la misma
realice en su lugar un update del campo estado de ‘A’ a ‘I’ (inactivo).
*/

create trigger soft_delete_historia_producto
on Products_historia_precios
instead of delete
as
begin

	update Products_historia_precios
	set estado = 'I'
	where stock_historia_id in (
		select stock_historia_id
		from deleted
	)

end;
go

delete from Products_historia_precios where stock_historia_id in (1, 2);

select * from Products_historia_precios;
go

/*
3. Validar que sólo se puedan hacer inserts en la tabla Products en un horario entre las 8:00 AM y
8:00 PM. En caso contrario enviar un error por pantalla.
*/

create trigger validar_horario_insert
on products
after insert
as
begin
	
	if(cast(getdate() as time) not between '08:00:00' and '20:00:00')
	begin
		rollback;
		throw 51000, 'Inserción fuera de horario', 1;
	end;

end;
go

select * from products where stock_num = 2 and manu_code = 'ANZ';

insert into products(stock_num, manu_code, unit_price, unit_code, status) 
values (2, 'ANZ', 45.0, 6, 'A');
go

/*
4. Crear un trigger que ante un borrado sobre la tabla ORDERS realice un borrado en cascada
sobre la tabla ITEMS, validando que sólo se borre 1 orden de compra.
Si detecta que están queriendo borrar más de una orden de compra, informará un error y
abortará la operación.
*/

alter trigger validar_delete_orders_items
on orders
instead of delete
as
begin

	if((select count(*) from deleted) > 1)
	begin;
		throw 51000, 'Error al eliminar. Solo puede borrarse una orden a la vez.', 1
	end;

	delete from items
	where order_num = (select order_num from deleted)

	delete from orders
	where order_num = (select order_num from deleted)

end;
go

select * from orders;
select * from items;

delete from orders where order_num in (1002, 1003);
go

/*
5. Crear un trigger de insert sobre la tabla ítems que al detectar que el código de fabricante
(manu_code) del producto a comprar no existe en la tabla manufact, inserte una fila en dicha
tabla con el manu_code ingresado, en el campo manu_name la descripción ‘Manu Orden 999’
donde 999 corresponde al nro. de la orden de compra a la que pertenece el ítem y en el campo
lead_time el valor 1.
*/

alter trigger itemSinManufact
on items
instead of insert 
as
begin
	insert into manufact (manu_code, manu_name, lead_time)
	select
	i.manu_code,
	'Manu Orden ' + cast(i.order_num as varchar(1000)),
	1 
	from inserted i
	left join manufact m on i.manu_code = m.manu_code
	where m.manu_code is null
	group by i.manu_code, i.order_num
end

select * from products
select * from items

insert into items values 
(7, 1000, 4, 'HRO', 1, 980.00),
(7, 1564, 4, 'ÑLK', 1, 980.00),
(7, 2341, 4, 'MBO', 1, 980.00),
(7, 4442, 4, 'BOB', 1, 980.00)

select * from manufact where manu_code in ('ÑLK', 'MBO', 'BOB')

-- 6
