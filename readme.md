# 쿼리 분석 프로젝트
## 1. 앞서서
- 해당 프로젝트는 sql query가 어떤 식으로 동작하는 지 파악하여, 효율적으로 데이터를 질의하는 방법을 찾는 것이 목적입니다. 

## 2. 환경 설정 

- 해당 환경은 aws ec2 우분투 24.04 환경에서 작업했습니다. 

- postgres 설치 
```
sudo apt update -y
sudo apt-get -y install postgresql
sudo -i -u postgres
psql
```

- 사용자 추가 및 데이터베이스 추가
``` 
create user kim password '1234' superuser;
create database kimdb owner kim;
\q # 셸 나가기
```

- 새로 생성된 사용자의 접속을 위해, postgres 설정 파일 수정
```
sudo vim /etc/postgresql/16/main/pg_hba.conf
#아래의 부분으로 수정
local   all      all     md5
```

- 바뀐 설정 적용
```
sudo systemctl restart postgresql
```


## 3. 단순 데이터로 쿼리 속도 측정하기

### 1) python으로 예제 데이터 만들기


```
from faker import Faker
import csv

fake = Faker()
fake.seed_instance(100)
names = [fake.unique.first_name() for i in range(500)]

with open("./employee1.csv", "w", newline="") as csvfile:
    writer = csv.writer(csvfile, delimiter=",")
    writer.writerow(["emp_id", "name"])
    for i in range(len(names)):
        writer.writerow([i + 1, names[i]])
```

- faker 라이브러리를 이용해서, 직원 id와 이름이 저장된 employee1.csv 파일을 생성 

### 2) postgres에 테이블 만들기

```
-- id가 기본 키인 테이블 
CREATE TABLE employee_with_id_key(emp_id smallint PRIMARY KEY, name varchar(50)); 

-- name이 기본 키인 테이블
CREATE TABLE employee_with_name_key(emp_id smallint , name varchar(50) PRIMARY KEY);

-- 기본 키가 없는 테이블
CREATE TABLE employee_with_no_key(emp_id smallint, name varchar(50));
```
- 키의 유무와 어떤 열이 키인 가에 따른 쿼리 계획 변화를 확인하기 위해 테이블 생성

### 3) postgres에 파일 적재하기

```
COPY employee_with_id_key
FROM '/home/ubuntu/data/employee1.csv'
WITH (FORMAT CSV, HEADER);


COPY employee_with_no_key
FROM '/home/ubuntu/data/employee1.csv'
WITH (FORMAT CSV, HEADER);


COPY employee_with_name_key
FROM '/home/ubuntu/data/employee1.csv'
WITH (FORMAT CSV, HEADER);
```

- postgres 셸에서 작업을 하는 경우에는 COPY를 \copy로 바꾸세요.
- 해당 작업이 안 되는 경우, 파일의 권한을 확인해보세요.

### 4) 쿼리 성능 체크하기

```
EXPLAIN ANALYZE SELECT * FROM employee_with_id_key WHERE name='Dustin';

EXPLAIN ANALYZE SELECT * FROM employee_with_name_key WHERE name='Dustin';

EXPLAIN ANALYZE SELECT * FROM employee_with_no_key WHERE name='Dustin';
```
- 각각의 명령을 실행하면, 이하의 결과가 나옵니다
```
                                                  QUERY PLAN                                                  
--------------------------------------------------------------------------------------------------------------
 Seq Scan on employee_with_id_key  (cost=0.00..9.25 rows=1 width=8) (actual time=0.016..0.063 rows=1 loops=1)
   Filter: ((name)::text = 'Dustin'::text)
   Rows Removed by Filter: 499
 Planning Time: 0.136 ms
 Execution Time: 0.078 ms
(5 rows)


                                                                     QUERY PLAN                                                                     
----------------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using employee_with_name_key_pkey on employee_with_name_key  (cost=0.27..8.29 rows=1 width=8) (actual time=0.011..0.013 rows=1 loops=1)
   Index Cond: ((name)::text = 'Dustin'::text)
 Planning Time: 0.197 ms
 Execution Time: 0.030 ms
(4 rows)




                                                  QUERY PLAN                                                  
--------------------------------------------------------------------------------------------------------------
 Seq Scan on employee_with_no_key  (cost=0.00..9.25 rows=1 width=8) (actual time=0.013..0.063 rows=1 loops=1)
   Filter: ((name)::text = 'Dustin'::text)
   Rows Removed by Filter: 499
 Planning Time: 0.153 ms
 Execution Time: 0.079 ms
(5 rows)
```


- 테이블 employee_with_name_key의 경우에만 Index Scan이 발생하고, 나머지에서는 Seq Scan이 발생합니다.
- Index Scan이라고 해서, query 시간이 그리 차이가 나지 않는 데, 그 이유는 데이터 자체가 너무 적기 때문이라고 생각합니다. 


