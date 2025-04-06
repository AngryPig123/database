-- sql -> parsor (context) -> optimizer (최적화) -> innoDB (storege engine) ->
-- optimizer 동작 방식 알아보기, TREE 알아보기
-- sql -> parsor(sql을 최소 단위로 분리, 구성 요소를 TREE로 작성) -> preprocessor (TREE의 구성 요소로 권한 / 존재 여부 확인) ->
-- optimizer -> engine executor -> store engine -> engine executor -> response

-- DB object
-- pk, fk, index, unique index, non-unique index, view

-- 스칼라 서브 쿼리, 인라인 뷰, 중첩 서브쿼리

-- 비상관 서브 쿼리, 상관 서브 쿼리

-- 단일행 서브쿼리, 다중행 서브쿼리, 다중열 서브쿼리

-- 크로스 조인, 자연 조인

-- 드라이빙, 드리븐 테이블 테이블에 접근하는 선후 관계

-- 테이블을 동시에 접근할 수 없기 때문에 범위를 줄일 수 있는 테이블을 선정하여 먼저 접근한다 ( where 절 )

-- 먼저 접근하는 테이블 -> 드라이빙 테이블

-- 후 순위로 접근하는 테이블 -> 드리븐 테이블

-- where, join on 절에 오는 컬럼 값은 인덱스로하는게 유리하다

-- 테이블에 접근하는 횟수를 줄이는게 유리함.

-- 접근 횟수를 줄이고, 인덱스를 통해서 조인을 한다.

-- 인덱스가 있는 테이블을 드리븐 테이블로 선택

-- 스토리지에 접근하는 방식 : 임의 접근, 순차 접근

-- 조인 알고리즘 : Nested Loop Join, Hash Join

-- Nested Loop Join : 좁은 범위

---------------
-- index 사용 --
---------------

EXPLAIN
SELECT 
        emp.EMP_ID
    ,   emp.FIRST_NAME 
    ,   emp.LAST_NAME 
    ,   grade.GRADE_NAME 
FROM grade, emp
WHERE emp.LAST_NAME = 'Suri'
AND grade.EMP_ID = emp.EMP_ID ;

EXPLAIN
SELECT 
        emp.EMP_ID
    ,   emp.FIRST_NAME 
    ,   emp.LAST_NAME 
    ,   grade.GRADE_NAME 
FROM grade, emp;

-- no index
EXPLAIN
SELECT 
        EMP_ID 
    ,   LAST_NAME 
    ,   FIRST_NAME 
FROM emp
WHERE gender IS NOT NULL;

-- index range
EXPLAIN
SELECT
        EMP_ID
    ,   LAST_NAME
    ,   FIRST_NAME
FROM emp
WHERE EMP_ID BETWEEN 20000 AND 30000;

-- index full
EXPLAIN
SELECT
		LAST_NAME 
FROM emp
WHERE gender <> 'F';

-- index unique
EXPLAIN
SELECT
	*
FROM emp
WHERE EMP_ID = 20000;

--  index loose ,인덱스 range scan 또는 index full scan 이 일어나고, 테이블 row에는 접근하지 않음 즉, 인덱스를 효율적으로 잘 활용한 경우!
EXPLAIN
SELECT 
		GENDER
	,	COUNT(DISTINCT LAST_NAME) AS cnt
FROM emp
WHERE GENDER = 'F'
GROUP BY GENDER;
    
-- index skip
EXPLAIN
SELECT
		MAX(EMP_ID) AS max_emp_id
FROM emp
WHERE LAST_NAME = 'Peha';

-- index merge
EXPLAIN
SELECT
		EMP_ID
	,	LAST_NAME
    ,	FIRST_NAME
FROM emp
WHERE (HIRE_DATE BETWEEN '1989-01-01' AND '1989-06-30')
OR EMP_ID > 600000;

