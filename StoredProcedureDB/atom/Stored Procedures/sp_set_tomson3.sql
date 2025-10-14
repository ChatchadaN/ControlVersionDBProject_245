-- =============================================
CREATE PROCEDURE [atom].[sp_set_tomson3] 
	-- Add the parameters for the stored procedure here
	@status INT = 0, ----#0:insert, 1:update, 2:delete
	@LotIdTable lot_tomson3 READONLY,
	@tomson3_after CHAR(4) = '   ', 
	@user_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO [StoredProcedureDB].[dbo].[exec_spdb_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [storedprocedname]
		, [lot_no]
		, [command_text] )
	SELECT GETDATE() --AS [record_at]
		, 4 AS [record_class]
		, ORIGINAL_LOGIN() --AS [login_name]
		, HOST_NAME() --AS [hostname]
		, APP_NAME() --AS [appname]
		, N'[StoredProcedureDB].[atom].[sp_set_tomson3]' --AS [storedprocedname]
		, N'tomson3' --AS [lot_no]
		, '@status = ' + ISNULL( CAST( @status AS VARCHAR ), '' ) 
			+ ', @LotIdTable = ''' + (SELECT CAST(ISNULL( STUFF( ( SELECT CONCAT(', ', lot_id) FROM @LotIdTable FOR XML PATH ('')), 1, 2, '' ), 'NULL' ) AS VARCHAR(MAX) ) ) + '''' 
			+ ', @tomson3_after = ''' + ISNULL( CAST( @tomson3_after AS VARCHAR ), '' )  + ''''
			+ ', @user_id = ' + ISNULL( CAST( @user_id AS VARCHAR ), '' );

	--IF (@user_id != 1339)
	--BEGIN
	--	SELECT 'FALSE' AS [Is_Pass] 
	--		, ( CASE WHEN @status = 0 THEN 'Insert'
	--			WHEN @status = 1 THEN 'Update'
	--			WHEN @status = 2 THEN 'Delete'
	--			ELSE ''
	--		END ) + ' data error !!' AS [Error_Message_ENG]
	--		, ( CASE WHEN @status = 0 THEN N'เพิ่ม'
	--			WHEN @status = 1 THEN N'แก้ไข'
	--			WHEN @status = 2 THEN N'ลบ'
	--			ELSE ''
	--		END ) + N'ข้อมูลผิดพลาด !!' AS [Error_Message_THA] 
	--		, N'กรุณาติดต่อ system' AS [Handling];
	--	RETURN;
	--END

	-------------------------------------------------------------------------------------------------------
	-- (***) declare parameter
	-------------------------------------------------------------------------------------------------------
	DECLARE @status_return INT = 0
	DECLARE @table_send AS atom.lot_tomson3 
	DECLARE @table_lot TABLE (
		[lot_id] [INT],
		[lot_no] [VARCHAR](10),
		[tomson3_before] [CHAR](4),
		[tomson3_after] [CHAR](4),
		[surplus] [INT],
		[label] [INT],
		[qc_info] [INT]
	)

	-------------------------------------------------------------------------------------------------------
	-- (***) insert data lot to temp_table(@table_lot) by parameter
	-------------------------------------------------------------------------------------------------------
	INSERT INTO @table_lot
	SELECT [lots].[id] AS [lot_id]
		, [lots].[lot_no]
		, ISNULL( [allocat].[Tomson3], ISNULL( [allocat_temp].[Tomson3], ISNULL( [surpluses].[qc_instruction], '' ) ) ) AS [tomson3_before]
		, @tomson3_after AS [tomson3_after]
		, ISNULL( [surpluses].[count], 0 ) AS [surplus]
		, ISNULL( [label_issue_records].[count], 0 ) AS [label]
		, ISNULL( [lot_qc_info].[count], 0 ) AS [qc_info]
	FROM @LotIdTable AS [table_lot]
	INNER JOIN [APCSProDB].[trans].[lots] ON [table_lot].[lot_id] = [lots].[id]
	LEFT JOIN [APCSProDB].[method].[allocat] ON [lots].[lot_no] = [allocat].[LotNo]
	LEFT JOIN [APCSProDB].[method].[allocat_temp] ON [lots].[lot_no] = [allocat_temp].[LotNo]
	OUTER APPLY (
		SELECT TOP 1 1 AS [count] 
		FROM [APCSProDWH].[tg].[lot_qc_info] 
		WHERE [lot_qc_info].[lot_id] = [lots].[id] 
	) AS [lot_qc_info]
	OUTER APPLY (
		SELECT TOP 1 1 AS [count], [surpluses].[qc_instruction] 
		FROM [APCSProDB].[trans].[surpluses] 
		WHERE [surpluses].[lot_id] = [lots].[id] 
	) AS [surpluses]
	OUTER APPLY (
		SELECT TOP 1 1 AS [count] 
		FROM [APCSProDB].[trans].[label_issue_records] 
		WHERE [label_issue_records].[lot_no] = [lots].[lot_no]
	) AS [label_issue_records];

	-------------------------------------------------------------------------------------------------------
	-- (***) check @status 0:insert, 1:update, 2:delete
	-------------------------------------------------------------------------------------------------------
	IF ( @status = 0 ) --# 0:Insert
	BEGIN
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
			UPDATE [allocat]
			SET [allocat].[Tomson3] = @tomson3_after
			FROM [APCSProDB].[method].[allocat]
			INNER JOIN @table_lot AS [table_lot] ON [allocat].[LotNo] = [table_lot].[lot_no]
			WHERE [qc_info] = 0;

			UPDATE [allocat]
			SET [allocat].[Tomson3] = @tomson3_after
			FROM [APCSProDB].[method].[allocat_temp] AS [allocat]
			INNER JOIN @table_lot AS [table_lot] ON [allocat].[LotNo] = [table_lot].[lot_no]
			WHERE [qc_info] = 0;

			IF EXISTS (SELECT [lot_id] FROM @table_lot WHERE [surplus] = 1)
				OR EXISTS (SELECT [lot_id] FROM @table_lot WHERE [label] = 1)
			BEGIN
				SET @status_return = 2;
			END
			ELSE
			BEGIN
				SET @status_return = 1;
			END
		END
	END
	ELSE IF ( @status = 1 ) --# 0:Update
	BEGIN
		UPDATE [lot_qc_info]
		SET [tomson3_after] = @tomson3_after
		FROM [APCSProDWH].[tg].[lot_qc_info]
		INNER JOIN @table_lot AS [table_lot] ON [lot_qc_info].[lot_id] = [table_lot].[lot_id]
		WHERE [qc_info] = 1;

		IF (@@ROWCOUNT > 0)
		BEGIN
			UPDATE [allocat]
			SET [allocat].[Tomson3] = @tomson3_after
			FROM [APCSProDB].[method].[allocat]
			INNER JOIN @table_lot AS [table_lot] ON [allocat].[LotNo] = [table_lot].[lot_no]
			WHERE [qc_info] = 1;

			UPDATE [allocat]
			SET [allocat].[Tomson3] = @tomson3_after
			FROM [APCSProDB].[method].[allocat_temp] AS [allocat]
			INNER JOIN @table_lot AS [table_lot] ON [allocat].[LotNo] = [table_lot].[lot_no]
			WHERE [qc_info] = 1;

			IF EXISTS (SELECT [lot_id] FROM @table_lot WHERE [surplus] = 1)
				OR EXISTS (SELECT [lot_id] FROM @table_lot WHERE [label] = 1)
			BEGIN
				SET @status_return = 2;
			END
			ELSE
			BEGIN
				SET @status_return = 1;
			END
		END
	END
	ELSE IF ( @status = 2 ) --# 2:Delete
	BEGIN
		SET NOCOUNT OFF;
		DELETE FROM [lot_qc_info]
		FROM [APCSProDWH].[tg].[lot_qc_info]
		INNER JOIN @table_lot AS [table_lot] ON [lot_qc_info].[lot_id] = [table_lot].[lot_id]
		WHERE [qc_info] = 1;

		IF (@@ROWCOUNT > 0)
		BEGIN
			SET @status_return = 1;
		END
	END

	-------------------------------------------------------------------------------------------------------
	-- (***) surpluses and label_issue_records 
	-------------------------------------------------------------------------------------------------------
	IF (@status_return = 2)
	BEGIN
		-------------------------------------------------------------------------------------------------------
		-- (1) Update table surpluses, Insert table surpluse_records
		-------------------------------------------------------------------------------------------------------
		INSERT INTO @table_send([lot_id])
		SELECT [lot_id]
		FROM @table_lot AS [table_lot]
		WHERE [table_lot].[surplus] = 1;

		-------------------------------------------------------------------------------------------------------
		-- (1.1) Update table surpluses
		-------------------------------------------------------------------------------------------------------
		UPDATE [surpluses]
		SET [qc_instruction] = @tomson3_after
		FROM [APCSProDB].[trans].[surpluses]
		INNER JOIN @table_lot AS [table_lot] ON [surpluses].[lot_id] = [table_lot].[lot_id]
		WHERE [table_lot].[surplus] = 1;

		-------------------------------------------------------------------------------------------------------
		-- (1.2) Insert table surpluse_records
		-------------------------------------------------------------------------------------------------------
		EXEC [StoredProcedureDB].[atom].[sp_set_history_records]
			@LotIdTable = @table_send,
			@user_id = @user_id,
			@table_name = N'surpluses';
		DELETE FROM @table_send;

		-------------------------------------------------------------------------------------------------------
		-- (2) Update table label_issue_records, Insert table label_issue_records_hist
		-------------------------------------------------------------------------------------------------------
		INSERT INTO @table_send([lot_id])
		SELECT [lot_id]
		FROM @table_lot AS [table_lot]
		WHERE [table_lot].[label] = 1;

		-------------------------------------------------------------------------------------------------------
		-- (2.1) Update table label_issue_records
		-------------------------------------------------------------------------------------------------------
		UPDATE [label_issue_records]
		SET [tomson_3] = @tomson3_after
		FROM [APCSProDB].[trans].[label_issue_records]
		INNER JOIN @table_lot AS [table_lot] ON [label_issue_records].[lot_no] = [table_lot].[lot_no]
		WHERE [table_lot].[label] = 1;

		-------------------------------------------------------------------------------------------------------
		-- (2.2) Insert table label_issue_records_hist
		-------------------------------------------------------------------------------------------------------
		EXEC [StoredProcedureDB].[atom].[sp_set_history_records]
			@LotIdTable = @table_send,
			@user_id = @user_id,
			@table_name = N'label_issue_records';
		DELETE FROM @table_send;

		SET @status_return = 1;
	END

	-------------------------------------------------------------------------------------------------------
	-- (***) return
	-------------------------------------------------------------------------------------------------------
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
			, ( CASE WHEN @status = 0 THEN 'Insert'
				WHEN @status = 1 THEN 'Update'
				WHEN @status = 2 THEN 'Delete'
				ELSE ''
			END ) + ' data error !!' AS [Error_Message_ENG]
			, ( CASE WHEN @status = 0 THEN N'เพิ่ม'
				WHEN @status = 1 THEN N'แก้ไข'
				WHEN @status = 2 THEN N'ลบ'
				ELSE ''
			END ) + N'ข้อมูลผิดพลาด !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END
END
