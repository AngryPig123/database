-- 부서별 평균 급여를 계산하고, 가장 높은 부서를 출력하라.
SHOW INDEX FROM departments;
-- PRIMARY	1	dept_no
-- dept_name	1	dept_name

SHOW INDEX FROM dept_manager;
-- PRIMARY	1	emp_no
-- PRIMARY	2	dept_no
-- dept_no	1	dept_no

SHOW INDEX FROM dept_emp;
-- PRIMARY	1	emp_no
-- PRIMARY	2	dept_no
-- dept_no	1	dept_no

EXPLAIN ANALYZE
SELECT
		dm.dept_no
	,	dm.emp_no
FROM departments d
INNER JOIN dept_manager dm ON dm.dept_no = d.dept_no;

EXPLAIN ANALYZE
SELECT
		de.dept_no
	,	de.emp_no
FROM departments d
INNER JOIN dept_emp de ON de.dept_no = d.dept_no;

-- 1	PRIMARY	d		index	PRIMARY	dept_name	162		9	100.00	Using index
-- 1	PRIMARY	dm		ref	dept_no	dept_no	16	employees.d.dept_no	2	100.00	Using index
-- 2	UNION	d		index	PRIMARY	dept_name	162		9	100.00	Using index
-- 2	UNION	de		ref	dept_no	dept_no	16	employees.d.dept_no	41392	100.00	Using index

-- -> Append  (cost=37673 rows=372560) (actual time=0.0456..290 rows=331627 loops=1)
--      -> Stream results  (cost=6.57 rows=24) (actual time=0.0447..0.0836 rows=24 loops=1)
--          -> Nested loop inner join  (cost=6.57 rows=24) (actual time=0.041..0.0754 rows=24 loops=1)
--              -> Covering index scan on d using dept_name  (cost=1.9 rows=9) (actual time=0.023..0.0251 rows=9 loops=1)
--              -> Covering index lookup on dm using dept_no (dept_no=d.dept_no)  (cost=0.281 rows=2.67) (actual time=0.00392..0.00499 rows=2.67 loops=9)
--      -> Stream results  (cost=37666 rows=372536) (actual time=0.0455..258 rows=331603 loops=1)
--          -> Nested loop inner join  (cost=37666 rows=372536) (actual time=0.0447..186 rows=331603 loops=1)
--              -> Covering index scan on d using dept_name  (cost=1.9 rows=9) (actual time=0.0035..0.0209 rows=9 loops=1)
--              -> Covering index lookup on de using dept_no (dept_no=d.dept_no)  (cost=506 rows=41393) (actual time=0.0558..17.8 rows=36845 loops=9)




-- using temporary, using filesort 를 피하기 위한 인덱스 추가 전

-- 1	SIMPLE	dm		ALL	PRIMARY,dept_no				24	100.00	Using temporary; Using filesort
-- 1	SIMPLE	d		eq_ref	PRIMARY	PRIMARY	16	employees.dm.dept_no	1	100.00	Using index

-- -> Sort: dm.from_date DESC  (actual time=0.204..0.205 rows=24 loops=1)
--      -> Table scan on <temporary>  (cost=2.5..2.5 rows=0) (actual time=0.145..0.147 rows=24 loops=1)
--          -> Temporary table  (cost=0..0 rows=0) (actual time=0.145..0.145 rows=24 loops=1)
--              -> Window aggregate: rank() OVER (PARTITION BY dm.emp_no ORDER BY dm.from_date desc )   (actual time=0.126..0.136 rows=24 loops=1)
--                  -> Sort: dm.emp_no, dm.from_date DESC  (actual time=0.123..0.125 rows=24 loops=1)
--                      -> Table scan on <temporary>  (cost=13.6..16.2 rows=24) (actual time=0.106..0.108 rows=24 loops=1)
--                          -> Temporary table with deduplication  (cost=13.5..13.5 rows=24) (actual time=0.105..0.105 rows=24 loops=1)
--                              -> Nested loop inner join  (cost=11.1 rows=24) (actual time=0.0525..0.0851 rows=24 loops=1)
--                                  -> Table scan on dm  (cost=2.65 rows=24) (actual time=0.0371..0.0423 rows=24 loops=1)
--                                  -> Single-row covering index lookup on d using PRIMARY (dept_no=dm.dept_no)  (cost=0.254 rows=1) (actual time=0.00155..0.00157 rows=1 loops=24)
 
