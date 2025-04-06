-- 1 ] 기본키를 변형하는 나쁜 SQL
SELECT COUNT(*) FROM emp;
SHOW INDEX FROM emp;
-- PRIMARY	1	EMP_ID
-- I_HIRE_DATE	1	HIRE_DATE
-- I_GENDER_LAST_NAME	1	GENDER
-- I_GENDER_LAST_NAME	2	LAST_NAME

-- before
EXPLAIN
SELECT
	*
FROM emp
WHERE SUBSTRING(emp_id,1,4) = 1100
AND LENGTH(EMP_ID) = 5;

-- after
EXPLAIN
SELECT
	*
FROM emp
WHERE emp_id BETWEEN 11000 AND 11009;


-- 2 ] 불필요한 함수를 포함하는 나쁜 SQL
select 
	gender 
from emp GROUP BY gender;

EXPLAIN
SELECT 
		IFNULL(GENDER,'NO DATA') AS gender
	,	COUNT(1) AS count
FROM emp
GROUP BY IFNULL(gender,'NO DATA');

EXPLAIN
SELECT 
		GENDER AS gender
	,	COUNT(*) AS count
FROM emp
GROUP BY gender;

-- 3 ] 인덱스를 활용하지 못하는 나쁜 SQL

SHOW INDEX FROM salary;
-- PRIMARY	1	EMP_ID
-- PRIMARY	2	START_DATE
-- I_IS_YN	1	IS_YN

-- -> Aggregate: count(0)  (cost=292517 rows=1) (actual time=659..659 rows=1 loops=1)
--      -> Filter: (salary.IS_YN = 1)  (cost=266492 rows=260244) (actual time=646..657 rows=42842 loops=1)
--          -> Covering index scan on salary using I_IS_YN  (cost=266492 rows=2.6e+6) (actual time=0.0307..463 rows=2.84e+6 loops=1)

-- -> Aggregate: count(salary.IS_YN)  (cost=16593 rows=1) (actual time=13.5..13.5 rows=1 loops=1)
--      -> Covering index lookup on salary using I_IS_YN (IS_YN='1')  (cost=8310 rows=82824) (actual time=0.0336..11.2 rows=42842 loops=1)
 
EXPLAIN
SELECT
	COUNT(is_yn)
FROM salary
WHERE is_yn = 1;

EXPLAIN
SELECT
	COUNT(is_yn)
FROM salary
WHERE is_yn = '1';


-- 4 ] FTS(full table scan) 방식으로 수행하는 나쁜 SQL
SHOW INDEX FROM emp;
-- PRIMARY	1	EMP_ID
-- I_HIRE_DATE	1	HIRE_DATE
-- I_GENDER_LAST_NAME	1	GENDER
-- I_GENDER_LAST_NAME	2	LAST_NAME

-- -> Filter: (emp.HIRE_DATE like '1994%')  (cost=30175 rows=33266) (actual time=0.0454..165 rows=14835 loops=1)
--      -> Table scan on emp  (cost=30175 rows=299423) (actual time=0.0384..101 rows=300024 loops=1)
EXPLAIN
SELECT
		FIRST_NAME
	,	LAST_NAME
FROM emp
WHERE hire_date LIKE '1994%';

-- -> Index range scan on emp using I_HIRE_DATE over ('1994-01-01' <= HIRE_DATE < '1995-01-01'), with index condition: ((emp.HIRE_DATE >= DATE'1994-01-01') and (emp.HIRE_DATE < DATE'1995-01-01'))  (cost=12673 rows=28162) (actual time=0.0362..49.4 rows=14835 loops=1)

EXPLAIN 
SELECT
		FIRST_NAME
	,	LAST_NAME
FROM emp
WHERE hire_date >= '1994-01-01'
AND hire_date < '1995-01-01';


-- 5 ] 컬럼을 결합해서 사용하는 나쁜 SQL

SHOW INDEX FROM emp;
-- PRIMARY	1	EMP_ID
-- I_HIRE_DATE	1	HIRE_DATE
-- I_GENDER_LAST_NAME	1	GENDER
-- I_GENDER_LAST_NAME	2	LAST_NAME

-- 1	SIMPLE	emp		ALL					299423	100.00	Using where
EXPLAIN
SELECT
	*
FROM emp
WHERE CONCAT(gender ,' ' , LAST_NAME) = 'M Radwan';

-- 1	SIMPLE	emp		ref	I_GENDER_LAST_NAME	I_GENDER_LAST_NAME	51	const,const	102	100.00	
EXPLAIN
SELECT
	*
FROM emp
WHERE gender = 'M'
AND last_name = 'Radwan';


-- 6 ] 습관적으로 중복을 제거하는 나쁜 SQL
SHOW INDEX FROM emp;
-- PRIMARY	1	EMP_ID
-- I_HIRE_DATE	1	HIRE_DATE
-- I_GENDER_LAST_NAME	1	GENDER
-- I_GENDER_LAST_NAME	2	LAST_NAME

