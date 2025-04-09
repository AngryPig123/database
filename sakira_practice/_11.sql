-- 고객별 총 대여 횟수와 총 지불 금액 출력

-- before

-- 1	SIMPLE	r		index	PRIMARY,rental_date,idx_fk_customer_id	idx_fk_customer_id	2		15831	100.00	Using index
-- 1	SIMPLE	p		ref	fk_payment_rental	fk_payment_rental	5	sakila.r.rental_id	1	100.00	

-- -> Group aggregate: count(r.customer_id), sum(p.amount)  (cost=10869 rows=599) (actual time=0.228..41.8 rows=599 loops=1)
--      -> Nested loop inner join  (cost=7221 rows=15831) (actual time=0.0808..40.1 rows=16044 loops=1)
--          -> Covering index scan o...

SHOW INDEX FROM payment;
-- PRIMARY	1	payment_id
-- idx_fk_staff_id	1	staff_id
-- idx_fk_customer_id	1	customer_id
-- fk_payment_rental	1	rental_id

EXPLAIN
SELECT
		COUNT(r.customer_id)
	,	SUM(p.amount)
FROM rental r
INNER JOIN payment p ON p.rental_id = r.rental_id
GROUP BY r.customer_id;