## 4. 더 많은 데이터로 쿼리 속도 측정하기


### 1) python으로 예제 데이터 만들기
```
from faker import Faker
import csv
import datetime

fake = Faker()
fake.seed_instance(100)
names = [fake.unique.first_name() for i in range(500)]
dates = [
    datetime.date(2024, 5, 5).strftime("%Y-%m-%d"),
    datetime.date(2024, 5, 6).strftime("%Y-%m-%d"),
    datetime.date(2024, 5, 7).strftime("%Y-%m-%d"),
]

with open("./employee2.csv", "w", newline="") as csvfile:
    writer = csv.writer(csvfile, delimiter=",")
    writer.writerow(["emp_id", "name", "work_date"])

    for i in range(len(names)):
        writer.writerow([i + 1, names[i], dates[0]])
        writer.writerow([i + 1, names[i], dates[1]])
        writer.writerow([i + 1, names[i], dates[2]])

```
- 위의 데이터와는 다르게, 날짜 칼럼이 추가 되었습니다. 

### 2) postgres에 테이블 만들기

```
CREATE TABLE employee_with_two_emp_name_id(id SERIAL PRIMARY KEY,emp_id smallint , name varchar(50),work_date DATE);

CREATE TABLE employee_with_two_emp_date_id(id SERIAL PRIMARY KEY,emp_id smallint , name varchar(50),work_date DATE);


CREATE TABLE employee_with_name_idx(id SERIAL PRIMARY KEY,emp_id smallint , name varchar(50),work_date DATE);

CREATE TABLE employee_with_idx_each(id SERIAL PRIMARY KEY,emp_id smallint , name varchar(50),work_date DATE);

CREATE TABLE employee_with_no_idx(id SERIAL,emp_id smallint, name varchar(50),work_date DATE);
```

- id라는 insert 시에 자동으로 증가하는 값을 추가해줍니다. 
- 이때 employee_with_no_idx를 제외하면, id를 기본키로 설정해 줍니다. 

### 3) 데이터 적재하기

```
COPY employee_with_two_emp_name_id (emp_id, name, work_date)
FROM '/home/ubuntu/data/employee2.csv'
WITH (FORMAT CSV, HEADER);

COPY employee_with_two_emp_date_id (emp_id, name, work_date)
FROM '/home/ubuntu/data/employee2.csv'
WITH (FORMAT CSV, HEADER);

COPY employee_with_name_idx (emp_id, name, work_date)
FROM '/home/ubuntu/data/employee2.csv'
WITH (FORMAT CSV, HEADER);

COPY employee_with_idx_each (emp_id, name, work_date)
FROM '/home/ubuntu/data/employee2.csv'
WITH (FORMAT CSV, HEADER);

COPY employee_with_no_idx (emp_id, name, work_date)
FROM '/home/ubuntu/data/employee2.csv'
WITH (FORMAT CSV, HEADER);
```


### 4) 인덱스 만들기

```
CREATE INDEX two_emp_name_id ON employee_with_two_emp_name_id (emp_id, name);

CREATE INDEX two_emp_date_id ON employee_with_two_emp_date_id (emp_id, work_date);

CREATE INDEX name_idx ON employee_with_name_idx (emp_id);

CREATE INDEX name_idx1 ON employee_with_idx_each(name);

CREATE INDEX emp_idx ON employee_with_idx_each(emp_id);

CREATE INDEX date_idx ON employee_with_idx_each(work_date);
```







### 5) postgres에서 쿼리 처리 및 속도 확인하기
```
EXPLAIN ANALYZE SELECT emp_id, name FROM [테이블명] WHERE emp_id =1 AND name = 'Dustin';
```

- 아래는 각 테이블로 위의 쿼리를 실행했을 때 결과


