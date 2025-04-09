-- 불필요한 추가 조건을 붙여서 인덱스를 타게하는 방법은 효과가 미미함. 새로운 인덱스를 추가해서 인덱스를 타게 만드는게 좋음. 카디널리티가 높은 순서로 복합 인덱스를 구성하는게 좋음.

-- before

-- 1	SIMPLE	emp		ALL					299468	1.00	Using where

-- - > Filter: ((emp.FIRST_NAME = 'Georgi') and (emp.LAST_NAME = 'Wielonsky'))  (cost=30179 rows=2995) (actual time=88.2..88.2 rows=1 loops=1)
--      -> Table scan on emp  (cost=30179 rows=299468) (actual time=0.0666..74.4 rows=300024 loops=1)

EXPLAIN ANALYZE
SELECT
	*
FROM emp
WHERE first_name = 'Georgi'
AND last_name = 'Wielonsky';


-- after

-- 1	SIMPLE	emp		range	I_GENDER_LAST_NAME	I_GENDER_LAST_NAME	51		160	10.00	Using index condition; Using where

-- -> Filter: (emp.FIRST_NAME = 'Georgi')  (cost=72.5 rows=16) (actual time=0.585..0.867 rows=1 loops=1)
--      -> Index range scan on emp using I_GENDER_LAST_NAME over (GENDER = 'M' AND LAST_NAME = 'Wielonsky') OR (GENDER = 'F' AND LAST_NAME = 'Wielonsky'), with index condition: ((emp.LAST_NAME = 'Wielonsky') and (emp.GENDER in ('M','F')))  (cost=72.5 rows=160) (actual time=0.0989..0.853 rows=160 loops=1)
 
SHOW INDEX FROM emp; 
-- EMP	0	PRIMARY	1	EMP_ID	A	299468				BTREE			YES	
-- EMP	1	I_HIRE_DATE	1	HIRE_DATE	A	5071				BTREE			YES	
-- EMP	1	I_GENDER_LAST_NAME	1	GENDER	A	1				BTREE			YES	
-- EMP	1	I_GENDER_LAST_NAME	2	LAST_NAME	A	3206				BTREE			YES	

-- 시도한 방법

EXPLAIN ANALYZE
SELECT
	*
FROM emp
WHERE first_name = 'Georgi'
AND last_name = 'Wielonsky'
AND gender IN ('M','F');



-- [1] first_name, last_name 인덱스 생성

SELECT 
		COUNT(DISTINCT first_name) AS first_name
	,	COUNT(DISTINCT last_name) AS last_name
FROM emp;

CREATE INDEX idx_last_first ON emp(last_name, first_name);

-- 1	SIMPLE	emp		ref	idx_last_first	idx_last_first	94	const,const	1	100.00	
-- -> Index lookup on emp using idx_last_first (LAST_NAME='Wielonsky', FIRST_NAME='Georgi')  (cost=0.35 rows=1) (actual time=0.0373..0.0394 rows=1 loops=1)
 
EXPLAIN ANALYZE
SELECT
	*
FROM emp
WHERE first_name = 'Georgi'
AND last_name = 'Wielonsky';




