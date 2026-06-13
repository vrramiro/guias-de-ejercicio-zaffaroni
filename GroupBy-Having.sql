select 
fname,
upper(lname),
customer_num,
zipcode
from dbo.customer
where state = 'CA' and zipcode LIKE '%025';

/*
Listar por cada código de fabricante, cantidad de
ordenes de compra (ante repetidos contar solo una),
Suma de quantity, suma de unit_price, para los
fabricantes que tengan mas de 5 items comprados
(cantidad de filas en table items > 5).
Ordenado por la suma de unit_price*quantity.
*/
use Comercial;

select i.manu_code, count(distinct(i.order_num)), sum(i.quantity), sum(i.unit_price) 
-- el count distinct es necesario porque los items pueden ser muchos para una misma factura
-- por lo tanto estaria contando la misma más de una vez. Estoy contando la cantidad distinta de
-- facturas.
from items i
group by i.manu_code -- como se pide por cada codigo de fab, entonces debo agrupar por el
having count(i.order_num) > 5
-- having count(*) > 5 en realidad miraria en cuantas filas aparece el fabricante 
order by sum(i.unit_price * i.quantity)