SHOW INDEX FROM entry_record;
-- PRIMARY	1	NO
-- PRIMARY	2	EMP_ID
-- I_REGION	1	REGION
-- I_ENTRY_TIME	1	ENTRY_TIME
-- I_GATE	1	GATE

-- before

-- 1	SIMPLE	entry_record		ref	I_GATE	I_GATE	4	const	329467	100.00	Using index
-- 1	SIMPLE	e		eq_ref	PRIMARY	PRIMARY	4	tuning.entry_record.EMP_ID	1	100.00	Using index

-- -> Aggregate: count(distinct e.EMP_ID)  (cost=181535 rows=1) (actual time=708..708 rows=1 loops=1)
--      -> Nested loop inner join  (cost=148588 rows=329467) (actual time=0.043..531 rows=250000 loops=1)
--          -> Covering index lookup on entry_record using I_GATE (GATE='A')  (cost=33275 rows=329467) (actual time=0.0351..94.3 rows=250000 loops=1)
--          -> Single-row covering index lookup on e using PRIMARY (EMP_ID=entry_record.EMP_ID)  (cost=0.25 rows=1) (actual time=0.00156..0.00158 rows=1 loops=250000)
 
EXPLAIN
SELECT
		COUNT(DISTINCT e.emp_id) AS count
FROM emp e
INNER JOIN (
	SELECT 
			emp_id
	FROM entry_record
    WHERE gate = 'A'
) record ON record.emp_id = e. emp_id;




-- after

-- 1	SIMPLE	e		index	PRIMARY	I_HIRE_DATE	3		299423	100.00	Using index
-- 1	SIMPLE	<subquery2>		eq_ref	<auto_distinct_key>	<auto_distinct_key>	4	tuning.e.EMP_ID	1	100.00	
-- 2	MATERIALIZED	entry_record		ref	I_GATE	I_GATE	4	const	329467	100.00	Using index

-- -> Aggregate: count(distinct e.EMP_ID)  (cost=19.7e+9 rows=1) (actual time=491..491 rows=1 loops=1)
--      -> Nested loop inner join  (cost=9.87e+9 rows=98.6e+9) (actual time=167..423 rows=150000 loops=1)
--          -> Covering index scan on e using I_HIRE_DATE  (cost=30175 rows=299423) (actual time=0.0246..62.7 rows=300024 loops=1)
--          -> Single-row index lookup on <subquery2> using <auto_distinct_key> (emp_id=e.EMP_ID)  (cost=66221..66221 rows=1) (actual time=0.00104..0.00108 rows=0.5 loops=300024)
--              -> Materialize with deduplication  (cost=66221..66221 rows=329467) (actual time=167..167 rows=150000 loops=1)
--                  -> Covering index lookup on er using I_GATE (GATE='A')  (cost=33275 rows=329467) (actual time=0.0223..77.8 rows=250000 loops=1)
 
EXPLAIN ANALYZE
SELECT
		COUNT(e.emp_id) AS count
FROM emp e
WHERE EXISTS (
	SELECT 
		1
	FROM entry_record er
    WHERE er.gate = 'A'
    AND er.emp_id = e.emp_id
);



















