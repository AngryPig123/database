-- 비효율적인 선택도를 사용하는 인덱스의 경우 인덱스 설계시 고려하여 설계한다. (카디널리티가 높은 컬럼을 선두 컬럼으로 한다.)

-- before

-- 1	SIMPLE	emp		ref	I_GENDER_LAST_NAME	I_GENDER_LAST_NAME	51	const,const	135	100.00	

-- -> Index lookup on emp using I_GENDER_LAST_NAME (GENDER='M', LAST_NAME='Baba')  (cost=47.2 rows=135) (actual time=0.269..0.385 rows=135 loops=1)

EXPLAIN ANALYZE
SELECT
		emp_id
	,	first_name
    ,	last_name
FROM emp
WHERE gender = 'M'
AND last_name = 'Baba';




-- after
SHOW INDEX FROM emp;

SELECT
		(SELECT COUNT(*) FROM emp WHERE gender = 'M') AS gender
	,	(SELECT COUNT(*) FROM emp WHERE last_name = 'Baba') AS last_name
    ,	(SELECT COUNT(*) FROM emp) AS emp;

DROP INDEX I_GENDER_LAST_NAME ON emp;
ALTER TABLE emp ADD INDEX idx_last_name_gender(last_name, gender);

EXPLAIN ANALYZE
SELECT
		emp_id
	,	first_name
    ,	last_name
FROM emp
WHERE gender = 'M'
AND last_name = 'Baba';