EXPLAIN 
SELECT  
		dm.emp_no AS emp_no
	,	dm.dept_no AS dept_no
    ,	RANK() OVER(PARTITION BY (dm.emp_no) ORDER BY from_date DESC) AS ranked
FROM departments d
INNER JOIN dept_manager dm ON dm.dept_no = d.dept_no
ORDER BY from_date DESC;




-- using temporary, using filesort 를 피하기 위한 인덱스 추가 후
CREATE INDEX idx_dm_empno_deptno_fromdate ON dept_manager(emp_no, dept_no, from_date DESC);
CREATE INDEX idx_de_empno_deptno_fromdate ON dept_emp(emp_no, dept_no, from_date DESC);

-- 1	PRIMARY	<derived2>		ref	<auto_key0>	<auto_key0>	8	const	2	100.00	
-- 2	DERIVED	dm		index	PRIMARY,dept_no,idx_dm_empno_deptno_fromdate	idx_dm_empno_deptno_fromdate	23		24	100.00	Using index; Using temporary; Using filesort
-- 2	DERIVED	d		eq_ref	PRIMARY	PRIMARY	16	employees.dm.dept_no	1	100.00	Using index

-- -> Index lookup on t1 using <auto_key0> (ranked=1)  (cost=0.35..0.84 rows=2.4) (actual time=0.147..0.152 rows=24 loops=1)
--      -> Materialize  (cost=0..0 rows=0) (actual time=0.145..0.145 rows=24 loops=1)
--          -> Sort: dm.from_date DESC  (actual time=0.127..0.128 rows=24 loops=1)
--              -> Table scan on <temporary>  (cost=2.5..2.5 rows=0) (actual time=0.116..0.117 rows=24 loops=1)
--                  -> Temporary table  (cost=0..0 rows=0) (actual time=0.115..0.115 rows=24 loops=1)
--                      -> Window aggregate: rank() OVER (PARTITION BY dm.emp_no ORDER BY dm.from_date desc )   (actual time=0.0994..0.109 rows=24 loops=1)
--                          -> Sort: dm.emp_no, dm.from_date DESC  (actual time=0.0958..0.0977 rows=24 loops=1)
--                              -> Stream results  (cost=11.1 rows=24) (actual time=0.0413..0.082 rows=24 loops=1)
--                                  -> Nested loop inner join  (cost=11.1 rows=24) (actual time=0.0377..0.0707 rows=24 loops=1)
--                                      -> Covering index scan on dm using idx_dm_empno_deptno_fromdate  (cost=2.65 rows=24) (actual time=0.0251..0.0306 rows=24 loops=1)
--                                      -> Single-row covering index lookup on d using PRIMARY (dept_no=dm.dept_no)  (cost=0.254 rows=1) (actual time=0.00144..0.00148 rows=1 loops=24)
 

EXPLAIN
SELECT
		t1.emp_no
	,	t1.dept_no
FROM(
	SELECT  
			dm.emp_no AS emp_no
		,	dm.dept_no AS dept_no
		,	RANK() OVER(PARTITION BY (dm.emp_no) ORDER BY from_date DESC) AS ranked
	FROM departments d
	INNER JOIN dept_manager dm ON dm.dept_no = d.dept_no
    UNION ALL
    SELECT  
			de.emp_no AS emp_no
		,	de.dept_no AS dept_no
		,	RANK() OVER(PARTITION BY (de.emp_no) ORDER BY from_date DESC) AS ranked
	FROM departments d
	INNER JOIN dept_emp de ON de.dept_no = d.dept_no
) t1
WHERE t1.ranked = 1;