-- 1	SIMPLE	s		ref	PRIMARY,I_IS_YN	I_IS_YN	4	const	82824	100.00	Using temporary
-- 1	SIMPLE	e		eq_ref	PRIMARY	PRIMARY	4	tuning.s.EMP_ID	1	100.00	
EXPLAIN
SELECT 
		DISTINCT e.emp_id
	, 	e.first_name
    ,	e.last_name
    ,	s.annual_salary
FROM emp e
INNER JOIN salary s ON (s.emp_id = e.emp_id)
WHERE s.is_yn = '1';

-- 42842
SELECT 
	COUNT(*)
FROM emp e
INNER JOIN salary s ON (s.emp_id = e.emp_id)
WHERE s.is_yn = '1';

-- 42842
SELECT 
	COUNT(DISTINCT e.emp_id)
FROM emp e
INNER JOIN salary s ON (s.emp_id = e.emp_id)
WHERE s.is_yn = '1';

EXPLAIN
SELECT 
		e.emp_id
	, 	e.first_name
    ,	e.last_name
    ,	s.annual_salary
FROM emp e
INNER JOIN salary s ON (s.emp_id = e.emp_id)
WHERE s.is_yn = '1';


-- 7 ] UNION문으로 쿼리를 합치는 나쁜 SQL
SHOW INDEX FROM emp;
-- PRIMARY	1	EMP_ID
-- I_HIRE_DATE	1	HIRE_DATE
-- I_GENDER_LAST_NAME	1	GENDER
-- I_GENDER_LAST_NAME	2	LAST_NAME

-- -> Table scan on <union temporary>  (cost=48.7..54 rows=226) (actual time=0.141..0.199 rows=226 loops=1)
--      -> Union materialize with deduplication  (cost=48.7..48.7 rows=226) (actual time=0.14..0.14 rows=226 loops=1)
--          -> Covering index lookup on EMP using I_GENDER_LAST_NAME (GENDER='M', LAST_NAME='Baba')  (cost=15.4 rows=135) (actual time=0.0338..0.0553 rows=135 loops=1)
--          -> Covering index lookup on EMP using I_GENDER_LAST_NAME (GENDER='F', LAST_NAME='Baba')  (cost=10.7 rows=91) (actual time=0.0209..0.0291 rows=91 loops=1)

-- 1	PRIMARY	EMP		ref	I_GENDER_LAST_NAME	I_GENDER_LAST_NAME	51	const,const	135	100.00	Using index
-- 2	UNION	EMP		ref	I_GENDER_LAST_NAME	I_GENDER_LAST_NAME	51	const,const	91	100.00	Using index
-- 3	UNION RESULT	<union1,2>		ALL							Using temporary

EXPLAIN
SELECT
		'M' AS gender
	,	emp_id
FROM EMP
WHERE gender = 'M'
AND last_name = 'Baba'
UNION
SELECT
		'F' AS gender
	,	emp_ID
FROM EMP
WHERE gender = 'F'
AND last_name = 'Baba';

-- 226
SELECT
	COUNT(t1.gender)
FROM
(
	SELECT
			'M' AS gender
		,	emp_id
	FROM EMP
	WHERE gender = 'M'
	AND last_name = 'Baba'
	UNION
	SELECT
			'F' AS gender
		,	emp_ID
	FROM EMP
	WHERE gender = 'F'
	AND last_name = 'Baba'
) t1;

-- 226
SELECT
	COUNT(*)
FROM EMP
WHERE last_name = 'Baba';

-- 1	SIMPLE	EMP		range	I_GENDER_LAST_NAME	I_GENDER_LAST_NAME	51		29942	100.00	Using where; Using index for skip scan
EXPLAIN
SELECT
	COUNT(*)
FROM EMP
WHERE last_name = 'Baba';

-- 1	PRIMARY	EMP		ref	I_GENDER_LAST_NAME	I_GENDER_LAST_NAME	51	const,const	135	100.00	Using index
-- 2	UNION	EMP		ref	I_GENDER_LAST_NAME	I_GENDER_LAST_NAME	51	const,const	91	100.00	Using index
EXPLAIN
SELECT
		'M' AS gender
	,	emp_id
FROM EMP
WHERE gender = 'M'
AND last_name = 'Baba'
UNION ALL
SELECT
		'F' AS gender
	,	emp_ID
FROM EMP
WHERE gender = 'F'
AND last_name = 'Baba';


-- 8 ] 인덱스를 생각하지 않고 작성한 나쁜 SQL

SHOW INDEX FROM emp;
-- PRIMARY	1	EMP_ID
-- I_HIRE_DATE	1	HIRE_DATE
-- I_GENDER_LAST_NAME	1	GENDER
-- I_GENDER_LAST_NAME	2	LAST_NAME

-- 1	SIMPLE	emp		index	I_GENDER_LAST_NAME	I_GENDER_LAST_NAME	51		299423	100.00	Using index; Using temporary
EXPLAIN
SELECT
		last_name
	,	gender
	,	COUNT(1) AS count
FROM emp
GROUP BY last_name, gender;

