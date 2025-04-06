-- 실행 계획과 수행 결과를 봐도 이해가 잘 안됨 나중에 더 적당한 예시로 확인해보자!

SHOW INDEX FROM grade;
-- GRADE	0	PRIMARY	1	EMP_ID	A	299449				BTREE			YES	
-- GRADE	0	PRIMARY	2	GRADE_NAME	A	442545				BTREE			YES	
-- GRADE	0	PRIMARY	3	START_DATE	A	443259				BTREE			YES	


-- 1	PRIMARY	grade		ALL					443259	1.00	Using where
-- 2	UNION	grade		ALL					443259	1.00	Using where
-- 3	UNION	grade		ALL					443259	1.00	Using where

-- -> Append  (cost=135246 rows=3) (actual time=126..373 rows=3 loops=1)
--      -> Stream results  (cost=45082 rows=1) (actual time=126..126 rows=1 loops=1)
--          -> Aggregate: count(0)  (cost=45082 rows=1) (actual time=126..126 rows=1 loops=1)
--              -> Filter: ((grade.END_DATE = DATE'9999-01-01') and (grade.GRADE_NAME = 'Manager'))  (cost=44639 rows=4433) (actual time=43..126 rows=9 loops=1)
--                  -> Table scan on grade  (cost=44639 rows=443259) (actual time=0.0349..93.9 rows=443308 loops=1)
--      -> Stream results  (cost=45082 rows=1) (actual time=122..122 rows=1 loops=1)
--          -> Aggregate: count(0)  (cost=45082 rows=1) (actual time=122..122 rows=1 loops=1)
--              -> Filter: ((grade.END_DATE = DATE'9999-01-01') and (grade.GRADE_NAME = 'Technique Leader'))  (cost=44639 rows=4433) (actual time=0.0341..122 rows=12055 loops=1)
--                  -> Table scan on grade  (cost=44639 rows=443259) (actual time=0.024..90.8 rows=443308 loops=1)
--      -> Stream results  (cost=45082 rows=1) (actual time=125..125 rows=1 loops=1)
--          -> Aggregate: count(0)  (cost=45082 rows=1) (actual time=125..125 rows=1 loops=1)
--              -> Filter: ((grade.END_DATE = DATE'9999-01-01') and (grade.GRADE_NAME = 'Assistant Engineer'))  (cost=44639 rows=4433) (actual time=0.0292..125 rows=3588 loops=1)
--                  -> Table scan on grade  (cost=44639 rows=443259) (actual time=0.0235..93.1 rows=443308 loops=1)
 
EXPLAIN ANALYZE
SELECT
		'BOSS' AS grade_name
	,	COUNT(*) AS cnt
FROM grade
WHERE grade_name = 'Manager'
AND end_date = '9999-01-01'
UNION ALL
SELECT
		'TL' AS grade_name
	,	COUNT(*) AS cnt
FROM grade
WHERE grade_name = 'Technique Leader'
AND end_date = '9999-01-01'
UNION ALL
SELECT
		'AE' AS grade_name
	,	COUNT(*) AS cnt
FROM grade
WHERE grade_name = 'Assistant Engineer'
AND end_date = '9999-01-01';




-- after
-- 1	SIMPLE	grade		ALL	PRIMARY				443259	3.00	Using where; Using temporary

-- -> Table scan on <temporary>  (actual time=190..190 rows=3 loops=1)
--      -> Aggregate using temporary table  (actual time=190..190 rows=3 loops=1)
--          -> Filter: ((grade.END_DATE = DATE'9999-01-01') and (grade.GRADE_NAME in ('Manager','Technique Leader','Assistant Engineer')))  (cost=44639 rows=13298) (actual time=0.0492..179 rows=15652 loops=1)
--              -> Table scan on grade  (cost=44639 rows=443259) (actual time=0.04..132 rows=443308 loops=1)
  
EXPLAIN ANALYZE
SELECT 
		CASE grade_name WHEN 'Manager' THEN 'BOSS'
						WHEN 'Technique Leader' THEN 'TL'
						WHEN 'Assistant Engineer' THEN 'AE'
						ELSE 'NA' END AS grade_name
	,	COUNT(*) AS cnt
FROM grade
WHERE grade_name IN ('Manager', 'Technique Leader', 'Assistant Engineer')
AND end_date = '9999-01-01'
GROUP BY grade_name;









