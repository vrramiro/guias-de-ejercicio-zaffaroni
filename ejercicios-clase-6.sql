use Comercial

select c.lname + ', ' + c.fname, c.customer_num
from customer c join cust_calls cc on c.customer_num = cc.customer_num
group by c.lname, c.fname, c.customer_num
having count(*) > 1;

select count(*)
from customer c1
join customer c2
on c1.city = c2.city 
-- estamos haciendo joins por campos NO PK
-- y eso no es un problema
where c2.lname = 'Higgins';



/*
1.
Mostrar el Código del fabricante, nombre del fabricante, tiempo de entrega y monto
Total de productos vendidos, ordenado por nombre de fabricante. En caso que el
fabricante no tenga ventas, mostrar el total en NULO.
*/

select m.manu_code codigo_fabricante,
m.manu_name nombre_fabricante,
m.lead_time,
coalesce(sum(i.quantity * i.unit_price), 0) monto_total_productos_vendidos
from manufact m left join items i on m.manu_code = i.manu_code
group by m.manu_code, m.manu_name, m.lead_time;

/*
2.
Mostrar en una lista de a pares, el código y descripción del producto, y los pares de
fabricantes que fabriquen el mismo producto. En el caso que haya un único fabricante
deberá mostrar el Código de fabricante 2 en nulo. Ordenar el resultado por código de
producto.

El listado debe tener el siguiente formato:
Nro. de Producto	Descripcion		Cód. de fabric.1	Cód. de fabric.2
(stock_num)			(Description)		(manu_code)			(manu_code)
*/

select pt.stock_num, pt.description, p1.manu_code, p2.manu_code
from product_types pt
join products p1 on pt.stock_num = p1.stock_num
left join products p2 on pt.stock_num = p2.stock_num
and p1.manu_code <> p2.manu_code;

-- el problema de esta resolución es que aparecen cosas dos veces pero con cod1 y cod2
-- dados vuelta.
-- quiero sacar las filas que se refieren a lo mismo

select pt.stock_num, pt.description, p1.manu_code, p2.manu_code
from product_types pt
join products p1 on pt.stock_num = p1.stock_num
left join products p2 on pt.stock_num = p2.stock_num
where p1.manu_code < p2.manu_code or p2.manu_code is null;

-- de esta manera lo tenemos en cuenta desde el codigo que sea menor, y no se tiene 
-- en cuenta el caso contrario.

select pt.stock_num, pt.description, p1.manu_code, p2.manu_code
from product_types pt
join products p1 on pt.stock_num = p1.stock_num
left join products p2 on pt.stock_num = p2.stock_num
where p1.manu_code > p2.manu_code or p2.manu_code is null;

-- esto seria al revés

/*
3.
Listar todos los clientes que hayan tenido más de una orden.
a) En primer lugar, escribir una consulta usando una subconsulta.
b) Reescribir la consulta utilizando GROUP BY y HAVING.
*/

-- a)
select c.customer_num numero_cliente, c.fname + ' ' + c.lname nombre_cliente
from customer c
where (
	select count(*)
	from orders o
	where o.customer_num = c.customer_num
) > 1

-- b)
select c.customer_num numero_cliente, c.fname + ' ' + c.lname nombre_cliente
from customer c
join orders o on c.customer_num = o.customer_num
group by c.customer_num, c.fname, c.lname
having count(o.order_num) > 1;

-- La condición no puede ir en el where porque tenemos una función de agregación
-- Esta también es la causa del uso de group by.

/*
4.
Seleccionar todas las Órdenes de compra cuyo Monto total (Suma de p x q de sus items)
sea menor al precio total promedio (avg p x q) de todas las líneas de las ordenes.
Formato de la salida: 
Nro. de Orden	Total
(order_num)		(suma)
*/

select o.order_num numero_orden, sum(i.quantity * i.unit_price) total 
from orders o
join items i on i.order_num = o.order_num
group by o.order_num
having sum(i.quantity * i.unit_price) < (
	select avg(i2.quantity * i2.unit_price)
	from items i2
)

/*
5.
Obtener por cada fabricante, el listado de todos los productos de stock con precio
unitario (unit_price) mayor que el precio unitario promedio de dicho fabricante.
Los campos de salida serán: manu_code, manu_name, stock_num, description,
unit_price.
*/

select m.manu_code, m.manu_name, pt.stock_num, pt.description, p.unit_price
from products p
join product_types pt on pt.stock_num = p.stock_num
join manufact m on m.manu_code = p.manu_code
where p.unit_price < (
	select avg(p2.unit_price)
	from manufact m2
	join products p2 on p2.manu_code = m2.manu_code
	where m2.manu_code = m.manu_code
);

/*
6.
Usando el operador NOT EXISTS listar la información de órdenes de compra que NO
incluyan ningún producto que contenga en su descripción el string 'baseball gloves'.
Ordenar el resultado por compañía del cliente ascendente y número de orden
descendente.
El formato de salida deberá ser:
Número de Cliente	Compañía	Número de Orden		Fecha de la Orden
(customer_num)		(company)	(order_num)				(order_date)
*/

select c.customer_num numero_cliente, 
c.company compania, 
o.order_num numero_orden, 
o.order_date fecha_origen
from orders o
join customer c on o.customer_num = c.customer_num
where not exists (
	select 1
	from items i
	join product_types pt on i.stock_num = pt.stock_num
	where i.order_num = o.order_num
		and pt.description like '%baseball gloves%' 
		-- acá no va not, la negación es la del not exists
)
order by c.company asc, o.order_num desc;

/*
7.
Obtener el número, nombre y apellido de los clientes que NO hayan comprado productos
del fabricante ‘HSK’.
*/

