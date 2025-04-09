-- 중복을 제거할 수 있으면 제거 한 테이블을 가지고 조인을 한다.

-- before

-- 1	SIMPLE	de		index	PRIMARY,I_DEPT_ID	I_DEPT_ID	12		331143	100.00	Using index; Using temporary
-- 1	SIMPLE	m		ref	I_DEPT_ID	I_DEPT_ID	12	tuning.de.DEPT_ID	2	100.00	Using index; Distinct

-- -> Table scan on <temporary>  (cost=226522..230664 rows=331143) (actual time=537..537 rows=9 loops=1)
--      -> Temporary table with deduplication  (cost=226522..226522 rows=331143) (actual time=537..537 rows=9 loops=1)
--          -> Nested loop inner join  (cost=150222 rows=331143) (actual time=0.174..489 rows=331603 loops=1)
--              -> Covering index scan on de using I_DEPT_ID  (cost=33851 rows=331143) (actual time=0.0499..50.1 rows=331603 loops=1)
--              -> Limit: 1 row(s)  (cost=0.251 rows=1) (actual time=0.00118..0.00119 rows=1 loops=331603)
--                  -> Covering index lookup on m using I_DEPT_ID (DEPT_ID=de.DEPT_ID)  (cost=0.251 rows=2.67) (actual time=0.00112..0.00112 rows=1 loops=331603)
 
EXPLAIN ANALYZE
SELECT 
	DISTINCT de.dept_id
FROM manager m 
INNER JOIN dept_emp_mapping de ON de.dept_id = m.dept_id
ORDER BY de.dept_id;




-- after 
 
SELECT
		(SELECT COUNT(1) FROM dept_emp_mapping) AS dept_emp_mapping
	,	(SELECT COUNT(1) FROM manager) AS manager;

-- 1	PRIMARY	<derived2>		ALL					9	100.00	
-- 1	PRIMARY	m		ref	I_DEPT_ID	I_DEPT_ID	12	de.dept_id	2	100.00	Using index; FirstMatch(<derived2>)
-- 2	DERIVED	dept_emp_mapping		range	PRIMARY,I_DEPT_ID	I_DEPT_ID	12		9	100.00	Using index for group-by

-- -> Nested loop semijoin  (cost=14.7 rows=24) (actual time=0.186..0.197 rows=9 loops=1)
--      -> Table scan on de  (cost=7.76..10.1 rows=9) (actual time=0.177..0.178 rows=9 loops=1)
--          -> Materialize  (cost=7.47..7.47 rows=9) (actual time=0.175..0.175 rows=9 loops=1)
--              -> Covering index skip scan for deduplication on dept_emp_mapping using I_DEPT_ID  (cost=5.4 rows=9) (actual time=0.107..0.161 rows=9 loops=1)
--      -> Covering index lookup on m using I_DEPT_ID (DEPT_ID=de.dept_id)  (cost=0.749 rows=2.67) (actual time=0.00167..0.00167 rows=1 loops=9)

EXPLAIN ANALYZE
SELECT 
	de.dept_id
FROM (
	SELECT 
		DISTINCT dept_id
	FROM dept_emp_mapping
) de
WHERE EXISTS (SELECT 1 FROM manager m WHERE m.dept_id = de.dept_id);
