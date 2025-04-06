-- 3회 이상 대여한 고객만 출력, 최적화 할게 없음

SHOW INDEX FROM rantel;

-- 16044
SELECT COUNT(*) FROM rental;




-- [1]
EXPLAIN ANALYZE
SELECT
		customer_id
	,	COUNT(rental_id)
FROM rental
GROUP BY customer_id
HAVING COUNT(rental_id) >=3;

-- 1	SIMPLE	rental		index	rental_date,idx_fk_customer_id,idx_customer_rental_date	idx_fk_customer_id	2		16424	100.00	Using index

-- -> Filter: (count(rental.rental_id) >= 3)  (cost=3309 rows=599) (actual time=0.0549..5.91 rows=599 loops=1)
--      -> Group aggregate: count(rental.rental_id), count(rental.rental_id)  (cost=3309 rows=599) (actual time=0.0537..5.81 rows=599 loops=1)
--          -> Covering index scan on rental using idx_fk_customer_id  (cost=1667 rows=16424) (actual time=0.0433..4.48 rows=16044 loops=1)
