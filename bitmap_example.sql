CREATE TABLE employee_with_two_emp_name_id(id SERIAL PRIMARY KEY,emp_id smallint , name varchar(50),work_date DATE);

CREATE TABLE employee_with_two_emp_date_id(id SERIAL PRIMARY KEY,emp_id smallint , name varchar(50),work_date DATE);


CREATE TABLE employee_with_name_idx(id SERIAL PRIMARY KEY,emp_id smallint , name varchar(50),work_date DATE);

CREATE TABLE employee_with_idx_each(id SERIAL PRIMARY KEY,emp_id smallint , name varchar(50),work_date DATE);

CREATE TABLE employee_with_no_idx(id SERIAL,emp_id smallint, name varchar(50),work_date DATE);


-- 인덱스 만들기

CREATE INDEX two_emp_name_id ON employee_with_two_emp_name_id (emp_id, name);
CREATE INDEX two_emp_date_id ON employee_with_two_emp_date_id (emp_id, work_date);

CREATE INDEX name_idx ON employee_with_name_idx (emp_id);

CREATE INDEX name_idx1 ON employee_with_idx_each(name);
CREATE INDEX emp_idx ON employee_with_idx_each(emp_id);
CREATE INDEX date_idx ON employee_with_idx_each(work_date);

-- 데이터 로드

\copy employee_with_two_emp_name_id (emp_id, name, work_date)
FROM '/home/ubuntu/data/employee2.csv'
WITH (FORMAT CSV, HEADER);

\copy employee_with_two_emp_date_id (emp_id, name, work_date)
FROM '/home/ubuntu/data/employee2.csv'
WITH (FORMAT CSV, HEADER);

\copy employee_with_name_idx (emp_id, name, work_date)
FROM '/home/ubuntu/data/employee2.csv'
WITH (FORMAT CSV, HEADER);


\copy employee_with_idx_each (emp_id, name, work_date)
FROM '/home/ubuntu/data/employee2.csv'
WITH (FORMAT CSV, HEADER);

\copy employee_with_no_idx (emp_id, name, work_date)
FROM '/home/ubuntu/data/employee2.csv'
WITH (FORMAT CSV, HEADER);

EXPLAIN ANALYZE SELECT emp_id,name FROM employee_with_two_emp_name_id  WHERE name='Dustin' and emp_id = 1;

EXPLAIN ANALYZE SELECT emp_id,name FROM employee_with_two_emp_date_id WHERE name='Dustin' and emp_id = 1;

EXPLAIN ANALYZE SELECT emp_id,name FROM employee_with_name_idx WHERE name='Dustin' and emp_id = 1;

EXPLAIN ANALYZE SELECT emp_id,name FROM employee_with_idx_each WHERE name='Dustin' and emp_id = 1;

EXPLAIN ANALYZE SELECT emp_id,name FROM employee_with_no_idx WHERE name='Dustin' and emp_id = 1;
