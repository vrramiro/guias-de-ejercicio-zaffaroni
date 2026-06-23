use Comercial

/*
1. Listar N�mero de Cliente, apellido y nombre, Total Comprado por el cliente �Total del Cliente�,
Cantidad de �rdenes de Compra del cliente �OCs del Cliente� y la Cantidad de �rdenes de Compra de
todos los clientes �Cant. Total OC�, de todos aquellos clientes cuyo promedio de compra por Orden
supere al promedio de �rdenes de compra general, tenga al menos 2 �rdenes y su zipcode comience
con 94.
*/

select c.customer_num, c.lname + ' ' + c.fname, 
sum(i.quantity*i.unit_price) total_del_cliente, count(o.order_num) ocs_cliente,
(
select 1
from customer c2
)
from customer c
join orders o on o.customer_num = c.customer_num
join items i on i.order_num = o.order_num

