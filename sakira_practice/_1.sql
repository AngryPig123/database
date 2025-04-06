-- 가장 많이 출연한 배우 TOP 10 출력 : Top-N whti Join, LIMIT + JOIN + WHERE 전략, 전체 정렬을 수행하지 않고 상위 배우만 쿼리한후 조인.

-- 1000
SELECT COUNT(*) FROM film;

-- 5462
SELECT COUNT(*) FROM film_actor;

-- 200
SELECT COUNT(*) FROM actor;




-- [1]
EXPLAIN ANALYZE
SELECT
		a.actor_id AS actor_id
	,	COUNT(fa.actor_id) AS count
FROM film f
INNER JOIN film_actor fa ON fa.film_id = f.film_id
INNER JOIN actor a ON a.actor_id = fa.actor_id
GROUP BY a.actor_id
ORDER BY COUNT(fa.actor_id) DESC
LIMIT 10;

-- 1	SIMPLE	a		index	PRIMARY,idx_actor_last_name	PRIMARY	2		200	100.00	Using index; Using temporary; Using filesort
-- 1	SIMPLE	fa		ref	PRIMARY,idx_fk_film_id	PRIMARY	2	sakila.a.actor_id	27	100.00	Using index
-- 1	SIMPLE	f		eq_ref	PRIMARY	PRIMARY	2	sakila.fa.film_id	1	100.00	Using index

-- -> Limit: 10 row(s)  (actual time=10.5..10.5 rows=10 loops=1)
--      -> Sort: count DESC, limit input to 10 row(s) per chunk  (actual time=10.5..10.5 rows=10 loops=1)
--          -> Stream results  (cost=3076 rows=200) (actual time=0.0998..10.5 rows=200 loops=1)
--              -> Group aggregate: count(fa.actor_id)  (cost=3076 rows=200) (actual time=0.098..10.4 rows=200 loops=1)
--                  -> Nested loop inner join  (cost=2529 rows=5462) (actual time=0.0563..9.89 rows=5462 loops=1)
--                      -> Nested loop inner join  (cost=618 rows=5462) (actual time=0.051..2.72 rows=5462 loops=1)
--                          -> Covering index scan on a using PRIMARY  (cost=20.2 rows=200) (actual time=0.035..0.0875 rows=200 loops=1)
--                          -> Covering index lookup on fa using PRIMARY (actor_id=a.actor_id)  (cost=0.27 rows=27.3) (actual time=0.00653..0.0114 rows=27.3 loops=200)
--                      -> Single-row covering index lookup on f using PRIMARY (film_id=fa.film_id)  (cost=0.25 rows=1) (actual time=0.00111..0.00114 rows=1 loops=5462)
 



-- [2]

EXPLAIN ANALYZE
SELECT
		t1.actor_id
	,	t1.count
FROM(
	SELECT
			a.actor_id AS actor_id
		,	COUNT(fa.actor_id) AS count
	FROM film f
	INNER JOIN film_actor fa ON fa.film_id = f.film_id
	INNER JOIN actor a ON a.actor_id = fa.actor_id
	GROUP BY a.actor_id
) t1
ORDER BY t1.count DESC
LIMIT 10;

-- 1	PRIMARY	<derived2>		ALL					5461	100.00	Using filesort
-- 2	DERIVED	a		index	PRIMARY,idx_actor_last_name	PRIMARY	2		200	100.00	Using index
-- 2	DERIVED	fa		ref	PRIMARY,idx_fk_film_id	PRIMARY	2	sakila.a.actor_id	27	100.00	Using index
-- 2	DERIVED	f		eq_ref	PRIMARY	PRIMARY	2	sakila.fa.film_id	1	100.00	Using index

-- -> Limit: 10 row(s)  (cost=3124..3124 rows=10) (actual time=11.2..11.2 rows=10 loops=1)
--      -> Sort: t1.count DESC, limit input to 10 row(s) per chunk  (cost=3124..3124 rows=10) (actual time=11.2..11.2 rows=10 loops=1)
--          -> Table scan on t1  (cost=3096..3101 rows=200) (actual time=11.2..11.2 rows=200 loops=1)
--              -> Materialize  (cost=3096..3096 rows=200) (actual time=11.2..11.2 rows=200 loops=1)
--                  -> Group aggregate: count(fa.actor_id)  (cost=3076 rows=200) (actual time=0.0998..11.1 rows=200 loops=1)
--                      -> Nested loop inner join  (cost=2529 rows=5462) (actual time=0.0546..10.5 rows=5462 loops=1)
--                          -> Nested loop inner join  (cost=618 rows=5462) (actual time=0.0493..2.92 rows=5462 loops=1)
--                              -> Covering index scan on a using PRIMARY  (cost=20.2 rows=200) (actual time=0.0342..0.0922 rows=200 loops=1)
--                              -> Covering index lookup on fa using PRIMARY (actor_id=a.actor_id)  (cost=0.27 rows=27.3) (actual time=0.00659..0.0123 rows=27.3 loops=200)
--                          -> Single-row covering index lookup on f using PRIMARY (film_id=fa.film_id)  (cost=0.25 rows=1) (actual time=0.00119..0.00122 rows=1 loops=5462)
 



-- [3]

EXPLAIN ANALYZE
WITH top_actors AS (
    SELECT 
			fa.actor_id AS actor_id
        ,	COUNT(*) AS count
    FROM film_actor fa
    GROUP BY fa.actor_id
    ORDER BY count DESC
    LIMIT 10
)
SELECT 
    a.actor_id,
    a.first_name,
    a.last_name,
    ta.count
FROM top_actors ta
JOIN actor a ON a.actor_id = ta.actor_id
ORDER BY ta.count DESC;


-- 1	PRIMARY	<derived2>		ALL					10	100.00	Using filesort
-- 1	PRIMARY	a		eq_ref	PRIMARY	PRIMARY	2	ta.actor_id	1	100.00	
-- 2	DERIVED	fa		index	PRIMARY,idx_fk_film_id	PRIMARY	4		5462	100.00	Using index; Using temporary; Using filesort

-- -> Nested loop inner join  (cost=5.1 rows=0) (actual time=1.76..1.78 rows=10 loops=1)
--      -> Sort: ta.count DESC  (cost=2.6..2.6 rows=0) (actual time=1.75..1.75 rows=10 loops=1)
--          -> Table scan on ta  (cost=2.5..2.5 rows=0) (actual time=1.74..1.74 rows=10 loops=1)
--              -> Materialize CTE top_actors  (cost=0..0 rows=0) (actual time=1.74..1.74 rows=10 loops=1)
--                  -> Limit: 10 row(s)  (actual time=1.72..1.72 rows=10 loops=1)
--                      -> Sort: count DESC, limit input to 10 row(s) per chunk  (actual time=1.72..1.72 rows=10 loops=1)
--                          -> Stream results  (cost=1095 rows=200) (actual time=0.042..1.68 rows=200 loops=1)
--                              -> Group aggregate: count(0)  (cost=1095 rows=200) (actual time=0.0398..1.63 rows=200 loops=1)
--                                  -> Covering index scan on fa using PRIMARY  (cost=549 rows=5462) (actual time=0.0339..1.26 rows=5462 loops=1)
--      -> Single-row index lookup on a using PRIMARY (actor_id=ta.actor_id)  (cost=0.26 rows=1) (actual time=0.00283..0.00285 rows=1 loops=10)
 







