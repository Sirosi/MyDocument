-- ******************************************************************
-- AuditTrail Update
-- ******************************************************************


DECLARE
	-- Parameters
	@p_code		BIGINT			= '1',		-- at_code, 추적용 고유코드
	@p_table	VARCHAR(128)	= 'emp',	-- AuditTrail을 남겨야 하는 Table명
	@p_emp		VARCHAR(20)		= NULL,		-- AuditTrail을 발생시킨, 발생자 ID
	@p_type		CHAR(1)			= 'U',		-- AuditTrail 유형, I: Insert/U: Update/D: Delete
	@p_comment	VARCHAR(1000)	= NULL		-- AuditTrail 발생 이유 및 코멘트

DECLARE
	-- Query 시작 시각
	@v_now		CHAR(23)		= CONVERT(CHAR(23), GETDATE(), 21),
	@v_ident	BIGINT			= IDENT_CURRENT('audit_trail')




BEGIN TRAN -- Transaction 시작점
BEGIN TRY
	-- ******************************************************************
	-- audit_trail 생성 부분
	-- 
	-- AuditTrail, 이력의 정보가 들어가는 Table에 행을 생성한다.
	-- ******************************************************************
	INSERT INTO
		audit_trail(at_code, at_table, at_emp, at_dt, at_type, at_comment)
	VALUES
		(@p_code, @p_table, @p_emp, @v_now, @p_type, @p_comment)

	DECLARE
		@v_at_id	BIGINT	= IDENT_CURRENT('audit_trail')





	-- ******************************************************************
	-- audit_trail_data 생성 부분
	--
	-- AuditTrail Type이 U라면,
	-- audit_trail_data중 가장 마지막에 입력된 데이터와 비교해서, 값이 변경된 AuditTrail 데이터들만 생성한다.
	-- AuditTrail Type이 I(Insert)나, D(Delete)라면,
	-- 모든 컬럼의 데이터들을 생성한다.
	-- ******************************************************************
	DECLARE @sql_text VARCHAR(MAX) =
	'
		INSERT INTO
			audit_trail_data(atd_id, atd_column, atd_value) 
	'

	SELECT
		@sql_text = CONCAT(@sql_text,
		'SELECT ',
		'	''', @v_at_id, ''', ',		-- audit_trail에서 생성된 Identity 값
		'	''', COLUMN_NAME, ''', ',	-- Table의 변경사항이 존재하는 Column명
		'	ISNULL(CAST(vt.', COLUMN_NAME, ' AS VARCHAR), ''[NULL]'') ', -- 실제 Column의 값
		'FROM ',
		'	', @p_table, ' AS vt ',
		'WHERE ',
		'	vt.at_code = ''', @p_code, ''' ',
		'AND ',
		'( ',
		'	''', @p_type, ''' IN (''I'', ''D'') ',
		'OR ',
		'	''', ISNULL((
			SELECT TOP 1
				atd_value
			FROM
				audit_trail_data AS atd
			INNER JOIN
			(
				SELECT TOP 1
					at_id
				FROM
					audit_trail
				INNER JOIN
					audit_trail_data
				ON
					at_id = atd_id
				AND
					at_table = @p_table
				AND
					atd_column = COLUMN_NAME
				ORDER BY at_dt DESC
			) AS at
			ON
				at.at_id = atd.atd_id
			AND
				atd_column = COLUMN_NAME), '[UNKNOWN]'
			), ''' != ISNULL(CAST(vt.', COLUMN_NAME, ' AS VARCHAR), ''[NULL]'') ',
		') ',
		'UNION ALL ')
	FROM
		INFORMATION_SCHEMA.COLUMNS
	WHERE
		TABLE_NAME = @p_table
	AND
		COLUMN_NAME != 'at_code'

	SET @sql_text = SUBSTRING(@sql_text, 0, LEN(@sql_text) - LEN('UNION ALL '))

	EXEC (@sql_text)





	COMMIT TRAN -- Transaction Commit
END TRY
BEGIN CATCH
	ROLLBACK TRAN -- Transaction Rollback
	DBCC CHECKIDENT ('audit_trail', RESEED, @v_ident); -- Identity는 Transaction과 별도로 움직이기 때문에 별도로 변경



    PRINT 'Error occurred at line ' + CAST(ERROR_LINE() AS VARCHAR(10));
    PRINT 'Error message: ' + ERROR_MESSAGE();
    PRINT 'Error number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
    PRINT 'Error procedure: ' + ISNULL(ERROR_PROCEDURE(), 'Unknown');
    PRINT 'Error severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
    PRINT 'Error state: ' + CAST(ERROR_STATE() AS VARCHAR(10));
END CATCH





-- ******************************************************************
-- audit_trail_data가 존재하는지 확인, 없으면 AuditTrail 삭제
--
-- audit_trail만을 갖고있는, 변경점이 없는 AuditTrail들은 굳이 기록할 필요가 없기에
-- 삭제처리 및 Identity도 갱신한다.
-- ******************************************************************
DELETE
	audit_trail
WHERE
	NOT EXISTS
	(
		SELECT
			atd_id
		FROM
			audit_trail_data
		WHERE
			atd_id = at_id
	)

IF @@ROWCOUNT > 0
BEGIN
	PRINT 'Update지만, audit_trail 이력 수정이 존재하지 않습니다.'
	DECLARE @v_max_id BIGINT = 0
	SELECT TOP 1 @v_max_id = at_id FROM audit_trail ORDER BY at_id DESC
	DBCC CHECKIDENT ('audit_trail', RESEED, @v_max_id);
END