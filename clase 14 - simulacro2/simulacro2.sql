use Comercial;

--1
select
s.[state] estado,
s.sname detalle_estado,
pt.[description] tipo_producto,
sum(i.quantity) cantidad_total_tipo_producto
from [state] s 
join customer c on c.state = s.[state]
join orders o on o.customer_num = c.customer_num
join items i on i.order_num = o.order_num
join product_types pt on pt.stock_num = i.stock_num
where pt.[description] in (select pt.description
                          from items ii

                          )
group by s.[state], s.sname, pt.[description]
order by s.sname;
go

create trigger ordenItemsTr ON ordenItems
instead of INSERT as
--
begin
--
    if (select count(distinct m.state) from inserted i join manufact m 
                                          on i.manu_code = m.manu_code) > 2  
               throw 50001, 'Error, Compras en mas de dos estados.', 1;
    --
    if exists (select 1 from inserted i join customer c
                                             on i.customer_num = c.customer_num 
                                        join manufact m 
                                            on i.manu_code = m.manu_code
                where c.state = 'AK' and m.state != 'AK')
           throw 50002, 'Hay compras desde Alaska afuera de Alaska', 1;
    --
    insert into orders (order_num, order_date, customer_num, paid_date)
            (select top 1 order_num, order_date, customer_num, paid_date
                 from inserted);
     --
     insert into items (order_num, item_num, stock_num, manu_code, 
                                      quantity, unit_price)
            (select order_num, item_num, stock_num, manu_code,
                                      quantity, unit_price 
                from inserted);
     --
end;