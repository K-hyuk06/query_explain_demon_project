CREATE TABLE employee_with_id_key(emp_id smallint PRIMARY KEY, name varchar(50));

CREATE TABLE employee_with_name_key(emp_id smallint , name varchar(50 ) PRIMARY KEY);

CREATE TABLE employee_with_no_key(emp_id smallint, name varchar(50));

COPY employee_with_id_key
FROM '/home/ubuntu/data/employee1.csv'
WITH (FORMAT CSV, HEADER);
\copy employee_with_id_key
FROM '/home/ubuntu/data/employee1.csv'
WITH (FORMAT CSV, HEADER);

COPY employee_with_no_key
FROM '/home/ubuntu/data/employee1.csv'
WITH (FORMAT CSV, HEADER);

\copy employee_with_no_key
FROM '/home/ubuntu/data/employee1.csv'
WITH (FORMAT CSV, HEADER);

COPY employee_with_name_key
FROM '/home/ubuntu/data/employee1.csv'
WITH (FORMAT CSV, HEADER);

\copy employee_with_name_key
FROM '/home/ubuntu/data/employee1.csv'
WITH (FORMAT CSV, HEADER);


EXPLAIN ANALYZE SELECT * FROM employee_with_id_key WHERE name='Dustin';

EXPLAIN ANALYZE SELECT * FROM employee_with_name_key WHERE name='Dustin';

EXPLAIN ANALYZE SELECT * FROM employee_with_no_key WHERE name='Dustin';