```
                                                                     QUERY PLAN                                                                     
----------------------------------------------------------------------------------------------------------------------------------------------------
 Index Only Scan using two_emp_name_id on employee_with_two_emp_name_id  (cost=0.28..4.30 rows=1 width=8) (actual time=0.065..0.069 rows=3 loops=1)
   Index Cond: ((emp_id = 1) AND (name = 'Dustin'::text))
   Heap Fetches: 0
 Planning Time: 0.096 ms
 Execution Time: 0.089 ms
(5 rows)


                                                           QUERY PLAN                                                           
--------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on employee_with_two_emp_date_id  (cost=4.30..11.15 rows=1 width=8) (actual time=0.016..0.020 rows=3 loops=1)
   Recheck Cond: (emp_id = 1)
   Filter: ((name)::text = 'Dustin'::text)
   Heap Blocks: exact=1
   ->  Bitmap Index Scan on two_emp_date_id  (cost=0.00..4.30 rows=3 width=0) (actual time=0.007..0.007 rows=3 loops=1)
         Index Cond: (emp_id = 1)
 Planning Time: 0.197 ms
 Execution Time: 0.055 ms
(8 rows)



                                                           QUERY PLAN                                                            
---------------------------------------------------------------------------------------------------------------------------------
 Index Scan using name_idx on employee_with_name_idx  (cost=0.28..8.34 rows=1 width=8) (actual time=0.011..0.015 rows=3 loops=1)
   Index Cond: (emp_id = 1)
   Filter: ((name)::text = 'Dustin'::text)
 Planning Time: 0.208 ms
 Execution Time: 0.034 ms
(5 rows)


                                                           QUERY PLAN                                                           
--------------------------------------------------------------------------------------------------------------------------------
 Index Scan using emp_idx on employee_with_idx_each  (cost=0.28..8.34 rows=1 width=8) (actual time=0.011..0.015 rows=3 loops=1)
   Index Cond: (emp_id = 1)
   Filter: ((name)::text = 'Dustin'::text)
 Planning Time: 0.310 ms
 Execution Time: 0.035 ms
(5 rows)


                                                  QUERY PLAN                                                   
---------------------------------------------------------------------------------------------------------------
 Seq Scan on employee_with_no_idx  (cost=0.00..31.50 rows=1 width=8) (actual time=0.010..0.148 rows=3 loops=1)
   Filter: (((name)::text = 'Dustin'::text) AND (emp_id = 1))
   Rows Removed by Filter: 1497
 Planning Time: 0.123 ms
 Execution Time: 0.164 ms
(5 rows)
```

- 인덱스 설정에 따라 Index Scan, Index Only Scan, Seq Scan 등이 나오는 것을 확인 가능


## 3. kaggle 데이터로 쿼리 속도 측정하기 1

### 1) 데이터 설명

#### 1. 파일 구하기
https://www.kaggle.com/datasets/thedevastator/unlock-profits-with-e-commerce-sales-data?select=Amazon+Sale+Report.csv 

#### 2. 칼럼 정보 찾기

- 칼럼
  - OrderID: 주문 id
  - Category: 제품의 타입
  - Size: 제품의 크기
  - Date: 판매 일자
  - Status: 판매 상태
  - Fulfilment: 주문 처리방법
  - Style: 제품의 스타일
  - SKU: 재고 보유 단위
  - ASIN: 아마존 확인 번호
  - Courier Status: 택배 상태
  - Qty: 제품 수량
  - Amount: 매매 금액
  - B2B:B2B 거래 여부
  - Currency: 판매에 사용된 통화





#### 3. 필요 없는 칼럼 제거하기

```
import pandas as pd

df = pd.read_csv("./AmazonSaleReport.csv")

df.drop(
    columns=[
        "index",
        "ship-city",
        "ship-state",
        "ship-postal-code",
        "ship-country",
        "promotion-ids",
        "ship-service-level",
        "Sales Channel ",
        "fulfilled-by",
        "Unnamed: 22",
    ],
    axis=1,
    inplace=True,
)

df.head()
df.to_csv("./AmazonSaleReport2.csv", index=False)
```


### 2) 데이터 적재하기




```
CREATE TABLE amazon_sale_report 
( 
	OrderID text,
	Date DATE,
	Status varchar(30),
	Fulfilment varchar(30),
	Style varchar(30),
	SKU varchar(30),
  Category text,
	Size text,
	ASIN text,
	CourierStatus text,
  Qty Integer,
	Currency text,
  Amount real,
  B2B boolean
);

COPY amazon_sale_report(OrderId,Date,Status,Fulfilment,Style,SKU,Category,Size,ASIN,CourierStatus,Qty,Currency,Amount,B2B)
FROM '/postgre_output/AmazonSaleReport2.csv'
WITH (FORMAT CSV, HEADER);
```

- 해당 데이터를 아직 잘 살펴보지 않았기 때문에 varchar을 어림잡아서 사용
- 모르는 부분은 text로 사용


### 2) 테이터 탐색하기

```
SELECT * FROM amazon_sale_report LIMIT 5;
```

```
SELECT COUNT(*), COUNT(DISTINCT OrderId) FROM amazon_sale_report;
#128975	120378

SELECT COUNT(*), COUNT(DISTINCT ASIN) FROM amazon_sale_report;
#128975	7190
```





### 2) 쿼리 검색 확인

* 참조: 고객의 입장에서 주로 할 것 같은 검색은 배송 상태로, 주문, 일자 ,상태, 배송 상태를 추출하는 쿼리로 테스트 


#### 비교 사항 1: 데이터 타입(char,text)이 쿼리에 미치는 영향 확인
```
SELECT min(length(OrderID)),max((length(OrderId))) FROM amazon_sale_report ;
```
  - 위와 같은 방식으로 확인하여 데이터 타입이 TEXT인 칼럼들을 char 또는 varchar로 변경한 테이블 작성 

