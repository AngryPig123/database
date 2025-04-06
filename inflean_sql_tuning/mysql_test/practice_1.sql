-- 최근 입사한 사원 10명의 이름과 입사일을 출력하라.

SHOW INDEX FROM employees;
-- PRIMARY	1	emp_no

-- before hire_date index 추가 전
-- 1	SIMPLE	employees		ALL					299117	100.00	Using filesort
-- -> Sort: employees.hire_date  (cost=30128 rows=299117) (actual time=332..373 rows=300024 loops=1)
--      -> Table scan on employees  (cost=30128 rows=299117) (actual time=0.0521..147 rows=300024 loops=1) 
EXPLAIN
SELECT
		first_name
	,	last_name
    ,	hire_date
FROM employees
ORDER BY hire_date DESC;

-- after hire_date index 추가 후
CREATE INDEX idx_employees_hire_date ON employees(hire_date);

-- -> Sort: employees.hire_date DESC  (cost=30128 rows=299117) (actual time=255..284 rows=300024 loops=1)
--      -> Table scan on employees  (cost=30128 rows=299117) (actual time=0.042..110 rows=300024 loops=1)
EXPLAIN ANALYZE
SELECT
		first_name
	,	last_name
    ,	hire_date
FROM employees
ORDER BY hire_date DESC;

-- -> Nested loop inner join  (cost=7.13 rows=10) (actual time=0.0435..0.0635 rows=10 loops=1)
--      -> Table scan on e2  (cost=1.27..3.63 rows=10) (actual time=0.034..0.0348 rows=10 loops=1)
--          -> Materialize  (cost=1.01..1.01 rows=10) (actual time=0.0331..0.0331 rows=10 loops=1)
--              -> Limit: 10 row(s)  (cost=0.00726 rows=10) (actual time=0.0227..0.0249 rows=10 loops=1)
--                  -> Covering index scan on employees using idx_employees_hire_date (reverse)  (cost=0.00726 rows=10) (actual time=0.0223..0.0238 rows=10 loops=1)
--      -> Single-row index lookup on e1 using PRIMARY (emp_no=e2.emp_no)  (cost=0.26 rows=1) (actual time=0.00257..0.00258 rows=1 loops=10)
  
EXPLAIN ANALYZE
SELECT
		e1.first_name
	,	e1.last_name
    ,	e1.hire_date
FROM employees e1
INNER JOIN (
	SELECT
			emp_no
	FROM employees
	ORDER BY hire_date DESC
	LIMIT 10
) e2 ON e2.emp_no = e1.emp_no;
