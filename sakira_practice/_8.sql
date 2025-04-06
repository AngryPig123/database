-- 한 번도 영화를 빌린 적 없는 고객 목록




-- [1]
EXPLAIN ANALYZE
SELECT
	c.customer_id
FROM customer c
LEFT OUTER JOIN(
	SELECT 
		DISTINCT customer_id
	FROM rental
) c2 ON c2.customer_id = c.customer_id
WHERE c2.customer_id IS NULL;

-- 1	PRIMARY	c		index		idx_fk_store_id	1		599	100.00	Using index
-- 1	PRIMARY	<derived2>		ref	<auto_key0>	<auto_key0>	2	sakila.c.customer_id	10	100.00	Using where; Not exists; Using index
-- 2	DERIVED	rental		range	rental_date,idx_fk_customer_id,idx_customer_rental_date	idx_fk_customer_id	2		600	100.00	Using index for group-by

-- -> Filter: (c2.customer_id is null)  (cost=37499 rows=359400) (actual time=2.44..2.44 rows=0 loops=1)
--      -> Nested loop antijoin  (cost=37499 rows=359400) (actual time=2.44..2.44 rows=0 loops=1)
--          -> Covering index scan on c using idx_fk_store_id  (cost=61.2 rows=599) (actual time=0.0291..0.147 rows=599 loops=1)
--          -> Covering index lookup on c2 using <auto_key0> (customer_id=c.customer_id)  (cost=244..246 rows=10) (actual time=0.00373..0.00373 rows=1 loops=599)
--              -> Materialize  (cost=243..243 rows=600) (actual time=1.89..1.89 rows=599 loops=1)
--                  -> Covering index skip scan for deduplication on rental using idx_fk_customer_id  (cost=183 rows=600) (actual time=0.0102..1.52 rows=599 loops=1)
 
 
 
 
 -- [2]
EXPLAIN ANALYZE
SELECT
	c.customer_id
FROM customer c
LEFT OUTER JOIN rental r ON r.customer_id = c.customer_id
WHERE r.customer_id IS NULL;
 
-- 1	SIMPLE	c		index		idx_fk_store_id	1		599	100.00	Using index
-- 1	SIMPLE	r		ref	idx_fk_customer_id,idx_customer_rental_date	idx_fk_customer_id	2	sakila.c.customer_id	27	100.00	Using where; Not exists; Using index
 
--  -> Filter: (r.customer_id is null)  (cost=1856 rows=16424) (actual time=2.78..2.78 rows=0 loops=1)
--      -> Nested loop antijoin  (cost=1856 rows=16424) (actual time=2.78..2.78 rows=0 loops=1)
--          -> Covering index scan on c using idx_fk_store_id  (cost=61.2 rows=599) (actual time=0.0265..0.131 rows=599 loops=1)
--          -> Covering index lookup on r using idx_fk_customer_id (customer_id=c.customer_id)  (cost=0.259 rows=27.4) (actual time=0.00434..0.00434 rows=1 loops=599)
 