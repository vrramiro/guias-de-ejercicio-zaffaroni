use Comercial

/*
1. Crear una tabla temporal #clientes a partir de la siguiente consulta: 
SELECT * FROM customer 
*/

select * 
into #clientes
from customer;

select * from #clientes;

-- podemos crear la tabla temporal con create table tambien

/*
2. Insertar el siguiente cliente en la tabla #clientes 
Customer_num  144 
Fname   Agustín 
Lname   Creevy 
Company  Jaguares SA 
State   CA 
City   Los Angeles 
*/

insert into #clientes (customer_num, fname, lname, company, state, city) values (144, 'Agustín', 'Creevy', 'Jaguares SA', 'CA', 'Los Angeles');

select * from #clientes where customer_num = 144;

/*
3. Crear una tabla temporal #clientesCalifornia con la misma estructura de la tabla customer. 
Realizar un insert masivo en la tabla #clientesCalifornia con todos los clientes de la tabla customer cuyo 
state sea CA. 
*/

select *
into #clientesCalifornia
from customer
where state = 'CA';

select * from #clientesCalifornia;

/*
4. Insertar el siguiente cliente en la tabla #clientes un cliente que tenga los mismos datos del cliente 103, 
pero cambiando en customer_num por 155 
Valide lo insertado.
*/

insert into #clientes (customer_num, fname, lname, company, address1, address2, city, state, zipcode, phone, customer_num_referedBy, status) 
select 155, fname, lname, company, address1, address2, city, state, zipcode, phone, customer_num_referedBy, status
from customer
where customer_num = 103;

select *
from customer
where customer_num = 103

select *
from #clientes
where customer_num = 155

/*
5. Borrar de la tabla #clientes los clientes cuyo campo zipcode esté entre 94000 y 94050 y la ciudad
comience con ‘M’. Validar los registros a borrar antes de ejecutar la acción.
*/

delete from #clientes where zipcode between 94000 and 94050 and city = 'M%';

/*
6.
*/