-- make sure hstore extension is installed
create extension if not exists "hstore";
-- List all installed extensions
SELECT *
FROM pg_extension;
-- create a type for a human
create type Human as (
    name text,
    birth_date date,
    dna char [4] [4],
    bio jsonb,
    skills hstore
);
-- tables
create table programmers (id serial primary key, details Human);
create table designers (id serial primary key, details Human);
-- insert a human into the programmers table
insert into programmers (details)
values (
        (
            'Danish',
            '1969-01-01',
            array ['A', 'T', 'G', 'C'],
            -- What? even though it's a 2d array, it's still a 1d array
            --     array['A', 'T', 'G', 'C'],
            -- array ['A', 'T', 'G', 'C'],
            -- array ['A', 'T', 'G', 'C'],
            -- array ['A', 'T', 'G', 'C'],
            -- ],
            '{"email": "example@example.com", "phone": "+1234567890"}'::jsonb,
            'js=>expert'::hstore
        )
    );
-- 
select (details).name, (details).bio, (details).skills -> 'js' as js_skill
from programmers
where (details).name = 'Danish' and (details).skills -> 'js' = 'expert' and (details).bio->>'email' = 'example@example.com';