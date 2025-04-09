-- OR 절로 되어있는 경우, 인덱스가 안걸려 있는 컬럼에 INDEX를 생성한다.
-- before

-- 1	SIMPLE	emp		ALL	I_HIRE_DATE				299423	10.02	Using where

-- -> Filter: ((emp.FIRST_NAME = 'Matt') or (emp.HIRE_DATE = DATE'1987-03-31'))  (cost=30175 rows=29999) (actual time=0.0668..141 rows=343 loops=1)
--      -> Table scan on emp  (cost=30175 rows=299423) (actual time=0.0478..113 rows=300024 loops=1)
 
EXPLAIN ANALYZE
SELECT
	*
FROM emp
WHERE first_name = 'Matt'
OR hire_date = '1987-03-31';




-- after
ALTER TABLE emp ADD INDEX idx_first_name(first_name);
SHOW INDEX FROM emp;

SELECT
		(SELECT COUNT(*) FROM emp WHERE first_name = 'Matt') AS first_name
	,	(SELECT COUNT(*) FROM emp WHERE hire_date = '1987-03-31') AS hire_date
    ,	(SELECT COUNT(*) FROM emp ) AS emp;

-- 1	SIMPLE	emp		index_merge	I_HIRE_DATE,idx_first_name	idx_first_name,I_HIRE_DATE	44,3		344	100.00	Using union(idx_first_name,I_HIRE_DATE); Using where

-- -> Filter: ((emp.FIRST_NAME = 'Matt') or (emp.HIRE_DATE = DATE'1987-03-31'))  (cost=172 rows=344) (actual time=0.0532..1.07 rows=343 loops=1)
--      -> Deduplicate rows sorted by row ID  (cost=172 rows=344) (actual time=0.0509..1.03 rows=343 loops=1)
--          -> Index range scan on emp using idx_first_name over (FIRST_NAME = 'Matt')  (cost=25.7 rows=233) (actual time=0.034..0.128 rows=233 loops=1)
--          -> Index range scan on emp using I_HIRE_DATE over (HIRE_DATE = '1987-03-31')  (cost=12.1 rows=111) (actual time=0.0086..0.0801 rows=111 loops=1)
 
EXPLAIN ANALYZE
SELECT
	*
FROM emp
WHERE first_name = 'Matt'
OR hire_date = '1987-03-31';



