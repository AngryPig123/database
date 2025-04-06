-- before

-- 1	PRIMARY	e		range	PRIMARY	PRIMARY	4		100	100.00	Using where; Using index
-- 1	PRIMARY	<derived2>		ref	<auto_key0>	<auto_key0>	4	tuning.e.EMP_ID	10	100.00	
-- 2	DERIVED	salary		index	PRIMARY,I_IS_YN	PRIMARY	7		2602441	100.00	


-- -> Nested loop inner join  (cost=2.73e+6 rows=27.3e+6) (actual time=2752..2752 rows=100 loops=1)
--      -> Filter: (e.EMP_ID between 10001 and 10100)  (cost=21.1 rows=100) (actual time=0.0145..0.055 rows=100 loops=1)
--          -> Covering index range scan on e using PRIMARY over (10001 <= EMP_ID <= 10100)  (cost=21.1 rows=100) (actual time=0.0133..0.0443 rows=100 loops=1)
--      -> Index lookup on s using <auto_key0> (emp_id=e.EMP_ID)  (cost=551180..551182 rows=10) (actual time=27.5..27.5 rows=1 loops=100)
--          -> Materialize  (cost=551180..551180 rows=273459) (actual time=2752..2752 rows=300024 loops=1)
--              -> Group aggregate: min(salary.ANNUAL_SALARY), max(salary.ANNUAL_SALARY), avg(salary.ANNUAL_SALARY)  (cost=523834 rows=273459) (actual time=0.375..2006 rows=300024 loops=1)
--                  -> Index scan on salary using PRIMARY  (cost=263590 rows=2.6e+6) (actual time=0.363..1579 rows=2.84e+6 loops=1)
 
EXPLAIN ANALYZE
SELECT
		e.emp_id
	,	s.avg_salary
    ,	s.max_salary
    ,	s.min_salary
FROM emp e
INNER JOIN (
	SELECT
			emp_id
		,	ROUND(AVG(annual_salary),0) AS avg_salary
        ,	ROUND(MAX(annual_salary),0) AS max_salary
        ,	ROUND(MIN(annual_salary),0) AS min_salary
	FROM salary
    GROUP BY emp_id
) s ON s.emp_id = e.emp_id AND e.emp_id BETWEEN 10001 AND 10100;




-- after

-- 1	PRIMARY	<derived2>		ALL					999	100.00	
-- 1	PRIMARY	e		eq_ref	PRIMARY	PRIMARY	4	s.emp_id	1	100.00	Using index
-- 2	DERIVED	salary		range	PRIMARY,I_IS_YN	PRIMARY	4		999	100.00	Using where

-- -> Nested loop inner join  (cost=1513 rows=999) (actual time=0.609..0.714 rows=100 loops=1)
--      -> Table scan on s  (cost=400..415 rows=999) (actual time=0.598..0.607 rows=100 loops=1)
--          -> Materialize  (cost=400..400 rows=999) (actual time=0.596..0.596 rows=100 loops=1)
--              -> Group aggregate: min(salary.ANNUAL_SALARY), max(salary.ANNUAL_SALARY), avg(salary.ANNUAL_SALARY)  (cost=300 rows=999) (actual time=0.0352..0.541 rows=100 loops=1)
--                  -> Filter: (salary.EMP_ID between 10001 and 10100)  (cost=201 rows=999) (actual time=0.0173..0.343 rows=999 loops=1)
--                      -> Index range scan on salary using PRIMARY over (10001 <= EMP_ID <= 10100)  (cost=201 rows=999) (actual time=0.0159..0.276 rows=999 loops=1)
--      -> Single-row covering index lookup on e using PRIMARY (EMP_ID=s.emp_id)  (cost=0.999 rows=1) (actual time=935e-6..958e-6 rows=1 loops=100)
  
EXPLAIN ANALYZE
SELECT
		e.emp_id
	,	s.avg_salary
    ,	s.max_salary
    ,	s.min_salary
FROM emp e
INNER JOIN (
	SELECT
			emp_id
		,	ROUND(AVG(annual_salary),0) AS avg_salary
        ,	ROUND(MAX(annual_salary),0) AS max_salary
        ,	ROUND(MIN(annual_salary),0) AS min_salary
	FROM salary
    WHERE emp_id BETWEEN 10001 AND 10100
    GROUP BY emp_id
) s ON s.emp_id = e.emp_id;







