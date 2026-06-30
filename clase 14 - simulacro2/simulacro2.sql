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
group by s.[state], s.sname, pt.[description], i.stock_num
having i.stock_num in (
     select top 1 ii.stock_num 
     from customer cc 
     join orders oo on oo.customer_num = cc.customer_num
     join items ii on ii.order_num = oo.order_num
     where cc.state = s.state
     group by ii.stock_num
     order by sum(ii.quantity*ii.unit_price) desc
)
order by s.sname;
go


--2
Create View OrdenItems as  
select 
o.order_num, 
o.order_date, 
o.customer_num, 
o.paid_date,  
i.item_num, 
i.stock_num, 
i.manu_code, 
i.quantity, 
i.unit_price  
from orders o join items i on o.order_num = i.order_num;
go

create trigger vistaOrderItems
on OrdenItems
instead of insert
as
begin
     begin transaction
          if (select count(distinct m.state) 
             from inserted i join manufact m on m.manu_code = i.manu_code) > 2
          rollback transaction;
          throw 50001, 'No se pueden hacer compras en mas de dos estados', 1

          if exists (select 1 from inserted i 
                    join manufact m on i.manu_code = m.manu_code
                    join customer c on c.customer_num = i.customer_num
                    where c.[state] = 'AK' and m.[state] <> c.[state])
          rollback transaction;
          throw 50002, 'No se pueden hacer compras desde Alaska fuera de Alaska', 1

          insert into orders (order_num, order_date, customer_num, paid_date)
          select order_num, order_date, customer_num, paid_date
          from inserted;

          insert into items (order_num, item_num, stock_num, manu_code, quantity, unit_price)
          select order_num, item_num, stock_num, manu_code, quantity, unit_price
          from inserted;

     commit transaction
end

--3
create table clientesAltaOnline (
     customer_num smallint,
     lname varchar(15),
     fname varchar(15),
     company varchar(20),
     address1 varchar(20),
     city varchar(15),
     state char(2),
)

create table Auditoria (
     idAuditoria int identity(1,1) primary key,
     operacion char constraint CHK_operacion check (operacion in ('I', 'M')),
     customer_num smallint,
     lname varchar(15),
     fname varchar(15),
     company varchar(20),
     address1 varchar(20),
     city varchar(15),
     state char(2),
)
go

create procedure actualizaCliente
as 
begin
     declare altaOnlineCursor cursor for
     select customer_num, lname, fname, company, address1, city, state
     from clientesAltaOnline

     declare @customer_num smallint, @lname varchar(15), @fname varchar(15)
     declare @company varchar(20), @address1 varchar(20), @city varchar(15), @state char(2)

     open altaOnlineCursor
     fetch altaOnlineCursor into @customer_num, @lname, @fname, @company, @address1, @city, @state
     while @@FETCH_STATUS = 0
     begin
          begin transaction
               begin try
               if not exists (select 1 from customer where customer_num = @customer_num)
               begin
                    insert into customer (customer_num, lname, fname, company, address1, city, state) values
                    (@customer_num, @lname, @fname, @company, @address1, @city, @state)

                    insert into Auditoria (operacion,customer_num,lname,fname,company,address1,city,state) values 
                    ('I',@customer_num,@lname,@fname,@company,@address1,@city,@state)
               end
               else 
               begin  
                    update customer
                    set lname = @lname, fname = @fname, company = @company, address1 = @address1, city = @city, state = @state
                    where customer_num = @customer_num

                    insert into Auditoria (operacion,customer_num,lname,fname,company,address1,city,state) values 
                    ('M',@customer_num,@lname,@fname,@company,@address1,@city,@state)
               end
               end try
               begin catch
               rollback transaction
               end catch

          commit transaction
          fetch altaOnlineCursor into @customer_num, @lname, @fname, @company, @address1, @city, @state
     end
     close altaOnlineCursor
     deallocate altaOnlineCursor
end









