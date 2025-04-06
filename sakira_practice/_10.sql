-- 가장 오래된 영화 10개 (last_update 기준), 굳이 꼽자면 인덱스 추가. last_update + film_id, 복합 인덱스의 경우 어떤 값을 먼저두는지에 따라 결과가 달라짐.
-- 정렬 기준에 따라 먼저두는 인덱스를 결정. 해당 인덱스는 날짜를 기준으로 정렬하는 목적으로 사용되는거니 last_update를 먼저 두고 film_id를 둔다.




-- [1]
EXPLAIN ANALYZE
SELECT 
	film_id
FROM film
ORDER BY last_update
LIMIT 10;

-- 1	SIMPLE	film		ALL					1000	100.00	Using filesort

-- -> Limit: 10 row(s)  (cost=103 rows=10) (actual time=0.528..0.529 rows=10 loops=1)
--      -> Sort: film.last_update, limit input to 10 row(s) per chunk  (cost=103 rows=1000) (actual time=0.527..0.528 rows=10 loops=1)
--          -> Table scan on film  (cost=103 rows=1000) (actual time=0.0448..0.313 rows=1000 loops=1)
 
 
 
 
 -- [2]
 
 CREATE INDEX idx_film_last_date_film_id ON film (last_update, film_id);
 
EXPLAIN ANALYZE
SELECT 
	film_id
FROM film
ORDER BY last_update
LIMIT 10;

-- 1	SIMPLE	film		index		idx_film_last_date_film_id	6		10	100.00	Using index

-- -> Limit: 10 row(s)  (cost=0.04 rows=10) (actual time=0.0453..0.0479 rows=10 loops=1)
--      -> Covering index scan on film using idx_film_last_date_film_id  (cost=0.04 rows=10) (actual time=0.0439..0.0459 rows=10 loops=1)

