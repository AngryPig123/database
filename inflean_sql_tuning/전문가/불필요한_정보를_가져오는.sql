-- before

-- 1	SIMPLE	emp		ref	PRIMARY,I_GENDER_LAST_NAME	I_GENDER_LAST_NAME	1	const	149711	50.00	Using where; Using index
-- 1	SIMPLE	m		ref	PRIMARY	PRIMARY	4	tuning.emp.EMP_ID	1	100.00	Using index

-- -> Aggregate: count(emp.EMP_ID)  (cost=41712 rows=1) (actual time=140..140 rows=1 loops=1)
--      -> Nested loop left join  (cost=34226 rows=74855) (actual time=0.0501..136 rows=60108 loops=1)
--          -> Filter: (emp.EMP_ID > 300000)  (cost=8027 rows=74855) (actual time=0.0394..54.5 rows=60108 loops=1)
--              -> Covering index lookup on emp using I_GENDER_LAST_NAME (GENDER='M')  (cost=8027 rows=149711) (actual time=0.0273..44.1 rows=179973 loops=1)
--          -> Covering index lookup on m using PRIMARY (EMP_ID=emp.EMP_ID)  (cost=0.25 rows=1) (actual time=0.0012..0.0012 rows=0 loops=60108)
 

EXPLAIN ANALYZE
SELECT
		COUNT(emp_id) AS count
FROM (
	SELECT
			e.emp_id
		,	m.dept_id
	FROM (
		SELECT
			*
		FROM emp
        WHERE gender = 'M'
        AND emp_id > 300000
    ) e
    LEFT OUTER JOIN manager m ON e.emp_id = m.emp_id
) sub;




-- after

-- 1	SIMPLE	emp		range	PRIMARY,I_GENDER_LAST_NAME	I_GENDER_LAST_NAME	55		49898	100.00	Using where; Using index for skip scan

-- -> Aggregate: count(emp.EMP_ID)  (cost=8677..8677 rows=1) (actual time=47.7..47.7 rows=1 loops=1)
--      -> Filter: ((emp.GENDER = 'M') and (emp.EMP_ID > 300000))  (cost=0.0739..3687 rows=49898) (actual time=0.0241..44.5 rows=60108 loops=1)
--          -> Covering index skip scan on emp using I_GENDER_LAST_NAME over GENDER = 'M', 300000 < EMP_ID  (cost=0.0739..3687 rows=49898) (actual time=0.0221..37.8 rows=60108 loops=1)


EXPLAIN ANALYZE
SELECT
	COUNT(emp_id) AS count
FROM emp
WHERE gender = 'M'
AND emp_id > 300000;








