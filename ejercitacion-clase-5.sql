use Comercial

/*
1.
Obtener el número de cliente, la compañía, y número de orden de todos los clientes que tengan 
órdenes. Ordenar el resultado por número de cliente.
*/

select c.customer_num numero_cliente, c.company compania, o.order_num numero_orden
from customer c join orders o on c.customer_num = o.customer_num
order by c.customer_num;

/*
2.
Listar los ítems de la orden número 1004, incluyendo una descripción de cada uno. El listado debe 
contener: Número de orden (order_num), Número de Item (item_num), Descripción del producto 
(product_types.description), Código del fabricante (manu_code), Cantidad (quantity), Precio total 
(unit_price*quantity).
*/

select o.order_num numero_orden, 
i.item_num numero_item, 
pt.description descripcion, 
i.manu_code codigo_fabricante, 
i.quantity cantidad, 
i.unit_price * i.quantity precio_total
from orders o join items i on o.order_num = i.order_num
join product_types pt on pt.stock_num = i.stock_num
where o.order_num = '1004';

/*
3.
Listar los items de la orden número 1004, incluyendo una descripción de cada uno. El listado debe 
contener: Número de orden (order_num), Número de Item (item_num), Descripción del Producto 
(product_types.description), Código del fabricante (manu_code), Cantidad (quantity), precio total 
(unit_price*quantity) y Nombre del fabricante (manu_name).
*/

select o.order_num numero_orden, i.item_num numero_item, pt.description descripcion, 
i.manu_code codigo_fabricante, i.quantity cantidad, i.unit_price * i.quantity precio_total,
m.manu_name
from orders o join items i on o.order_num = i.order_num
join product_types pt on pt.stock_num = i.stock_num
join manufact m on m.manu_code = i.manu_code
where o.order_num = '1004';

/*
4.
Se desea listar todos los clientes que posean órdenes de compra. Los datos a listar son los 
siguientes: número de orden, número de cliente, nombre, apellido y compañía.
*/

select o.order_num numero_orden, c.customer_num numero_cliente, c.fname + ' ' + c.lname nombre_completo, c.company compania
from customer c join orders o on c.customer_num = o.customer_num;


/*
5.
Se desea listar todos los clientes que posean órdenes de compra. Los datos a listar son los 
siguientes: número de cliente, nombre, apellido y compañía. Se requiere sólo una fila por cliente. 
*/

select distinct c.customer_num numero_cliente, c.fname + ' ' + c.lname nombre_completo, c.company compania
from customer c join orders o on c.customer_num = o.customer_num
order by c.customer_num;

/*
6.
Se requiere listar para armar una nueva lista de precios los siguientes datos: nombre del fabricante 
(manu_name), número de stock (stock_num), descripción  
(product_types.description), unidad (units.unit), precio unitario (unit_price) y Precio Junio (precio 
unitario + 20%). 
*/

select m.manu_name nombre_fabricante, 
	   pt.stock_num numero_stock, 
	   pt.description descripcion, 
	   u.unit unidad, 
	   p.unit_price precio_unitario, 
	   p.unit_price*1.2 precio_junio
from manufact m join products p on m.manu_code = p.manu_code
				join units u on u.unit_code = p.unit_code
				join product_types pt on pt.stock_num = p.stock_num

/*
7.
Se requiere un listado de los items de la orden de pedido Nro. 1004 con los siguientes datos: 
Número de item (item_num), descripción de cada producto  
(product_types.description), cantidad (quantity) y precio total (unit_price*quantity).
*/

select i.item_num numero_item, pt.description descripcion, i.quantity cantidad, i.unit_price * i.quantity
from items i join orders o on i.order_num = o.order_num
			 join product_types pt on pt.stock_num = i.stock_num

/*
8.
Informar el nombre del fabricante (manu_name) y el tiempo de envío (lead_time) de los ítems de 
las Órdenes del cliente 104.  
*/

select m.manu_name
from items i join manufact m on i.manu_code = m.manu_code
join orders o on o.order_num = i.order_num
where o.order_num = '104';

/*
12.
Obtener por cada fabricante (manu_name) y producto (description), la cantidad vendida y el 
Monto Total vendido (unit_price * quantity). Sólo se deberán mostrar los ítems de los fabricantes 
ANZ, HRO, HSK y SMT, para las órdenes correspondientes a los meses de mayo y junio del 2015. 
Ordenar el resultado por el monto total vendido de mayor a menor. 
*/

select m.manu_name, pt.description, sum(i.quantity), sum(i.quantity*i.unit_price) monto_total
from manufact m join items i on i.manu_code = m.manu_code
join product_types pt on pt.stock_num = i.stock_num
join orders o on i.order_num = o.order_num
where m.manu_code in ('ANZ', 'HRO', 'HSK', 'SMT')
and month(o.order_date) in (4, 5) and year(o.order_date) = 2015
group by m.manu_name, pt.description
order by monto_total desc;