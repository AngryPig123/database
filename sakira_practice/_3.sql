-- 대여 수가 가장 많은 영화 TOP 5, 다른 방법이 생각이 안남.. 굳이 뽑자면 드라이빙 테이블 변경, 무조건 드라이빙 테이블에 데이터가 많은 녀석을 두는게 정답이 아님. 여러가지 케이스를 가지고 확인 필요

-- 16044
SELECT COUNT(*) FROM rental;

-- 4581
SELECT COUNT(*) FROM inventory;




-- [1]

EXPLAIN ANALYZE
SELECT
		i.film_id AS film_id
	,	COUNT(i.film_id) AS count
FROM rental r 
INNER JOIN inventory i ON i.inventory_id = r.inventory_id
GROUP BY i.film_id
ORDER BY COUNT(i.film_id) DESC
LIMIT 5;

-- 1	SIMPLE	i		index	PRIMARY,idx_fk_film_id,idx_store_id_film_id	idx_fk_film_id	2		4581	100.00	Using index; Using temporary; Using filesort
-- 1	SIMPLE	r		ref	idx_fk_inventory_id	idx_fk_inventory_id	3	sakila.i.inventory_id	3	100.00	Using index

-- -> Limit: 5 row(s)  (actual time=18.7..18.7 rows=5 loops=1)
--      -> Sort: count DESC, limit input to 5 row(s) per chunk  (actual time=18.7..18.7 rows=5 loops=1)
--          -> Stream results  (cost=4894 rows=958) (actual time=0.0943..18.5 rows=958 loops=1)
--              -> Group aggregate: count(i.film_id)  (cost=4894 rows=958) (actual time=0.092..18.3 rows=958 loops=1)
--                  -> Nested loop inner join  (cost=3251 rows=16428) (actual time=0.0511..16.8 rows=16044 loops=1)
--                      -> Covering index scan on i using idx_fk_film_id  (cost=461 rows=4581) (actual time=0.0378..1.34 rows=4581 loops=1)
--                      -> Covering index lookup on r using idx_fk_inventory_id (inventory_id=i.inventory_id)  (cost=0.251 rows=3.59) (actual time=0.00211..0.00294 rows=3.5 loops=4581)




-- [2]

EXPLAIN ANALYZE
SELECT  /*! STRAIGHT_JOIN */
		i.film_id AS film_id
	,	COUNT(i.film_id) AS count
FROM rental r 
INNER JOIN inventory i ON i.inventory_id = r.inventory_id
GROUP BY i.film_id
ORDER BY COUNT(i.film_id) DESC
LIMIT 5;

-- 1	SIMPLE	r		index	idx_fk_inventory_id	idx_fk_inventory_id	3		16424	100.00	Using index; Using temporary; Using filesort
-- 1	SIMPLE	i		eq_ref	PRIMARY,idx_fk_film_id,idx_store_id_film_id	PRIMARY	3	sakila.r.inventory_id	1	100.00	

-- -> Limit: 5 row(s)  (actual time=19.7..19.7 rows=5 loops=1)
--      -> Sort: count DESC, limit input to 5 row(s) per chunk  (actual time=19.7..19.7 rows=5 loops=1)
--          -> Table scan on <temporary>  (actual time=19.5..19.6 rows=958 loops=1)
--              -> Aggregate using temporary table  (actual time=19.5..19.5 rows=958 loops=1)
--                  -> Nested loop inner join  (cost=7415 rows=16424) (actual time=0.0504..14 rows=16044 loops=1)
--                      -> Covering index scan on r using idx_fk_inventory_id  (cost=1667 rows=16424) (actual time=0.0379..4.49 rows=16044 loops=1)
--                      -> Single-row index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=0.25 rows=1) (actual time=400e-6..427e-6 rows=1 loops=16044)
 
 