---------------
-- where 사용 --
---------------
-- 액세스 조건, 필터 조건
-- key 로 사용된 녀석이 엑세스 조건, 나머지 녀석이 필터 조건
-- 옵티마이저가 선택한 인덱스가 아닌 녀석들인 필터 조건으로 사용된다.
EXPLAIN
SELECT
		EMP_ID
	,	GENDER
    ,	FIRST_NAME
    ,	LAST_NAME
    ,	HIRE_DATE
FROM emp
WHERE EMP_ID BETWEEN 50000 AND 60000
AND GENDER = 'F'
AND LAST_NAME IN ('Kroft','Colorni')
AND HIRE_DATE >= '1990-01-01';

---------------
--  정량적지표  --
---------------
-- 선택도 = (선택한 레코드 건수 / 전체 레코드 건수) * 100
-- 결합 인덱스를 추가할때 선두로 오는 컬럼이 where 절에서의 엑세스 조건이 됨으로 선택도가 낮은 녀석을 앞에 둔다. => 더 알아보자.

-- 카디널리티 = 1 / 선택도


---------------
--  응용 용어  --
---------------
-- 힌트
-- STRAIGHT_JOIN : FROM 절에 나열된 테이블 순으로 조인을 유도하는 힌트
-- USE INDEX : 특정 인덱스를 사용하도록 유도하는 힌트
-- FORCE INDEX : 특정 인덱스를 사용하도록 강하게 유도하는 힌트
-- IGNORE INDEX : 특정 인덱스를 사용하지 못하도록 유도하는 힌트

-- /*! STRAIGHT_JOIN */, USE INDEX (PRIMAY), FORCE INDEX (PRIMARY), IGNORE INDEX (PRIMARY)
EXPLAIN
SELECT /* STRAIGHT_JOIN */
		e.FIRST_NAME
	,	e.LAST_NAME
FROM emp e
INNER JOIN manager m  /* USE INDEX (PRIMARY) */ /* FORCE INDEX (PRIMARY) */ /* IGNORE INDEX (I_DEPT_ID) */ ON m.EMP_ID = e.EMP_ID;

-- 콜레이션 : 데이터베이스에 저장된 문자값을 비교하거나 정렬하는 규칙


-- 통계정보 : 데이터베이스 오브젝트(테이블, 인덱스 등)에 대한 특징을 수집한 정보
SELECT * FROM mysql.innodb_table_stats
WHERE database_name = 'tuning';


---------------
--  실행 계획  --
---------------

-- 1 ] id, select_type, table

-- id : 최소한의 단위  select 문 마다 부여되는 식별자

-- table : id에 포함된 테이블명, 인라인 뷰의 경우 테이블 명이 다르게 나올 수 있음

-- select_type 항목
-- simple : 서브쿼리 또는 union 구문이 없는 단순한 select문
-- primary : 서브쿼리 또는 union 구문이 포함된 쿼리문에서 최초 접근한 테이블을 primary로 표현한다 PK랑 다름 
-- subquery : 독립적인 서브쿼리 (비상관 관계)
-- derieved : 단일 쿼리의 메모리나 디스크에 생성한 임시 테이블.(인라인뷰)
-- union : union 또는 union all 구문에서 첫 번째 이후의 테이블
-- union result : union 구문에서 중복을 제거 하기 위해 메모리나 디스크에 생성한 임시 테이블
-- dependent subquery, dependent union : Union 또는 Union all 구문에서 메인 테이블의 영향을 받는 테이블
-- materialized : 조인 등의 가공 작업을 위해서 생성한 임시 테이블

EXPLAIN
SELECT e.emp_id, e.first_name, e.last_name, s.annual_salary,
	(SELECT g.grade_name FROM grade g
	 WHERE g.emp_id = e.emp_id
     AND g.end_date = '9999-01-01') grade_name
FROM emp e, salary s
WHERE e.emp_id = 10001
AND e.emp_id = s.emp_id
AND s.is_yn = 1;

