drop function if exists sql_invoicing.get_clients_by_state;
-- basic example
create or replace function sql_invoicing.get_clients_by_state(state_param char(2) default null) returns table(
        client_id int4,
        name varchar(50),
        address varchar(50)
    ) as $$ begin return query
select c.client_id,
    c.name,
    c.address
from sql_invoicing.clients c
where c.state = coalesce(state_param, c.state);
end $$ language plpgsql;
-- calling the function
select *
from sql_invoicing.get_clients_by_state('CA');
select *
from sql_invoicing.get_clients_by_state(null);
select *
from sql_invoicing.get_clients_by_state();
-- get function overloads:
select pg_get_functiondef(pp.oid)
from pg_proc pp
where proname = 'get_clients_by_state';
-- calling function overloads
select *
from sql_invoicing.get_clients_by_state('CA'::char(2));
select *
from sql_invoicing.get_clients_by_state('CA'::varchar);
-- parameter validations
CREATE OR REPLACE FUNCTION sql_invoicing.update_invoice_payment(
        p_invoice_id INT,
        p_payment_total numeric(9, 2),
        p_payment_date DATE
    ) returns void AS $$ BEGIN IF p_payment_total <= 0 THEN RAISE EXCEPTION 'Payment amount cannot be negative';
END IF;
UPDATE sql_invoicing.invoices i
SET payment_total = p_payment_total,
    payment_date = p_payment_date
WHERE i.invoice_id = p_invoice_id;
end $$ LANGUAGE plpgsql;
select update_invoice_payment(1, -1, '2025-1-1');
select update_invoice_payment(1, 1, '2025-1-1');
select *
from sql_invoicing.invoices i
where i.invoice_id = 1;
-- reset row
update sql_invoicing.invoices i
SET payment_total = 0.00,
    payment_date = null
WHERE i.invoice_id = 1;
-- in, out and inout parameters
-- by default all parameters are in
-- example of out parameters
create or replace function sql_store.get_customer(p_customer_id int4, OUT full_name varchar) as $$ begin
select c.first_name || ' ' || c.last_name into full_name
from sql_store.customers c
where c.customer_id = p_customer_id;
end $$ language plpgsql;
-- Usage:
select *
from sql_store.get_customer(1);
-- or:
DO $$
DECLARE c_full_name VARCHAR;
BEGIN
SELECT *
FROM sql_store.get_customer(1) INTO c_full_name;
RAISE NOTICE 'Employee: %',
c_full_name;
END $$;
-- example of inout parameters
CREATE OR REPLACE FUNCTION double_value(INOUT x INT) AS $$ BEGIN x := x * 2;
END;
$$ LANGUAGE plpgsql;
-- Usage:
SELECT double_value(10);
-- variable assignment
create or replace function sql_invoicing.get_risk_factor_for_client(p_client_id int4) returns int as $$
declare risk_factor int := 0;
invoices_total int := 0;
invoices_count int := 0;
begin
select count(*),
    sum(i.invoice_total) into invoices_count,
    invoices_total
from sql_invoicing.invoices i
where i.client_id = p_client_id;
risk_factor = invoices_total / invoices_count * 5;
return coalesce(risk_factor, 0);
end $$ language plpgsql;
-- I was just flexing with variable although you can achieve the same behavior with few code:
create or replace function sql_invoicing.get_risk_factor_for_client(p_client_id int4) returns int as $$ begin return coalesce(
        (
            select sum(invoice_total) / count(*) * 5
            from sql_invoicing.invoices
            where client_id = p_client_id
        ),
        0
    );
end $$ language plpgsql;