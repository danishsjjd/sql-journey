CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
--
CREATE INDEX idx_users_username ON users(username);
--

-- 
CREATE TABLE todos (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    description TEXT NOT NULL,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);
--
CREATE INDEX idx_todos_user_id ON todos(user_id);
CREATE INDEX idx_todos_completed ON todos(completed);
--

--
CREATE TYPE audit_type AS ENUM ('INSERT', 'UPDATE', 'DELETE');
--
CREATE TABLE audits (
id SERIAL PRIMARY KEY,
table_name VARCHAR(50) NOT NULL,
operation audit_type NOT NULL,
old_data JSONB,
new_data JSONB,
changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
--
CREATE INDEX idx_audits_table_name ON audits(table_name);
CREATE INDEX idx_audits_changed_at ON audits(changed_at);
--
CREATE OR REPLACE FUNCTION audit_trigger_function() RETURNS TRIGGER AS $$
BEGIN
INSERT INTO audits (table_name, operation, old_data, new_data)
VALUES (
        TG_TABLE_NAME,
        TG_OP::audit_type,
        CASE
            WHEN TG_OP IN ('UPDATE', 'DELETE') THEN row_to_json(OLD)
            ELSE NULL
        END,
        CASE
            WHEN TG_OP IN ('UPDATE', 'INSERT') THEN row_to_json(NEW)
            ELSE NULL
        END
    );
RETURN NULL;
END;
$$ LANGUAGE plpgsql;
-- Create triggers for auditing
CREATE TRIGGER users_audit_trigger
AFTER
INSERT
    OR
UPDATE
    OR DELETE ON users FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
CREATE TRIGGER todos_audit_trigger
AFTER
INSERT
    OR
UPDATE
    OR DELETE ON todos FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
--

-- Testing the auditing
INSERT INTO users (username)
VALUES ('Danish');
INSERT INTO todos (user_id, description)
VALUES (1, 'Buy groceries');
UPDATE users
SET username = 'Dan'
WHERE id = 1;
DELETE FROM users
WHERE id = 1;
SELECT *
FROM audits;
----------------
----------------
----------------
----------------
create or replace function sql_invoicing.payments_after_insert() returns trigger as $$ begin
update sql_invoicing.invoices
set payment_total = payment_total + new.amount
where invoice_id = new.invoice_id;
return new;
end;
$$ language plpgsql;
create or replace trigger payments_after_insert
after
insert on sql_invoicing.payments for each row execute procedure sql_invoicing.payments_after_insert();
insert into sql_invoicing.payments
values (9, 3, 3, '2025-01-01', 10, 1);
---
create or replace function payments_after_delete() returns trigger as $$
declare invoice_payment_total int := 0;
begin
select payment_total into invoice_payment_total
from sql_invoicing.invoices i
where i.invoice_id = old.invoice_id;
update sql_invoicing.invoices i
set payment_total = payment_total - old.amount
where invoice_id = old.invoice_id;
-- for debugging
raise notice 'new=%, old=%, invoice_payment_total=%',
new,
old,
invoice_payment_total - old.amount;
return new;
end $$ language plpgsql;
create or replace trigger payments_after_delete
after delete on sql_invoicing.payments for each row execute procedure payments_after_delete();
delete from sql_invoicing.payments p
where p.payment_id = 9;
-- returning null from before delete trigger cause it to stop deleting the row so please don't return new from it