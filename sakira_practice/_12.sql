-- 대여가 가장 많은 카테고리

-- 1	SIMPLE	fc		index	PRIMARY,fk_film_category_category	fk_film_category_category	1		1000	100.00	Using index; Using temporary; Using filesort
-- 1	SIMPLE	i		ref	PRIMARY,idx_fk_film_id	idx_fk_film_id	2	sakila.fc.film_id	4	100.00	Using index
-- 1	SIMPLE	r		ref	idx_fk_inventory_id	idx_fk_inventory_id	3	sakila.i.inventory_id	3	100.00	Using index

EXPLAIN
SELECT
		fc.category_id
	,	COUNT(fc.category_id)
FROM rental r
INNER JOIN inventory i ON i.inventory_id = r.inventory_id
INNER JOIN film_category fc ON fc.film_id = i.film_id
GROUP BY fc.category_id
ORDER BY COUNT(fc.category_id) DESC
LIMIT 1;


