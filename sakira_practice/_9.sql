-- 배우별 영화 촬영한 횟수 TOP 10 출력




-- [1]
EXPLAIN ANALYZE
SELECT
	a.actor_id
FROM actor a
INNER JOIN (
	SELECT
		actor_id AS actor_id
	FROM film_actor
	GROUP BY actor_id
	ORDER BY COUNT(actor_id) DESC
	LIMIT 10
) t1 ON t1.actor_id = a.actor_id;

-- 1	PRIMARY	<derived2>		ALL					10	100.00	
-- 1	PRIMARY	a		eq_ref	PRIMARY	PRIMARY	2	t1.actor_id	1	100.00	Using index
-- 2	DERIVED	film_actor		index	PRIMARY,idx_fk_film_id	PRIMARY	4		5462	100.00	Using index; Using temporary; Using filesort

-- -> Nested loop inner join  (cost=5 rows=0) (actual time=2.72..2.78 rows=10 loops=1)
--      -> Table scan on t1  (cost=2.5..2.5 rows=0) (actual time=2.7..2.7 rows=10 loops=1)
--          -> Materialize  (cost=0..0 rows=0) (actual time=2.69..2.69 rows=10 loops=1)
--              -> Limit: 10 row(s)  (actual time=2.68..2.68 rows=10 loops=1)
--                  -> Sort: count(film_actor.actor_id) DESC, limit input to 10 row(s) per chunk  (actual time=2.68..2.68 rows=10 loops=1)
--                      -> Stream results  (cost=1095 rows=200) (actual time=0.0584..2.6 rows=200 loops=1)
--                          -> Group aggregate: count(film_actor.actor_id)  (cost=1095 rows=200) (actual time=0.0559..2.54 rows=200 loops=1)
--                              -> Covering index scan on film_actor using PRIMARY  (cost=549 rows=5462) (actual time=0.0471..1.93 rows=5462 loops=1)
--      -> Single-row covering index lookup on a using PRIMARY (actor_id=t1.actor_id)  (cost=0.26 rows=1) (actual time=0.00783..0.00786 rows=1 loops=10)
 