```
CREATE TABLE amazon_sale_report2 
( 
	OrderID char(19),
	Date DATE,
	Status varchar(30),
	Fulfilment varchar(8),
	Style varchar(8),
	SKU varchar(30),
  Category varchar(13),
	Size varchar(4),
	ASIN char(10),
	CourierStatus varchar(9),
  Qty Integer,
	Currency char(3),
  Amount real,
  B2B boolean
);

INSERT INTO amazon_sale_report2 SELECT * FROM amazon_sale_report ;

```

 - 쿼리 확인해보기 
```
EXPLAIN ANALYZE SELECT OrderId, date,Status, CourierStatus FROM amazon_sale_report2 WHERE orderID='408-7955685-3083534' ;
EXPLAIN ANALYZE SELECT OrderId, date,Status, CourierStatus FROM amazon_sale_report WHERE orderID='408-7955685-3083534';
```

 - 출력값
```
# amazon_sale_report2의 경우
"Seq Scan on amazon_sale_report2  (cost=0.00..3871.19 rows=1 width=45) (actual time=0.099..34.556 rows=1 loops=1)"
"  Filter: (orderid = '408-7955685-3083534'::bpchar)"
"  Rows Removed by Filter: 128974"
"Planning Time: 0.517 ms"
"Execution Time: 34.590 ms"

# amazon_sale_report의 경우
"Seq Scan on amazon_sale_report  (cost=0.00..3871.19 rows=1 width=45) (actual time=0.031..41.954 rows=1 loops=1)"
"  Filter: (orderid = '408-7955685-3083534'::text)"
"  Rows Removed by Filter: 128974"
"Planning Time: 0.245 ms"
"Execution Time: 41.976 ms"
```




#### 비교 사항 2: 모든 데이터를 출력하는 것과 필요 데이터만 출력하는 것에 대한 비교
 - 쿼리 확인해보기

```
EXPLAIN ANALYZE SELECT OrderId, date,Status, CourierStatus FROM amazon_sale_report2;

EXPLAIN ANALYZE SELECT * FROM amazon_sale_report2;
```

  - 출력값
```
# 일부 데이터
"Seq Scan on amazon_sale_report2  (cost=0.00..3548.75 rows=128975 width=45) (actual time=0.015..27.415 rows=128975 loops=1)"
"Planning Time: 0.048 ms"
"Execution Time: 38.064 ms"

# 전체 데이터
"Seq Scan on amazon_sale_report2  (cost=0.00..3548.75 rows=128975 width=105) (actual time=0.012..16.226 rows=128975 loops=1)"
"Planning Time: 0.434 ms"
"Execution Time: 21.044 ms"
```
  - 해당 출력값은 방금 사용한 테이블을 다시 사용해서 속도가 더 빠른 것으로 보인다 




#### 비교 사항 3: 인덱스와 인덱스 없음의 비교
 - 테이블을 새로 만들고, 인덱스 생성
  
```
CREATE TABLE amazon_sale_report3 AS SELECT * FROM amazon_sale_report2;

CREATE INDEX ex_idx ON amazon_sale_report3(OrderId,Status);
```
 - 인덱스가 있는 테이블과 없는 테이블 사이에서 속도 비교

```
EXPLAIN ANALYZE SELECT OrderId, date,Status, CourierStatus FROM amazon_sale_report3 WHERE orderID='408-7955685-3083534';

EXPLAIN ANALYZE SELECT OrderId, date,Status, CourierStatus FROM amazon_sale_report2 WHERE orderID='408-7955685-3083534' ;
```

 - 출력값

```
# amazon_sale_report3의 경우
"Index Scan using ex_idx on amazon_sale_report3  (cost=0.42..8.44 rows=1 width=45) (actual time=0.989..0.991 rows=1 loops=1)"
"  Index Cond: (orderid = '408-7955685-3083534'::bpchar)"
"Planning Time: 0.689 ms"
"Execution Time: 1.055 ms"

# amazon_sale_report2의 경우
"Seq Scan on amazon_sale_report2  (cost=0.00..3871.19 rows=1 width=45) (actual time=0.033..35.460 rows=1 loops=1)"
"  Filter: (orderid = '408-7955685-3083534'::bpchar)"
"  Rows Removed by Filter: 128974"
"Planning Time: 0.356 ms"
"Execution Time: 35.506 ms"
```

 - 인덱스가 있는 테이블의 스캔이 더 빠른 것을 확인 가능하다.
 


## 4. 더 해보고 싶은 것들

### 1) 여러 테이블에 조인이 있을 때의 성능 개선

### 2) vaccum을 통한 성능 개선




