-- select 절에 하나의 테이블만 사용되면 범위 제한을 하는 인라인뷰 테이블을 고려해봐라

-- before

-- 1	SIMPLE	e		range	PRIMARY,I_HIRE_DATE,I_GENDER_LAST_NAME	PRIMARY	4		79652	100.00	Using where; Using temporary; Using filesort
-- 1	SIMPLE	s		ref	PRIMARY	PRIMARY	4	tuning.e.EMP_ID	9	100.00	

-- -> Limit/Offset: 10/150 row(s)  (actual time=290..290 rows=10 loops=1)
--      -> Sort: sum(s.ANNUAL_SALARY) DESC, limit input to 160 row(s) per chunk  (actual time=290..290 rows=160 loops=1)
--          -> Stream results  (cost=192619 rows=299423) (actual time=0.0444..279 rows=40000 loops=1)
--              -> Group aggregate: sum(s.ANNUAL_SALARY)  (cost=192619 rows=299423) (actual time=0.0392..256 rows=40000 loops=1)
--                  -> Nested loop inner join  (cost=116816 rows=758028) (actual time=0.0242..213 rows=379595 loops=1)
--                      -> Filter: (e.EMP_ID between 10001 and 50000)  (cost=16000 rows=79652) (actual time=0.0152..22.7 rows=40000 loops=1)
--                          -> Index range scan on e using PRIMARY over (10001 <= EMP_ID <= 50000)  (cost=16000 rows=79652) (actual time=0.014..17.7 rows=40000 loops=1)
--                      -> Index lookup on s using PRIMARY (EMP_ID=e.EMP_ID)  (cost=0.314 rows=9.52) (actual time=0.00251..0.00412 rows=9.49 loops=40000)

EXPLAIN ANALYZE
SELECT
		e.emp_id
	,	e.first_name
    ,	e.last_name
    ,	e.hire_date
FROM emp e
INNER JOIN salary s ON s.emp_id = e.emp_id AND e.emp_id BETWEEN 10001 AND 50000
GROUP BY e.emp_id
ORDER BY SUM(s.annual_salary) DESC
LIMIT 150,10;




-- after

-- 1	PRIMARY	<derived2>		ALL					160	100.00	
-- 1	PRIMARY	e		eq_ref	PRIMARY	PRIMARY	4	s.emp_id	1	100.00	
-- 2	DERIVED	salary		range	PRIMARY,I_IS_YN	PRIMARY	4		779148	100.00	Using where; Using temporary; Using filesort

-- -> Nested loop inner join  (cost=145 rows=0) (actual time=186..186 rows=10 loops=1)
--      -> Table scan on s  (cost=2.5..2.5 rows=0) (actual time=186..186 rows=10 loops=1)
--          -> Materialize  (cost=0..0 rows=0) (actual time=186..186 rows=10 loops=1)
--              -> Limit/Offset: 10/150 row(s)  (actual time=186..186 rows=10 loops=1)
--                  -> Sort: sum(salary.ANNUAL_SALARY) DESC, limit input to 160 row(s) per chunk  (actual time=186..186 rows=160 loops=1)
--                      -> Stream results  (cost=233952 rows=273459) (actual time=0.032..179 rows=40000 loops=1)
--                          -> Group aggregate: sum(salary.ANNUAL_SALARY)  (cost=233952 rows=273459) (actual time=0.0293..171 rows=40000 loops=1)
--                              -> Filter: (salary.EMP_ID between 10001 and 50000)  (cost=156037 rows=779148) (actual time=0.0141..134 rows=379595 loops=1)
--                                  -> Index range scan on salary using PRIMARY over (10001 <= EMP_ID <= 50000)  (cost=156037 rows=779148) (actual time=0.013..106 rows=379595 loops=1)
--      -> Single-row index lookup on e using PRIMARY (EMP_ID=s.emp_id)  (cost=0.893 rows=1) (actual time=0.00376..0.0038 rows=1 loops=10)
 
EXPLAIN ANALYZE
SELECT
		e.emp_id
	,	e.first_name
    ,	e.last_name
    ,	e.hire_date
FROM emp e
INNER JOIN (
	SELECT
		emp_id
	FROM salary
    WHERE emp_id BETWEEN 10001 AND 50000
    GROUP BY emp_id
    ORDER BY SUM(annual_salary) DESC
    LIMIT 150,10
) s ON s.emp_id = e.emp_id;













