-- 2005년에 대여된 영화 개수, BETWEEN을 '>= AND <'로 바꾸면 더 안전하고 인덱스 최적화에 유리

SHOW INDEX FROM rental;

SELECT COUNT(*) FROM rental;




-- [1]

EXPLAIN ANALYZE
SELECT
	COUNT(*)
FROM rental
WHERE rental_date BETWEEN '2005-01-01' AND '2006-01-01';

-- 1	SIMPLE	rental		range	rental_date	rental_date	5		8212	100.00	Using where; Using index

-- -> Aggregate: count(0)  (cost=2468 rows=1) (actual time=14.3..14.3 rows=1 loops=1)
--      -> Filter: (rental.rental_date between '2005-01-01' and '2005-12-31')  (cost=1647 rows=8212) (actual time=0.0203..13.1 rows=15862 loops=1)
--          -> Covering index range scan on rental using rental_date over ('2005-01-01 00:00:00' <= rental_date <= '2005-12-31 00:00:00')  (cost=1647 rows=8212) (actual time=0.0171..5.83 rows=15862 loops=1)
 
 
 
 
-- [2]
EXPLAIN ANALYZE
SELECT
	COUNT(*)
FROM rental
WHERE rental_date >= '2005-01-01'
AND rental_date < '2006-01-01';

-- 1	SIMPLE	rental		range	rental_date	rental_date	5		8212	100.00	Using where; Using index

-- -> Aggregate: count(0)  (cost=2468 rows=1) (actual time=7.01..7.01 rows=1 loops=1)
--      -> Filter: ((rental.rental_date >= TIMESTAMP'2005-01-01 00:00:00') and (rental.rental_date < TIMESTAMP'2006-01-01 00:00:00'))  (cost=1647 rows=8212) (actual time=0.0167..6.26 rows=15862 loops=1)
--          -> Covering index range scan on rental using rental_date over ('2005-01-01 00:00:00' <= rental_date < '2006-01-01 00:00:00')  (cost=1647 rows=8212) (actual time=0.0145..4.31 rows=15862 loops=1)
 







