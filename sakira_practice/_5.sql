-- 카테고리별 평균 대여 요금, 추후에 데이터가 많아지면 드라이빙 테이블 조정 필요 현재 상태로도 괜찮음 

-- 4581
SELECT COUNT(*) FROM inventory;

-- 16044
SELECT COUNT(*) FROM rental;

-- 1000
SELECT COUNT(*) FROM film_category;




-- [1]

EXPLAIN ANALYZE
SELECT
		fc.category_id
	,	AVG(p.amount)
FROM film_category fc
INNER JOIN inventory i ON i.film_id = fc.film_id
INNER JOIN rental r ON r.inventory_id = i.inventory_id
INNER JOIN payment p ON p.rental_id = r.rental_id
GROUP BY fc.category_id;

-- 1	SIMPLE	fc		index	PRIMARY,fk_film_category_category	fk_film_category_category	1		1000	100.00	Using index; Using temporary; Using filesort
-- 1	SIMPLE	i		ref	PRIMARY,idx_fk_film_id	idx_fk_film_id	2	sakila.fc.film_id	4	100.00	Using index
-- 1	SIMPLE	r		ref	PRIMARY,idx_fk_inventory_id	idx_fk_inventory_id	3	sakila.i.inventory_id	3	100.00	Using index
-- 1	SIMPLE	p		ref	fk_payment_rental	fk_payment_rental	5	sakila.r.rental_id	1	100.00	

-- -> Group aggregate: avg(p.amount)  (cost=11479 rows=16) (actual time=5.83..89 rows=16 loops=1)
--      -> Nested loop inner join  (cost=9760 rows=17193) (actual time=0.0696..84.6 rows=16044 loops=1)
--          -> Nested loop inner join  (cost=3743 rows=17148) (actual time=0.0579..25.6 rows=16044 loops=1)
--              -> Nested loop inner join  (cost=830 rows=4782) (actual time=0.0498..5.72 rows=4581 loops=1)
--                  -> Covering index scan on fc using fk_film_category_category  (cost=101 rows=1000) (actual time=0.0348..0.394 rows=1000 loops=1)
--                  -> Covering index lookup on i using idx_fk_film_id (film_id=fc.film_id)  (cost=0.251 rows=4.78) (actual time=0.0035..0.00485 rows=4.58 loops=1000)
--              -> Covering index lookup on r using idx_fk_inventory_id (inventory_id=i.inventory_id)  (cost=0.251 rows=3.59) (actual time=0.00215..0.00399 rows=3.5 loops=4581)
--          -> Index lookup on p using fk_payment_rental (rental_id=r.rental_id)  (cost=0.251 rows=1) (actual time=0.00286..0.00339 rows=1 loops=16044)
 