-- 부서별 평균 급여를 계산하고, 가장 높은 부서를 출력하라.

SELECT
		dm.dept_no AS dept_no
	,	AVG(s.salary) AS avg_salary
FROM employees e
INNER JOIN dept_manager dm ON dm.emp_no = e.emp_no
INNER JOIN salaries s ON s.emp_no = dm.emp_no
GROUP BY dm.dept_no;


-- -> Table scan on <temporary>  (actual time=10832..10832 rows=9 loops=1)
--      -> Aggregate using temporary table  (actual time=10832..10832 rows=9 loops=1)
--          -> Nested loop inner join  (cost=634118 rows=3.19e+6) (actual time=0.79..8985 rows=3.14e+6 loops=1)
--              -> Nested loop inner join  (cost=138453 rows=332374) (actual time=0.779..1728 rows=331603 loops=1)
--                  -> Covering index scan on e using idx_employees_hire_date  (cost=30364 rows=299246) (actual time=0.753..223 rows=300024 loops=1)
--                  -> Covering index lookup on de using PRIMARY (emp_no=e.emp_no)  (cost=0.25 rows=1.11) (actual time=0.00405..0.00478 rows=1.11 loops=300024)
--              -> Index lookup on s using PRIMARY (emp_no=e.emp_no)  (cost=0.532 rows=9.59) (actual time=0.0183..0.0208 rows=9.48 loops=331603)
 
SHOW INDEX FROM employees;
-- employees	0	PRIMARY	1	emp_no	A	299246				BTREE			YES	
-- employees	1	idx_employees_hire_date	1	hire_date	A	5220				BTREE			YES	

SHOW INDEX FROM dept_emp;
-- dept_emp	0	PRIMARY	1	emp_no	A	298138				BTREE			YES	
-- dept_emp	0	PRIMARY	2	dept_no	A	331143				BTREE			YES	
-- dept_emp	1	dept_no	1	dept_no	A	8				BTREE			YES	
-- dept_emp	1	idx_de_empno_deptno_fromdate	1	emp_no	A	300308				BTREE			YES	
-- dept_emp	1	idx_de_empno_deptno_fromdate	2	dept_no	A	331143				BTREE			YES	
-- dept_emp	1	idx_de_empno_deptno_fromdate	3	from_date	D	331143				BTREE			YES	

SHOW INDEX FROM salaries;
-- salaries	0	PRIMARY	1	emp_no	A	280560				BTREE			YES	
-- salaries	0	PRIMARY	2	from_date	A	2690387				BTREE			YES	

EXPLAIN ANALYZE
SELECT
		de.dept_no AS dept_no
	,	AVG(s.salary) AS avg_salary
FROM employees e
INNER JOIN dept_emp de ON de.emp_no = e.emp_no
INNER JOIN salaries s ON s.emp_no = de.emp_no
GROUP BY de.dept_no;

-- 개선 1
EXPLAIN ANALYZE
SELECT
    de.dept_no,
    AVG(s.salary) AS avg_salary
FROM dept_emp de
JOIN (
    SELECT s1.emp_no, s1.salary
    FROM salaries s1
    INNER JOIN (
        SELECT emp_no, MAX(from_date) AS max_from_date
        FROM salaries
        GROUP BY emp_no
    ) s2 ON s1.emp_no = s2.emp_no AND s1.from_date = s2.max_from_date
) s ON s.emp_no = de.emp_no
GROUP BY de.dept_no;

-- 개선 2
EXPLAIN ANALYZE
WITH latest_salaries AS (
    SELECT emp_no, salary
    FROM (
        SELECT emp_no, salary,
               ROW_NUMBER() OVER(PARTITION BY emp_no ORDER BY from_date DESC) AS rn
        FROM salaries
    ) t
    WHERE rn = 1
)
SELECT de.dept_no, AVG(ls.salary) AS avg_salary
FROM dept_emp de
JOIN latest_salaries ls ON de.emp_no = ls.emp_no
GROUP BY de.dept_no;