-- 2 ] partitions, type
-- partitions 항목

-- type 
-- const : 단 1건의 데이터만 접근하는 유형
-- eq_ref : 조인 시 드리븐 테이블에서 매번 단 1건의 데이터만 접근하는 유형
-- ref : 데이터 접근 범위가 2개 이상인 유형
-- range : 연속되는 범위를 접근하게 되는 유형
-- index_merge : 특정 테이블에 생성된 2개 이상 인덱스가 병합되어 동시에 적용되는 유형
-- index : 인텍스를 처음부터 끝까지 접근하는 유형
-- all : 테이블을 처음부터 끝까지 접근하는 유형

-- 3 ] possible_keys, key, key_len, ref, row, filtered, extra
-- possible_keys : 사용할 수 잇는 인덱스 후보군 -> 호용성 없음
-- key : 사용한 인덱스명
-- key_len : 사용된 인덱스의 bytes
-- ref : 테이블을 접근한 조건
-- rows : 접글할 레코드 행 수(예상 수치)
-- filtered : 필터 조건에 의해 최종 반환되는 비율, 높을 수록 좋다.

-- extra : 쿼리문을 어떻게 수행할 것인지에 대한 부가 정보
-- discint : 중복이 제거되어 유일한 값을 찾을 때 출력되는 정보(distinct, union)
-- using where : where 절의 필터 조건을 사용해 엔진으로 가져온 데이터를 추출
-- using temporary : 데이터의 중간 결과를 저장하고자 임시 테이블을 생성
-- using index : 물리적인 데이터 파일을 읽지 않고 인덱스만 읽어 쿼리 수행 (Convering index)
-- using filesort : order by  가 인덱스 활용하지 못하고, 메모리에 올려서 추가적인 정렬 작업 수행
-- using index for group-by : 쿼리문에 group by 구문이나 distinct 구문이 포함될 때, 정렬된 인덱스를 순서대로 읽으면서 group by 연산 수행
-- using index for skip scan : 인덱스의 모든 값을 비교하는게 아닌, 필요한 값만 건너뛰면서 스캔하는 방식
-- FirstMatch() : 이넥스 스캔시에 첫 번째로 일치하는 레코드만 찾으면 검색을 중단하는 방식.

EXPLAIN
SELECT
		EMP_ID
	,	FIRST_NAME
FROM emp
WHERE EMP_ID BETWEEN 10001 AND 10100;



---------------
--  판단 기준  --
---------------

-- 1 ] select_type 항목 
-- SIMPLE, PRIMARY <-> DEPENDENT * UNCACHEABLE *

-- 2 ] type 항목
-- system, const, eq_ref <-> index, all

-- 3 ] extra 항목
-- using index <-> using filesort, using temporary


-- 싱행 계획의 확장
-- explain format=traditional
-- explain format=tree
-- explain format=json
-- explain analyze

EXPLAIN
SELECT
		EMP_ID
	,	FIRST_NAME
FROM emp
WHERE EMP_ID BETWEEN 10001 AND 10100;


---------------
--  프로 파일  --
---------------

-- explain
-- 쿼리 실행 계획, 인덱스 사용여부
-- 실행 계획 검토 및 인덱스 최적화
-- 상대적으로 간략 및 활용 용이


-- profiling
-- 상세 실행 이벤트 및 시간 측정
-- 병목 현상 확인
-- 상세

-- 확인

-- 확인
SHOW VARIABLES LIKE 'profiling';

-- 접속 세션에서 변수 변경
SET profiling = 'ON';

-- 쿼리 수행
SELECT
		EMP_ID
	,	FIRST_NAME
FROM emp
WHERE EMP_ID BETWEEN 10001 AND 10100;

-- 전체 확인
SHOW PROFILES;

-- 결과 확인
SHOW PROFILE FOR QUERY 6;

-- 상세 확인
SHOW PROFILE ALL FOR query 6;



































