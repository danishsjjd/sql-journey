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