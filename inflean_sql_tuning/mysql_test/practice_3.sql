-- 직책별 평균 급여를 내림차순으로 정렬하라.

SHOW INDEX FROM titles;
-- PRIMARY	1	emp_no
-- PRIMARY	2	title
-- PRIMARY	3	from_date

SHOW INDEX FROM salaries;
CREATE INDEX idx_salary_empno_fromdate_todate_desc ON salaries (emp_no, from_date, to_date);

EXPLAIN
SELECT
		emp_no
FROM salaries
WHERE to_date = '9999-01-01';
