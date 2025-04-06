-- 모든 고객에 대해 마지막 대여 일시를 출력, Using index for group-by 키워드가 발생할 수 있게 인덱스 추가 (customer_id, rental_date)

-- 16044
SELECT COUNT(*) FROM rental;

SHOW INDEX FROM rental;

-- [1]
EXPLAIN ANALYZE
SELECT
		customer_id AS customer_id
	,	MAX(rental_date) AS last_rental_date
FROM rental
GROUP BY customer_id;

-- 1	SIMPLE	rental		index	rental_date,idx_fk_customer_id	idx_fk_customer_id	2		16424	100.00	

-- -> Group aggregate: max(rental.rental_date)  (cost=3309 rows=599) (actual time=0.168..29 rows=599 loops=1)
--      -> Index scan on rental using idx_fk_customer_id  (cost=1667 rows=16424) (actual time=0.156..26.6 rows=16044 loops=1)




-- [2]
CREATE INDEX idx_customer_rental_date ON rental (customer_id, rental_date);

EXPLAIN ANALYZE
SELECT
		customer_id AS customer_id
	,	MAX(rental_date) AS last_rental_date
FROM rental
GROUP BY customer_id;

-- 1	SIMPLE	rental		range	rental_date,idx_fk_customer_id,idx_customer_rental_date	idx_customer_rental_date	2		600	100.00	Using index for group-by

-- -> Covering index skip scan for grouping on rental using idx_customer_rental_date  (cost=202 rows=600) (actual time=0.0441..3.73 rows=599 loops=1)
 
 