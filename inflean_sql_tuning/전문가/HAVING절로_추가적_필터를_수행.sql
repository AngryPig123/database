-- before

-- 1	SIMPLE	e		range	PRIMARY	PRIMARY	4		104330	100.00	Using where; Using temporary
-- 1	SIMPLE	s		ref	PRIMARY,I_IS_YN	PRIMARY	4	tuning.e.EMP_ID	9	100.00	

-- -> Filter: (max(s.ANNUAL_SALARY) > 100000)  (actual time=471..482 rows=3155 loops=1)
--      -> Table scan on <temporary>  (actual time=471..480 rows=49999 loops=1)
--          -> Aggregate using temporary table  (actual time=471..471 rows=49999 loops=1)
--              -> Nested loop inner join  (cost=211247 rows=992883) (actual time=0.0283..220 rows=472687 loops=1)
--                  -> Filter: (e.EMP_ID > 450000)  (cost=20957 rows=104330) (actual time=0.0191..20.6 rows=49999 loops=1)
--                      -> Index range scan on e using PRIMARY over (450000 < EMP_ID)  (cost=20957 rows=104330) (actual time=0.0178..16.4 rows=49999 loops=1)
--                  -> Index lookup on s using PRIMARY (EMP_ID=e.EMP_ID)  (cost=0.872 rows=9.52) (actual time=0.00214..0.00346 rows=9.45 loops=49999)
 
EXPLAIN
SELECT
		e.emp_id
    ,	e.first_name
	,	e.last_name
FROM emp e
INNER JOIN salary s ON s.emp_id = e.emp_id
WHERE e.emp_id > 450000
GROUP BY s.emp_id
HAVING MAX(s.annual_salary) > 100000;




-- after

-- 1	PRIMARY	e		range	PRIMARY	PRIMARY	4		104330	100.00	Using where
-- 2	DEPENDENT SUBQUERY	salary		ref	PRIMARY	PRIMARY	4	tuning.e.EMP_ID	9	100.00	

-- -> Filter: ((e.EMP_ID > 450000) and ((select #2) > 100000))  (cost=20957 rows=104330) (actual time=0.167..249 rows=3155 loops=1)
--      -> Index range scan on e using PRIMARY over (450000 < EMP_ID)  (cost=20957 rows=104330) (actual time=0.0177..15.5 rows=49999 loops=1)
--      -> Select #2 (subquery in condition; dependent)
--          -> Aggregate: max(salary.ANNUAL_SALARY)  (cost=2.78 rows=1) (actual time=0.00422..0.00424 rows=1 loops=49999)
--              -> Index lookup on salary using PRIMARY (EMP_ID=e.EMP_ID)  (cost=1.82 rows=9.52) (actual time=0.00217..0.00339 rows=9.45 loops=49999)
 
EXPLAIN
SELECT
		e.emp_id
    ,	e.first_name
	,	e.last_name
FROM emp e
WHERE e.emp_id > 450000
AND (
	SELECT
		MAX(annual_salary)
	FROM salary
    WHERE emp_id = e.emp_id
) > 100000;