EXPLAIN
SELECT
		last_name
	,	gender
	,	COUNT(1) AS count
FROM emp
GROUP BY gender, last_name;


-- 9 ] 엉뚱한 인덱스를 사용하는 나쁜 SQL : 접근 제한을 걸때 데이터의 수를 줄이는게 튜닝의 핵심!

SHOW INDEX FROM emp;
-- PRIMARY	1	EMP_ID
-- I_HIRE_DATE	1	HIRE_DATE
-- I_GENDER_LAST_NAME	1	GENDER
-- I_GENDER_LAST_NAME	2	LAST_NAME

-- 1	SIMPLE	emp		range	PRIMARY,I_HIRE_DATE	PRIMARY	4		149711	11.11	Using where
-- -> Filter: ((emp.HIRE_DATE like '1989%') and (emp.EMP_ID > 100000))  (cost=29980 rows=16633) (actual time=0.0239..101 rows=20001 loops=1)
--      -> Index range scan on emp using PRIMARY over (100000 < EMP_ID)  (cost=29980 rows=149711) (actual time=0.0115..58.3 rows=210024 loops=1)
EXPLAIN
SELECT
	emp_id
FROM emp
WHERE hire_date LIKE '1989%'
AND emp_id > 100000;

-- 1	SIMPLE	emp		range	PRIMARY,I_HIRE_DATE	I_HIRE_DATE	7		49824	50.00	Using where; Using index
-- -> Filter: ((emp.EMP_ID > 100000) and (emp.HIRE_DATE between '1989-01-01' and '1989-12-31'))  (cost=10005 rows=24912) (actual time=0.0161..14.1 rows=20001 loops=1)
--      -> Covering index range scan on emp using I_HIRE_DATE over ('1989-01-01' <= HIRE_DATE <= '1989-12-31' AND 100000 < EMP_ID)  (cost=10005 rows=49824) (actual time=0.0126..7.08 rows=28378 loops=1)
EXPLAIN
SELECT
	emp_id
FROM emp
WHERE emp_id > 100000
AND hire_date BETWEEN '1989-01-01' AND '1989-12-31';


-- 10 ] 잘못된 OOOO 테이블로 수행되는 나쁜 SQL : 조건절에 조건이 걸려있는 테이블을 드라이빙 테이블로 두는걸 고려해보자! /*! STRAIGHT_JOIN */ 

SHOW INDEX FROM dept_emp_mapping;
-- PRIMARY	1	EMP_ID
-- PRIMARY	2	DEPT_ID
-- I_DEPT_ID	1	DEPT_ID

SHOW INDEX FROM dept;
-- PRIMARY	1	DEPT_ID
-- UI_DEPT_NAME	1	DEPT_NAME


-- 1	SIMPLE	d		index	PRIMARY	UI_DEPT_NAME	122		9	100.00	Using index
-- 1	SIMPLE	de		ref	I_DEPT_ID	I_DEPT_ID	12	tuning.d.DEPT_ID	40355	33.33	Using where

-- -> Nested loop inner join  (cost=41297 rows=121055) (actual time=0.392..472 rows=1341 loops=1)
--      -> Covering index scan on d using UI_DEPT_NAME  (cost=1.9 rows=9) (actual time=0.0184..0.0274 rows=9 loops=1)
--      -> Filter: (de.START_DATE >= DATE'2002-03-01')  (cost=702 rows=13451) (actual time=1.24..52.4 rows=149 loops=9)
--          -> Index lookup on de using I_DEPT_ID (DEPT_ID=d.DEPT_ID)  (cost=702 rows=40356) (actual time=0.558..50.8 rows=36845 loops=9)

EXPLAIN
SELECT
		de.emp_id
	,	d.dept_id
FROM dept_emp_mapping de
INNER JOIN dept d ON d.dept_id = de.dept_id
WHERE de.start_date >= '2002-03-01';

-- 1	SIMPLE	de		ALL	I_DEPT_ID				322846	33.33	Using where
-- 1	SIMPLE	d		eq_ref	PRIMARY	PRIMARY	12	tuning.de.DEPT_ID	1	100.00	Using index

-- -> Nested loop inner join  (cost=70130 rows=107605) (actual time=0.171..107 rows=1341 loops=1)
--      -> Filter: (de.START_DATE >= DATE'2002-03-01')  (cost=32469 rows=107605) (actual time=0.159..106 rows=1341 loops=1)
--          -> Table scan on de  (cost=32469 rows=322846) (actual time=0.0457..87.5 rows=331603 loops=1)
--      -> Single-row covering index lookup on d using PRIMARY (DEPT_ID=de.DEPT_ID)  (cost=0.25 rows=1) (actual time=0.0012..0.00123 rows=1 loops=1341) 

EXPLAIN
SELECT  /*! STRAIGHT_JOIN */
		de.emp_id
	,	d.dept_id
FROM dept_emp_mapping de
INNER JOIN dept d ON d.dept_id = de.dept_id
WHERE de.start_date >= '2002-03-01';
























