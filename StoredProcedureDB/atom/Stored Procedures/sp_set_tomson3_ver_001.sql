-- =============================================
CREATE PROCEDURE [atom].[sp_set_tomson3_ver_001] 
	-- Add the parameters for the stored procedure here
	@status INT = 0, ----#0:insert, 1:update, 2:delete
	@lot_id VARCHAR(MAX), 
	@tomson3_after CHAR(4) = '   ', 
	@user_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (@user_id != 1339)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
			, (CASE WHEN @status = 0 THEN 'Insert'
				WHEN @status = 1 THEN 'Update'
				WHEN @status = 2 THEN 'Delete'
				ELSE ''
			END) + ' data error !!' AS [Error_Message_ENG]
			, (CASE WHEN @status = 0 THEN N'เพิ่ม'
				WHEN @status = 1 THEN N'แก้ไข'
				WHEN @status = 2 THEN N'ลบ'
				ELSE ''
			END) + N'ข้อมูลผิดพลาด !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END

	DECLARE @table_lot TABLE (
		[lot_id] [INT],
		[lot_no] [VARCHAR](10),
		[tomson3_before] [CHAR](4),
		[tomson3_after] [CHAR](4),
		[surplus] [INT],
		[label] [INT],
		[qc_info] [INT]
	)

	DECLARE @lot_id_sort VARCHAR(MAX)
		, @status_return INT = 0

	INSERT INTO @table_lot
	SELECT [lots].[id] AS [lot_id]
		, [lots].[lot_no]
		, ISNULL( [allocat].[Tomson3], ISNULL( [allocat_temp].[Tomson3], [surpluses].[qc_instruction] ) ) AS [tomson3_before]
		, @tomson3_after AS [tomson3_after]
		, ISNULL( [surpluses].[count], 0 ) AS [surplus]
		, ISNULL( [label_issue_records].[count], 0 ) AS [label]
		, ISNULL( [lot_qc_info].[count], 0 ) AS [qc_info]
	FROM (
		SELECT TRIM( value ) AS [lot_id]
		FROM STRING_SPLIT( @lot_id, ',' )
		WHERE value != ''
	) AS [table_lot]
	INNER JOIN [APCSProDB].[trans].[lots] ON [table_lot].[lot_id] = [lots].[id]
	LEFT JOIN [APCSProDB].[method].[allocat] ON [lots].[lot_no] = [allocat].[LotNo]
	LEFT JOIN [APCSProDB].[method].[allocat_temp] ON [lots].[lot_no] = [allocat_temp].[LotNo]
	OUTER APPLY (
		SELECT TOP 1 1 AS [count] FROM [APCSProDWH].[tg].[lot_qc_info] WHERE [lot_qc_info].[lot_id] = [lots].[id] 
	) AS [lot_qc_info]
	OUTER APPLY (
		SELECT TOP 1 1 AS [count], [surpluses].[qc_instruction] FROM [APCSProDB].[trans].[surpluses] WHERE [surpluses].[lot_id] = [lots].[id] 
	) AS [surpluses]
	OUTER APPLY (
		SELECT TOP 1 1 AS [count] FROM [APCSProDB].[trans].[label_issue_records] WHERE [label_issue_records].[lot_no] = [lots].[lot_no]
	) AS [label_issue_records];

	IF ( @status = 0 ) --# 0:Insert
	BEGIN
		----# insert table lot_qc_info
		INSERT INTO [APCSProDWH].[tg].[lot_qc_info]
			( [lot_id]
			, [tomson3_before]
			, [tomson3_after]
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by] )
		SELECT [lot_id]
			, [tomson3_before]
			, [tomson3_after]
			, GETDATE() AS [created_at]
			, @user_id AS [created_by]
			, GETDATE() AS [updated_at]
			, @user_id AS [updated_by] 
		FROM @table_lot
		WHERE [qc_info] = 0;

		IF (@@ROWCOUNT > 0)
		BEGIN
			----# update table surpluses
			--SELECT @tomson3_after AS [qc_instruction]
			--	, GETDATE() AS [updated_at]
			--	, @user_id AS [updated_by] 
			UPDATE [surpluses]
			SET [qc_instruction] = @tomson3_after
				--, [updated_at] = GETDATE()
				--, [updated_by] = @user_id
			FROM [APCSProDB].[trans].[surpluses]
			INNER JOIN @table_lot AS [table_lot] ON [surpluses].[lot_id] = [table_lot].[lot_id]
			WHERE [table_lot].[surplus] = 1;

			IF (@@ROWCOUNT > 0)
			BEGIN
				SET @lot_id_sort = '';
				SELECT @lot_id_sort = 
					( CASE WHEN @lot_id_sort = ''
						THEN COALESCE( CAST( [lot_id] AS VARCHAR(MAX) ), '' )
						ELSE @lot_id_sort + COALESCE( ',' + CAST( [lot_id] AS VARCHAR(MAX) ), '' )
					END )
				FROM @table_lot AS [table_lot]
				WHERE [table_lot].[surplus] = 1;

				EXEC [StoredProcedureDB].[atom].[sp_set_history_records]
					@lot_id = @lot_id_sort,
					@user_id = 1339,
					@table_name = N'surpluses';
			END

			----# update table label_issue_records
			--SELECT @tomson3_after AS [tomson_3]
			--	, GETDATE() AS [update_at]
			--	, @user_id AS [update_by] 
			UPDATE [label_issue_records]
			SET [tomson_3] = @tomson3_after
				--, [update_at] = GETDATE()
				--, [update_by] = @user_id
			FROM [APCSProDB].[trans].[label_issue_records]
			INNER JOIN @table_lot AS [table_lot] ON [label_issue_records].[lot_no] = [table_lot].[lot_no]
			WHERE [table_lot].[label] = 1;

			IF (@@ROWCOUNT > 0)
			BEGIN
				SET @lot_id_sort = '';
				SELECT @lot_id_sort = 
					( CASE WHEN @lot_id_sort = ''
						THEN COALESCE( CAST( [lot_id] AS VARCHAR(MAX) ), '' )
						ELSE @lot_id_sort + COALESCE( ',' + CAST( [lot_id] AS VARCHAR(MAX) ), '' )
					END )
				FROM @table_lot AS [table_lot]
				WHERE [table_lot].[label] = 1;

				EXEC [StoredProcedureDB].[atom].[sp_set_history_records]
					@lot_id = @lot_id_sort,
					@user_id = 1339,
					@table_name = N'label_issue_records';
			END
			SET @status_return = 1;
		END
	END
	ELSE IF ( @status = 1 ) --# 0:Update
	BEGIN
		----# update table lot_qc_info
		--SELECT @tomson3_after AS [tomson3_after]
		--	, GETDATE() AS [updated_at]
		--	, @user_id AS [updated_by] 
		UPDATE [lot_qc_info]
		SET [tomson3_after] = @tomson3_after
			, [updated_at] = GETDATE()
			, [updated_by] = @user_id
		FROM [APCSProDWH].[tg].[lot_qc_info]
		INNER JOIN @table_lot AS [table_lot] ON [lot_qc_info].[lot_id] = [table_lot].[lot_id]
		WHERE [qc_info] = 1;

		IF (@@ROWCOUNT > 0)
		BEGIN
			----# update table surpluses
			--SELECT @tomson3_after AS [qc_instruction]
			--	, GETDATE() AS [updated_at]
			--	, @user_id AS [updated_by] 
			UPDATE [surpluses]
			SET [qc_instruction] = @tomson3_after
				--, [updated_at] = GETDATE()
				--, [updated_by] = @user_id
			FROM [APCSProDB].[trans].[surpluses]
			INNER JOIN @table_lot AS [table_lot] ON [surpluses].[lot_id] = [table_lot].[lot_id]
			WHERE [table_lot].[surplus] = 1;

			IF (@@ROWCOUNT > 0)
			BEGIN
				SET @lot_id_sort = '';
				SELECT @lot_id_sort = 
					( CASE WHEN @lot_id_sort = ''
						THEN COALESCE( CAST( [lot_id] AS VARCHAR(MAX) ), '' )
						ELSE @lot_id_sort + COALESCE( ',' + CAST( [lot_id] AS VARCHAR(MAX) ), '' )
					END )
				FROM @table_lot AS [table_lot]
				WHERE [table_lot].[surplus] = 1;

				EXEC [StoredProcedureDB].[atom].[sp_set_history_records]
					@lot_id = @lot_id_sort,
					@user_id = 1339,
					@table_name = N'surpluses';
			END

			----# update table label_issue_records
			--SELECT @tomson3_after AS [tomson_3]
			--	, GETDATE() AS [update_at]
			--	, @user_id AS [update_by] 
			UPDATE [label_issue_records]
			SET [tomson_3] = @tomson3_after
				--, [update_at] = GETDATE()
				--, [update_by] = @user_id
			FROM [APCSProDB].[trans].[label_issue_records]
			INNER JOIN @table_lot AS [table_lot] ON [label_issue_records].[lot_no] = [table_lot].[lot_no]
			WHERE [table_lot].[label] = 1;

			IF (@@ROWCOUNT > 0)
			BEGIN
				SET @lot_id_sort = '';
				SELECT @lot_id_sort = 
					( CASE WHEN @lot_id_sort = ''
						THEN COALESCE( CAST( [lot_id] AS VARCHAR(MAX) ), '' )
						ELSE @lot_id_sort + COALESCE( ',' + CAST( [lot_id] AS VARCHAR(MAX) ), '' )
					END )
				FROM @table_lot AS [table_lot]
				WHERE [table_lot].[label] = 1;

				EXEC [StoredProcedureDB].[atom].[sp_set_history_records]
					@lot_id = @lot_id_sort,
					@user_id = 1339,
					@table_name = N'label_issue_records';
			END
			SET @status_return = 1;
		END
	END
	ELSE IF ( @status = 2 ) --# 2:Delete
	BEGIN
		SET NOCOUNT OFF;
		----# delete table lot_qc_info
		--SELECT @tomson3_after AS [tomson3_after]
		--	, GETDATE() AS [updated_at]
		--	, @user_id AS [updated_by] 
		DELETE FROM [lot_qc_info]
		FROM [APCSProDWH].[tg].[lot_qc_info]
		INNER JOIN @table_lot AS [table_lot] ON [lot_qc_info].[lot_id] = [table_lot].[lot_id]
		WHERE [qc_info] = 1;

		IF (@@ROWCOUNT > 0)
		BEGIN
			SET @status_return = 1;
		END
	END

	----# return
	IF (@status_return = 1)
	BEGIN
		SELECT 'TRUE' AS [Is_Pass] 
			, '' AS [Error_Message_ENG]
			, N'' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
			, (CASE WHEN @status = 0 THEN 'Insert'
				WHEN @status = 1 THEN 'Update'
				WHEN @status = 2 THEN 'Delete'
				ELSE ''
			END) + ' data error !!' AS [Error_Message_ENG]
			, (CASE WHEN @status = 0 THEN N'เพิ่ม'
				WHEN @status = 1 THEN N'แก้ไข'
				WHEN @status = 2 THEN N'ลบ'
				ELSE ''
			END) + N'ข้อมูลผิดพลาด !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END
END