-- 개선 3 
CREATE INDEX idx_salary_empno_fromdate_desc ON salaries (emp_no, from_date DESC);

EXPLAIN
SELECT 
		de.dept_no
	,   AVG(ls.salary) AS avg_salary
FROM dept_emp de
JOIN (
    SELECT emp_no, salary
    FROM (
        SELECT emp_no, salary,
               ROW_NUMBER() OVER(PARTITION BY emp_no ORDER BY from_date DESC) AS rn
        FROM salaries FORCE INDEX (idx_salary_empno_fromdate_desc)
    ) t
    WHERE rn = 1
) ls ON de.emp_no = ls.emp_no
GROUP BY de.dept_no;

EXPLAIN
SELECT  /*! STRAIGHT_JOIN */
		de.dept_no
	,   AVG(ls.salary) AS avg_salary
FROM (
    SELECT emp_no, salary
    FROM (
        SELECT emp_no, salary,
               ROW_NUMBER() OVER(PARTITION BY emp_no ORDER BY from_date DESC) AS rn
        FROM salaries FORCE INDEX (idx_salary_empno_fromdate_desc)
    ) t
    WHERE rn = 1
) ls
INNER JOIN dept_emp de ON de.emp_no = ls.emp_no
GROUP BY de.dept_no;

-- <derived3> :300024
SELECT 
	COUNT(1)
FROM (
	SELECT 
			emp_no
		,	salary
        ,	ROW_NUMBER() OVER(PARTITION BY emp_no ORDER BY from_date DESC) AS rn
	FROM salaries FORCE INDEX (idx_salary_empno_fromdate_desc)
) t
WHERE rn = 1;

-- de : 331603
SELECT
	COUNT(1)
FROM dept_emp;

-- salaries : 2844047
SELECT
	COUNT(1)
FROM salaries;

-- 개선 4

EXPLAIN ANALYZE
SELECT /*+ JOIN_ORDER(salaries dept_emp) */
       de.dept_no,
       AVG(s.salary) AS avg_salary
FROM (
    SELECT s.emp_no, s.salary
    FROM salaries s
    JOIN (
        SELECT emp_no, MAX(from_date) AS max_from_date
        FROM salaries
        GROUP BY emp_no
    ) latest
    ON s.emp_no = latest.emp_no AND s.from_date = latest.max_from_date
) s
JOIN dept_emp de ON s.emp_no = de.emp_no
GROUP BY de.dept_no;


-- 개선 5
SELECT 
    de.dept_no,
    AVG(s.salary) AS avg_salary
FROM dept_emp de
JOIN (
    SELECT s.emp_no, s.salary
    FROM salaries s
    JOIN (
        SELECT emp_no, MAX(from_date) AS max_from_date
        FROM salaries
        GROUP BY emp_no
    ) latest
    ON s.emp_no = latest.emp_no AND s.from_date = latest.max_from_date
) s ON de.emp_no = s.emp_no
GROUP BY de.dept_no
ORDER BY avg_salary DESC
LIMIT 1;

-- 개선 6 방식 변경

SELECT
		emp_no
	,	MAX(salary)
FROM salaries
GROUP BY emp_no;


SELECT /*! STRAIGHT_JOIN */
		e.emp_no
	,	e.first_name
    ,	e.last_name
    ,	s.salary
FROM (
	SELECT
			emp_no
		,	MAX(salary) AS salary
	FROM salaries
	GROUP BY emp_no
) s
INNER JOIN employees e ON s.emp_no = e.emp_no;


SELECT
		emp_no
	,	dept_no
    ,	from_date
    ,	to_date
