-- 고객 중 가장 많은 금액을 소비한 사람, 데이터가 많아지면 정렬 비용이 더 저렴한 2번째 방식이 유리.

-- 16044
SELECT COUNT(*) FROM payment;

SHOW INDEX FROM payment;
-- PRIMARY	1	payment_id	A	16086
-- idx_fk_staff_id	1	staff_id	A	2
-- idx_fk_customer_id	1	customer_id	A	599
-- fk_payment_rental	1	rental_id	A	16044




-- [1]
EXPLAIN ANALYZE
SELECT
		customer_id
	,	SUM(amount)
FROM payment
GROUP BY customer_id
ORDER BY SUM(amount) DESC
LIMIT 1;

-- 1	SIMPLE	payment		index	idx_fk_customer_id	idx_fk_customer_id	2		16086	100.00	Using temporary; Using filesort

-- -> Limit: 1 row(s)  (actual time=27.5..27.5 rows=1 loops=1)
--      -> Sort: SUM(amount) DESC, limit input to 1 row(s) per chunk  (actual time=27.5..27.5 rows=1 loops=1)
--          -> Stream results  (cost=3241 rows=599) (actual time=0.15..27.3 rows=599 loops=1)
--              -> Group aggregate: sum(payment.amount)  (cost=3241 rows=599) (actual time=0.147..27 rows=599 loops=1)
--                  -> Index scan on payment using idx_fk_customer_id  (cost=1633 rows=16086) (actual time=0.133..24.2 rows=16044 loops=1)
 



-- [2]
EXPLAIN ANALYZE
SELECT
		t1.customer_id AS customer_id
	,	t1.total_amount AS total_amount
FROM(
	SELECT
			customer_id
		,	SUM(amount) AS total_amount
	FROM payment
	GROUP BY customer_id
)t1
ORDER BY total_amount
LIMIT 1;

-- 1	PRIMARY	<derived2>		ALL					16086	100.00	Using filesort
-- 2	DERIVED	payment		index	idx_fk_customer_id	idx_fk_customer_id	2		16086	100.00	

-- -> Limit: 1 row(s)  (cost=3371..3371 rows=1) (actual time=23.9..23.9 rows=1 loops=1)
--      -> Sort: t1.total_amount, limit input to 1 row(s) per chunk  (cost=3371..3371 rows=1) (actual time=23.9..23.9 rows=1 loops=1)
--          -> Table scan on t1  (cost=3301..3311 rows=599) (actual time=23.7..23.7 rows=599 loops=1)
--              -> Materialize  (cost=3301..3301 rows=599) (actual time=23.7..23.7 rows=599 loops=1)
--                  -> Group aggregate: sum(payment.amount)  (cost=3241 rows=599) (actual time=0.167..23.4 rows=599 loops=1)
--                      -> Index scan on payment using idx_fk_customer_id  (cost=1633 rows=16086) (actual time=0.135..20.7 rows=16044 loops=1)
 






