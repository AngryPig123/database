-- 이력성 테이블에 인덱스를 수정해야 하는 경우에는 새벽 시간대에 인덱스를 삭제 후 update 이후 인덱스를 생성하는 방식으로 문제를 해결한다. 

-- 1	UPDATE	entry_record		index	I_GATE	PRIMARY	8		658935	100.00	Using where
-- -> <not executable by iterator executor>

EXPLAIN
UPDATE entry_record
SET gate = 'X'
WHERE gate = 'B';
