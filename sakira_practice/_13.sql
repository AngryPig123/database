-- 고객이 가장 좋아하는 장르(카테고리)

-- 1	PRIMARY	<derived2>		ref	<auto_key0>	<auto_key0>	8	const	10	100.00	
-- 2	DERIVED	r		index	idx_fk_inventory_id	rental_date	10		15831	100.00	Using index; Using temporary; Using filesort
-- 2	DERIVED	i		eq_ref	PRIMARY,idx_fk_film_id	PRIMARY	3	sakila.r.inventory_id	1	100.00	
-- 2	DERIVED	fc		ref	PRIMARY	PRIMARY	2	sakila.i.film_id	1	100.00	Using index

-- -> Index lookup on t1 using <auto_key0> (category_rank=1)  (cost=0.35..3.5 rows=10) (actual time=59.4..59.5 rows=999 loops=1)
--      -> Materialize  (cost=0..0 rows=0) (actual time=59.4..59.4 rows=7741 loops=1)
--          -> Window aggregate: rank() OVER (PARTITION BY r.customer_id ORDER BY category_count desc )   (actual time=55.1..56.3 rows=7741 loops=1)
--              -> Sort: r.customer_id, category_count DESC  (actual time=55.1..55.4 rows=7741 loops=1)
--                  -> Table scan on <temporary>  (actual time=52.6..53 rows=7741 loops=1)
--                      -> Aggregate using temporary table  (actual time=52.6..52.6 rows=7741 loops=1)
--                          -> Nested loop inner join  (cost=12689 rows=15831) (actual time=0.0714..45.8 rows=16044 loops=1)
--                              -> Nested loop inner join  (cost=7148 rows=15831) (actual time=0.0626..22.5 rows=16044 loops=1)
--                                  -> Covering index scan on r using rental_date  (cost=1607 rows=15831) (actual time=0.0476..3.11 rows=16044 loops=1)
--                                  -> Single-row index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=0.25 rows=1) (actual time=0.00111..0.00112 rows=1 loops=16044)
--                              -> Covering index lookup on fc using PRIMARY (film_id=i.film_id)  (cost=0.25 rows=1) (actual time=0.001..0.00131 rows=1 loops=16044)

EXPLAIN ANALYZE
SELECT
		t1.customer_id
	,	t1.category_id
    ,	t1.category_count
	,	t1.category_rank
FROM(
	SELECT
			r.customer_id AS customer_id
		,	fc.category_id AS category_id
        ,	COUNT(fc.category_id) AS category_count
		,	RANK()OVER(PARTITION BY r.customer_id ORDER BY COUNT(fc.category_id) DESC) AS category_rank
	FROM rental r
	INNER JOIN inventory i ON i.inventory_id = r.inventory_id
	INNER JOIN film_category fc ON fc.film_id = i.film_id
	GROUP BY r.customer_id, fc.category_id
) t1
WHERE t1.category_rank = 1;