select c.customer_num numero_cliente, 
c.fname + ' ' + c.lname nombre_cliente
from customer c
where not exists (
	select 1
	from orders o
	join items i on i.order_num = o.order_num
	where o.customer_num = c.customer_num 
		and i.manu_code = 'HSK'
);

/*
8.
Obtener el número, nombre y apellido de los clientes que hayan comprado TODOS los
productos del fabricante ‘HSK’.
*/

-- Haciendolo por cuenta:
-- La cantidad de productos distintos que ha comprado el cliente en el tiempo debe
-- ser igual a la cantidad de productos que ofrece el fabricante.

select c.customer_num, c.fname, c.lname
from customer c
join orders o on o.customer_num = c.customer_num
join items i on i.order_num = o.order_num
join products p on p.manu_code = i.manu_code
where p.manu_code = 'HSK'
group by c.customer_num, c.fname, c.lname, p.manu_code
having count(distinct p.stock_num) = (
	select count(*)
	from products p2
	where p2.manu_code = p.manu_code
)

-- Haciendolo por teoría de conjuntos:
-- Para que el cliente lo cumpla, no debe existir ningún producto del fabricante
-- que no haya sido comprado. Por lo tanto, no puede haber orden de dicho cliente
-- que no contenga a cada producto al menos una vez.

select c.customer_num, c.fname, c.lname
from customer c
where not exists (
		select *
		from products p
		where p.manu_code = 'HSK' 
		and p.stock_num not in (
			select i.stock_num
			from orders o
			join items i on o.order_num = i.order_num
			where o.customer_num = c.customer_num
		)
)

-- UNION
/*
9.
Reescribir la siguiente consulta utilizando el operador UNION:  
SELECT * FROM products 
WHERE manu_code = 'HRO'  OR  stock_num = 1 
*/
select *
from products
where manu_code = 'HRO'
union
select *
from products
where stock_num = 1

/*
10.
Desarrollar una consulta que devuelva las ciudades y compañías de todos los Clientes 
ordenadas alfabéticamente por Ciudad pero en la consulta deberán aparecer primero las 
compañías situadas en Redwood City y luego las demás.  
Formato:  Clave de ordenamiento		Ciudad		Compañía  
				(sortkey)			(city)		(company)  
*/

select 1 sortkey, c.city ciudad, c.company compañia
from customer c
where c.city = 'Redwood City'
union
select 2 sortkey, c.city ciudad, c.company compañia
from customer c
order by 1, 2 asc;

/*
11.
Desarrollar una consulta que devuelva los dos tipos de productos más vendidos y los dos 
menos vendidos en función de las unidades totales vendidas.
*/

select 1 codigo_ordenamiento, pt.stock_num tipo_producto, sum(i.quantity) cantidad_vendida
from product_types pt
join items i on i.stock_num = pt.stock_num
where pt.stock_num in (
    select top 2 pt2.stock_num
    from product_types pt2
    join items i2 on i2.stock_num = pt2.stock_num
    group by pt2.stock_num
    order by sum(i2.quantity) desc
)
group by pt.stock_num
union
select 2 codigo_ordenamiento, pt.stock_num tipo_producto, sum(i.quantity) cantidad_vendida
from product_types pt
join items i on i.stock_num = pt.stock_num
where pt.stock_num in (
    select top 2 pt2.stock_num
    from product_types pt2
    join items i2 on i2.stock_num = pt2.stock_num
    group by pt2.stock_num
    order by sum(i2.quantity) asc
)
group by pt.stock_num;

-- Esta es la primera versión. Es innecesario el in, puedo hacer la sub-query directo en el from
-- y de ahi extraer los campos a listar usando los alias que les dí.

select 1 codigo_ordenamiento, tipo_producto, cantidad_vendida
from (
	select top 2 pt.stock_num tipo_producto, sum(i2.quantity) cantidad_vendida 
	from product_types pt
	join items i2 on i2.stock_num = pt.stock_num
	group by pt.stock_num
	order by sum(i2.quantity) desc
) productos_mas_vendidos
union all
select 2 codigo_ordenamiento, tipo_producto, cantidad_vendida
from (
	select top 2 pt.stock_num tipo_producto, sum(i.quantity) cantidad_vendida 
	from product_types pt
	join items i on i.stock_num = pt.stock_num
	group by pt.stock_num
	order by sum(i.quantity) asc
) productos_menos_vendidos;
go

-- Necesito hacer una sub-query porque no puedo ordenar dentro de cada select por separado 
-- teniendo un union.

-- VIEWS
/*
12.
Crear una Vista llamada ClientesConMultiplesOrdenes basada en la consulta realizada en 
el punto 3.b  con los nombres de atributos solicitados en dicho punto.  
*/

create view ClientesConMultiplesOrdenes as
select c.customer_num numero_cliente, c.fname + ' ' + c.lname nombre_cliente
from customer c
join orders o on c.customer_num = o.customer_num
group by c.customer_num, c.fname, c.lname
having count(o.order_num) > 1;
go 

/*
13.
Crear una Vista llamada Productos_HRO en base a la consulta
SELECT * FROM products
WHERE manu_code = “HRO”

La vista deberá restringir la posibilidad de insertar datos que no cumplan con su criterio de
selección.
a. Realizar un INSERT de un Producto con manu_code=’ANZ’ y stock_num=303. Qué sucede?
b. Realizar un INSERT con manu_code=’HRO’ y stock_num=303. Qué sucede?
c. Validar los datos insertados a través de la vista.
*/

create view Productos_HRO as
select * from products
where manu_code = 'HRO'
with check option