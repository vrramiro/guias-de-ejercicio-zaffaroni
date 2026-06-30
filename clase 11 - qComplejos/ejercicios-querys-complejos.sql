use Comercial

-- 1
select c.customer_num, c.lname + ' ' + c.fname nombre_completo, 
sum(i.quantity*i.unit_price) total_del_cliente, count(o.order_num) ocs_cliente,
(
    select count(o2.order_num)
    from orders o2
) cant_total_oc
from customer c
join orders o on o.customer_num = c.customer_num
join items i on i.order_num = o.order_num
where c.zipcode like '94%'
group by c.customer_num, c.lname, c.fname
having count(o.order_num) >= 2
and (sum(i.quantity*i.unit_price) / count(o.order_num)) > (select sum(i2.quantity*i2.unit_price)/count(o2.order_num) 
                                                           from orders o2 
                                                           join items i2 on o2.order_num = i2.order_num) 

-- 2
create table #ABC_Productos (
    stock_num smallint, 
    manu_code char(3),
    unit_descr varchar(15),
    manu_name varchar(15),
    monto_total_prod_vendido decimal(8, 2),
    cantidad_prod_pedido int
)

insert into #ABC_Productos
select
p.stock_num,
m.manu_code,
u.unit_descr,
m.manu_name,
coalesce(sum(i.quantity*i.unit_price), 0) monto_total_prod_vendido,
coalesce(count(i.order_num), 0) cantidad_prod_pedido
from products p
join manufact m on m.manu_code = p.manu_code
join units u on u.unit_code = p.unit_code
left join items i on i.stock_num = p.stock_num and i.manu_code = p.manu_code
where m.manu_code in (select manu_code 
                      from products
                      group by manu_code
                      having count(stock_num) > 10
                      )
group by p.stock_num, m.manu_code, u.unit_descr, m.manu_name

select * from #ABC_Productos order by monto_total_prod_vendido desc, stock_num, manu_code asc

-- 3
select
a.unit_descr,
c.fname + ', ' + c.lname cliente,
month(o.order_date) mes,
count(o.order_num) cantidad_oc_mes,
sum(i.quantity * i.unit_price) total_oc_mes,
sum(i.quantity) producto_pedido_mes
from #ABC_Productos a
join items i on i.stock_num = a.stock_num and i.manu_code = a.manu_code
join orders o on i.order_num = o.order_num
join customer c on c.customer_num = o.customer_num
where c.state in (select top 1 s.state
                from state s
                join customer c2 on c2.state = s.state
                group by s.state
                order by count(c2.customer_num) desc)
group by month(o.order_date), a.unit_descr, c.lname, c.fname
order by mes asc, producto_pedido_mes desc
