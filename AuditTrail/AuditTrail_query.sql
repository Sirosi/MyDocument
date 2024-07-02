-- ******************************************************************
-- AuditTrail Update
-- ******************************************************************


DECLARE
	-- Parameters
	@p_code		BIGINT			= '1',		-- at_code, ������ �����ڵ�
	@p_table	VARCHAR(128)	= 'emp',	-- AuditTrail�� ���ܾ� �ϴ� Table��
	@p_emp		VARCHAR(20)		= NULL,		-- AuditTrail�� �߻���Ų, �߻��� ID
	@p_type		CHAR(1)			= 'U',		-- AuditTrail ����, I: Insert/U: Update/D: Delete
	@p_comment	VARCHAR(1000)	= NULL		-- AuditTrail �߻� ���� �� �ڸ�Ʈ

DECLARE
	-- Query ���� �ð�
	@v_now		CHAR(23)		= CONVERT(CHAR(23), GETDATE(), 21),
	@v_ident	BIGINT			= IDENT_CURRENT('audit_trail')




BEGIN TRAN -- Transaction ������
BEGIN TRY
	-- ******************************************************************
	-- audit_trail ���� �κ�
	-- 
	-- AuditTrail, �̷��� ������ ���� Table�� ���� �����Ѵ�.
	-- ******************************************************************
	INSERT INTO
		audit_trail(at_code, at_table, at_emp, at_dt, at_type, at_comment)
	VALUES
		(@p_code, @p_table, @p_emp, @v_now, @p_type, @p_comment)

	DECLARE
		@v_at_id	BIGINT	= IDENT_CURRENT('audit_trail')





	-- ******************************************************************
	-- audit_trail_data ���� �κ�
	--
	-- AuditTrail Type�� U���,
	-- audit_trail_data�� ���� �������� �Էµ� �����Ϳ� ���ؼ�, ���� ����� AuditTrail �����͵鸸 �����Ѵ�.
	-- AuditTrail Type�� I(Insert)��, D(Delete)���,
	-- ��� �÷��� �����͵��� �����Ѵ�.
	-- ******************************************************************
	DECLARE @sql_text VARCHAR(MAX) =
	'
		INSERT INTO
			audit_trail_data(atd_id, atd_column, atd_value) 
	'

	SELECT
		@sql_text = CONCAT(@sql_text,
		'SELECT ',
		'	''', @v_at_id, ''', ',		-- audit_trail���� ������ Identity ��
		'	''', COLUMN_NAME, ''', ',	-- Table�� ��������� �����ϴ� Column��
		'	ISNULL(CAST(vt.', COLUMN_NAME, ' AS VARCHAR), ''[NULL]'') ', -- ���� Column�� ��
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
	DBCC CHECKIDENT ('audit_trail', RESEED, @v_ident); -- Identity�� Transaction�� ������ �����̱� ������ ������ ����



    PRINT 'Error occurred at line ' + CAST(ERROR_LINE() AS VARCHAR(10));
    PRINT 'Error message: ' + ERROR_MESSAGE();
    PRINT 'Error number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
    PRINT 'Error procedure: ' + ISNULL(ERROR_PROCEDURE(), 'Unknown');
    PRINT 'Error severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
    PRINT 'Error state: ' + CAST(ERROR_STATE() AS VARCHAR(10));
END CATCH





-- ******************************************************************
-- audit_trail_data�� �����ϴ��� Ȯ��, ������ AuditTrail ����
--
-- audit_trail���� �����ִ�, �������� ���� AuditTrail���� ���� ����� �ʿ䰡 ���⿡
-- ����ó�� �� Identity�� �����Ѵ�.
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
	PRINT 'Update����, audit_trail �̷� ������ �������� �ʽ��ϴ�.'
	DECLARE @v_max_id BIGINT = 0
	SELECT TOP 1 @v_max_id = at_id FROM audit_trail ORDER BY at_id DESC
	DBCC CHECKIDENT ('audit_trail', RESEED, @v_max_id);
END