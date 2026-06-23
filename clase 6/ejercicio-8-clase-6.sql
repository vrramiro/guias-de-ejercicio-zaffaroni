use Comercial;

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
