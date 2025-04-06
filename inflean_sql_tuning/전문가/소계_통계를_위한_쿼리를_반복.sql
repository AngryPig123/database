-- 통계/소계 함수 학습하고 다시오자...

-- before

-- 1	PRIMARY	entry_record		range	I_REGION	I_REGION	4		329468	100.00	Using where; Using index
-- 2	UNION	entry_record		ALL	I_REGION				658935	50.00	Using where; Using temporary
-- 3	UNION	entry_record		range	I_REGION	I_REGION	4		329468	100.00	Using where; Using index

-- -> Append  (cost=198636 rows=4) (actual time=181..1572 rows=9 loops=1)
--      -> Stream results  (cost=99318 rows=4) (actual time=181..453 rows=4 loops=1)
--          -> Group aggregate: count(0)  (cost=99318 rows=4) (actual time=181..453 rows=4 loops=1)
--              -> Filter: (entry_record.REGION <> '')  (cost=66371 rows=329468) (actual time=0.0213..416 rows=659985 loops=1)
--                  -> Covering index range scan on entry_record using I_REGION over (NULL < REGION < '') OR ('' < REGION)  (cost=66371 rows=329468) (actual time=0.0202..374 rows=659985 loops=1)
--      -> Stream results  (actual time=927..927 rows=4 loops=1)
--          -> Table scan on <temporary>  (actual time=927..927 rows=4 loops=1)
--              -> Aggregate using temporary table  (actual time=927..927 rows=4 loops=1)
--                  -> Filter: (entry_record.REGION <> '')  (cost=67529 rows=329468) (actual time=2.95..741 rows=659985 loops=1)
--                      -> Table scan on entry_record  (cost=67529 rows=658935) (actual time=2.94..695 rows=660000 loops=1)
--      -> Stream results  (cost=99318 rows=1) (actual time=192..192 rows=1 loops=1)
--          -> Aggregate: count(0)  (cost=99318 rows=1) (actual time=192..192 rows=1 loops=1)
--              -> Filter: (entry_record.REGION <> '')  (cost=66371 rows=329468) (actual time=0.0286..168 rows=659985 loops=1)
--                  -> Covering index range scan on entry_record using I_REGION over (NULL < REGION < '') OR ('' < REGION)  (cost=66371 rows=329468) (actual time=0.028..128 rows=659985 loops=1)
 
EXPLAIN ANALYZE
SELECT
		region AS region
	,	NULL AS gate
    ,	COUNT(*) AS cnt
FROM entry_record
WHERE region <> ''
GROUP BY region
UNION ALL
SELECT
		region AS region
	,	gate AS gate
    ,	COUNT(*) AS cnt
FROM entry_record
WHERE region <> ''
GROUP BY region, gate
UNION ALL
SELECT
		NULL AS region
	,	NULL AS gate
    ,	COUNT(*)
FROM entry_record
WHERE region <> '';




-- after

-- 1	SIMPLE	entry_record		ALL	I_REGION				658935	50.00	Using where; Using filesort

-- -> Group aggregate with rollup: count(0)  (cost=132196 rows=12.2) (actual time=399..454 rows=9 loops=1)
--      -> Sort: entry_record.REGION, entry_record.GATE  (cost=66302 rows=658935) (actual time=365..398 rows=659985 loops=1)
--          -> Filter: (entry_record.REGION <> '')  (cost=66302 rows=658935) (actual time=0.0333..207 rows=659985 loops=1)
--              -> Table scan on entry_record  (cost=66302 rows=658935) (actual time=0.0322..161 rows=660000 loops=1)
 

EXPLAIN ANALYZE
SELECT
		region AS region
	,	gate AS gate
    ,	COUNT(*) AS cnt
FROM entry_record
WHERE region <> ''
GROUP BY ROLLUP(region, gate);