FROM dept_manager
WHERE (emp_no, from_date) IN (
	SELECT
			emp_no
		,	MAX(from_date)
	FROM dept_manager
	GROUP BY emp_no
)
UNION ALL
SELECT
		emp_no
	,	dept_no
    ,	from_date
    ,	to_date
FROM dept_emp
WHERE (emp_no, from_date) IN (
	SELECT
			emp_no
		,	MAX(from_date)
	FROM dept_emp
	GROUP BY emp_no
);


-- -> Limit: 1 row(s)  (actual time=13546..13546 rows=1 loops=1)
--      -> Sort: avg_salary DESC, limit input to 1 row(s) per chunk  (actual time=13546..13546 rows=1 loops=1)
--          -> Table scan on <temporary>  (actual time=13546..13546 rows=9 loops=1)
--              -> Aggregate using temporary table  (actual time=13546..13546 rows=9 loops=1)
--                  -> Nested loop inner join  (cost=83.6e+9 rows=836e+9) (actual time=10643..13150 rows=300077 loops=1)
--                      -> Nested loop inner join  (cost=372565 rows=2.98e+6) (actual time=5922..6875 rows=300077 loops=1)
--                          -> Covering index scan on de using dept_name  (cost=1.9 rows=9) (actual time=0.0311..0.071 rows=9 loops=1)
--                          -> Index lookup on d using <auto_key2> (dept_no=de.dept_no)  (cost=66973..75294 rows=3974) (actual time=658..761 rows=33342 loops=9)
--                              -> Union all materialize  (cost=66971..66971 rows=331167) (actual time=5921..5921 rows=300077 loops=1)
--                                  -> Filter: <in_optimizer>((dept_manager.emp_no,dept_manager.from_date),(dept_manager.emp_no,dept_manager.from_date) in (select #3))  (cost=3.4 rows=24) (actual time=10.4..10.4 rows=24 loops=1)
--                                      -> Covering index scan on dept_manager using idx_dm_empno_deptno_fromdate  (cost=3.4 rows=24) (actual time=10.3..10.3 rows=24 loops=1)
--                                      -> Select #3 (subquery in condition; run only once)
--                                          -> Filter: ((dept_manager.emp_no = `<materialized_subquery>`.emp_no) and (dept_manager.from_date = `<materialized_subquery>`.`MAX(from_date)`))  (cost=8.3..8.3 rows=1) (actual time=0.00412..0.00412 rows=0.96 loops=25)
--                                              -> Limit: 1 row(s)  (cost=8.2..8.2 rows=1) (actual time=0.00372..0.00372 rows=0.96 loops=25)
--                                                  -> Index lookup on <materialized_subquery> using <auto_distinct_key> (emp_no=dept_manager.emp_no, MAX(from_date)=dept_manager.from_date)  (actual time=0.0035..0.0035 rows=0.96 loops=25)
--                                                      -> Materialize with deduplication  (cost=8.2..8.2 rows=24) (actual time=0.069..0.069 rows=24 loops=1)
--                                                          -> Group aggregate: max(dept_manager.from_date)  (cost=5.8 rows=24) (actual time=0.026..0.0379 rows=24 loops=1)
--                                                              -> Covering index scan on dept_manager using idx_dm_empno_deptno_fromdate  (cost=3.4 rows=24) (actual time=0.0188..0.0252 rows=24 loops=1)
--                                  -> Filter: <in_optimizer>((dept_emp.emp_no,dept_emp.from_date),(dept_emp.emp_no,dept_emp.from_date) in (select #5))  (cost=33851 rows=331143) (actual time=1186..3137 rows=300053 loops=1)
--                                      -> Covering index scan on dept_emp using idx_de_empno_deptno_fromdate  (cost=33851 rows=331143) (actual time=0.383..193 rows=331603 loops=1)
--                                      -> Select #5 (subquery in condition; run only once)
--                                          -> Filter: ((dept_emp.emp_no = `<materialized_subquery>`.emp_no) and (dept_emp.from_date = `<materialized_subquery>`.`MAX(from_date)`))  (cost=96779..96779 rows=1) (actual time=0.00781..0.00781 rows=0.905 loops=331575)
--                                              -> Limit: 1 row(s)  (cost=96779..96779 rows=1) (actual time=0.00742..0.00742 rows=0.905 loops=331575)
--                                                  -> Index lookup on <materialized_subquery> using <auto_distinct_key> (emp_no=dept_emp.emp_no, MAX(from_date)=dept_emp.from_date)  (actual time=0.00721..0.00721 rows=0.905 loops=331575)
--                                                      -> Materialize with deduplication  (cost=96779..96779 rows=298138) (actual time=1185..1185 rows=300024 loops=1)
--                                                          -> Group aggregate: max(dept_emp.from_date)  (cost=66965 rows=298138) (actual time=0.0344..238 rows=300024 loops=1)
--                                                              -> Covering index scan on dept_emp using idx_de_empno_deptno_fromdate  (cost=33851 rows=331143) (actual time=0.0303..127 rows=331603 loops=1)
--                      -> Index lookup on s using <auto_key0> (emp_no=d.emp_no)  (cost=569511..569514 rows=10) (actual time=0.0202..0.0206 rows=1 loops=300077)
--                          -> Materialize  (cost=569511..569511 rows=280560) (actual time=4722..4722 rows=300024 loops=1)
--                              -> Group aggregate: max(salaries.salary)  (cost=541455 rows=280560) (actual time=0.0423..3375 rows=300024 loops=1)
--                                  -> Index scan on salaries using PRIMARY  (cost=272416 rows=2.69e+6) (actual time=0.0337..2919 rows=2.84e+6 loops=1)
 
EXPLAIN ANALYZE
SELECT
		d.dept_no
	,	de.dept_name
    ,	AVG(s.salary) AS avg_salary
FROM (
    SELECT emp_no, dept_no
    FROM dept_manager
    WHERE (emp_no, from_date) IN (
        SELECT emp_no, MAX(from_date)
        FROM dept_manager
        GROUP BY emp_no
    )
    UNION ALL
    SELECT emp_no, dept_no
    FROM dept_emp
    WHERE (emp_no, from_date) IN (
        SELECT emp_no, MAX(from_date)
        FROM dept_emp
        GROUP BY emp_no
    )
) d
INNER JOIN (
    SELECT emp_no, MAX(salary) AS salary
    FROM salaries
    GROUP BY emp_no
) s ON d.emp_no = s.emp_no
INNER JOIN departments de ON de.dept_no = d.dept_no
GROUP BY d.dept_no
ORDER BY avg_salary DESC
LIMIT 1;


-- -> Limit: 1 row(s)  (actual time=10330..10330 rows=1 loops=1)
--      -> Sort: avg_salary DESC, limit input to 1 row(s) per chunk  (actual time=10330..10330 rows=1 loops=1)
--          -> Table scan on <temporary>  (actual time=10330..10330 rows=9 loops=1)
--              -> Aggregate using temporary table  (actual time=10330..10330 rows=9 loops=1)
--                  -> Nested loop inner join  (cost=8.51e+9 rows=85.1e+9) (actual time=7763..9976 rows=300077 loops=1)
--                      -> Nested loop inner join  (cost=38611 rows=303213) (actual time=3919..4726 rows=300077 loops=1)
--                          -> Covering index scan on d using dept_name  (cost=1.9 rows=9) (actual time=0.0257..0.0676 rows=9 loops=1)
--                          -> Index lookup on ld using <auto_key2> (dept_no=d.dept_no)  (cost=379000..379924 rows=442) (actual time=436..522 rows=33342 loops=9)
--                              -> Materialize union CTE latest_dept  (cost=378998..378998 rows=33690) (actual time=3919..3919 rows=300077 loops=1)
--                                  -> Nested loop inner join  (cost=75.4 rows=576) (actual time=0.796..0.825 rows=24 loops=1)
--                                      -> Covering index scan on dm using idx_dm_empno_deptno_fromdate  (cost=3.4 rows=24) (actual time=0.694..0.698 rows=24 loops=1)
--                                      -> Covering index lookup on latest_dm using <auto_key0> (emp_no=dm.emp_no, max_from_date=dm.from_date)  (cost=8.45..8.81 rows=2.4) (actual time=0.00472..0.00493 rows=1 loops=24)
--                                          -> Materialize  (cost=8.2..8.2 rows=24) (actual time=0.0957..0.0957 rows=24 loops=1)
--                                              -> Group aggregate: max(dept_manager.from_date)  (cost=5.8 rows=24) (actual time=0.0498..0.0608 rows=24 loops=1)
--                                                  -> Covering index scan on dept_manager using idx_dm_empno_deptno_fromdate  (cost=3.4 rows=24) (actual time=0.0136..0.0201 rows=24 loops=1)
--                                  -> Nested loop inner join  (cost=375553 rows=33114) (actual time=449..1949 rows=300053 loops=1)
--                                      -> Table scan on latest_de  (cost=96581..100311 rows=298138) (actual time=449..505 rows=300024 loops=1)
--                                          -> Materialize  (cost=96581..96581 rows=298138) (actual time=449..449 rows=300024 loops=1)
--                                              -> Group aggregate: max(dept_emp.from_date)  (cost=66767 rows=298138) (actual time=0.659..335 rows=300024 loops=1)
--                                                  -> Covering index scan on dept_emp using idx_de_empno_deptno_fromdate  (cost=33653 rows=331143) (actual time=0.652..256 rows=331603 loops=1)
--                                      -> Filter: (de.from_date = latest_de.max_from_date)  (cost=0.731 rows=0.111) (actual time=0.00367..0.00449 rows=1 loops=300024)
--                                          -> Index lookup on de using PRIMARY (emp_no=latest_de.emp_no)  (cost=0.731 rows=1.11) (actual time=0.00344..0.00418 rows=1.11 loops=300024)
--                      -> Index lookup on ms using <auto_key0> (emp_no=ld.emp_no)  (cost=569246..569264 rows=73) (actual time=0.0168..0.0172 rows=1 loops=300077)
--                          -> Materialize CTE max_salary  (cost=569245..569245 rows=280560) (actual time=3844..3844 rows=300024 loops=1)
--                              -> Group aggregate: max(salaries.salary)  (cost=541189 rows=280560) (actual time=0.0403..2732 rows=300024 loops=1)
--                                  -> Index scan on salaries using PRIMARY  (cost=272151 rows=2.69e+6) (actual time=0.0303..2378 rows=2.84e+6 loops=1)
 

EXPLAIN ANALYZE
WITH latest_dept AS (
    SELECT dm.emp_no, dm.dept_no
    FROM dept_manager dm
    JOIN (
        SELECT emp_no, MAX(from_date) AS max_from_date
        FROM dept_manager
        GROUP BY emp_no
    ) latest_dm ON dm.emp_no = latest_dm.emp_no AND dm.from_date = latest_dm.max_from_date

    UNION ALL

    SELECT de.emp_no, de.dept_no
    FROM dept_emp de
    JOIN (
        SELECT emp_no, MAX(from_date) AS max_from_date
        FROM dept_emp
        GROUP BY emp_no
    ) latest_de ON de.emp_no = latest_de.emp_no AND de.from_date = latest_de.max_from_date
),
max_salary AS (
    SELECT emp_no, MAX(salary) AS salary
    FROM salaries
    GROUP BY emp_no
)
SELECT
    ld.dept_no,
    d.dept_name,
    AVG(ms.salary) AS avg_salary
FROM latest_dept ld
JOIN max_salary ms ON ld.emp_no = ms.emp_no
JOIN departments d ON d.dept_no = ld.dept_no
GROUP BY ld.dept_no
ORDER BY avg_salary DESC
LIMIT 1;








