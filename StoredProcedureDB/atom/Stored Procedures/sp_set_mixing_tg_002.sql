-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_mixing_tg_002]
	-- Add the parameters for the stored procedure here
	  @new_lotno VARCHAR(10)
	, @lot_no VARCHAR(MAX)
	, @empid INT
	, @app_type INT = 0 -- 0:default 1:LSMS
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	----------------------------------------------------------------------------
	----- # log exec stored procedure
	----------------------------------------------------------------------------
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	(
		[record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
	)
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, ISNULL('EXEC [atom].[p_set_mixing_tg_002] @new_lotno = ''' + @new_lotno + '''','EXEC [atom].[p_set_mixing_tg_002] @new_lotno = NULL')
			+ ISNULL(', @lot_no = ''' + @lot_no + '''',', @lot_no = NULL')
			+ ISNULL(', @empid = ' + CAST(@empid AS VARCHAR),', @empid = NULL')
		, @new_lotno;
	----------------------------------------------------------------------------
	----- # create lot in trans.lot_combine, trans.lot_combine_records
	----------------------------------------------------------------------------
	DECLARE @empnum VARCHAR(6) = (SELECT [emp_num] FROM [APCSProDB].[man].[users] WITH (NOLOCK) WHERE [id] = @empid);
	DECLARE @date DATETIME = GETDATE();

	IF ( @app_type = 0 )
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			IF EXISTS (
				SELECT [lot_mas].[lot_no] AS [lot_no]  
					, [lot_mas].[id] AS [lot_id] 
					, [lot_mem].[lot_no] AS [member_lot_no]  
					, [lot_mem].[id] AS [member_lot_id]  
				FROM (
					SELECT TRIM(value) AS [lot_no]
					FROM STRING_SPLIT(@lot_no, ',')
					WHERE value != ''
				) AS [table_lot]
				INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mem] ON [table_lot].[lot_no] = [lot_mem].[lot_no]
				INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mas] ON [lot_mas].[lot_no] = @new_lotno
			)
			BEGIN
				-----------------------------------------------------------------------------
				-------- set data to trans.lot_combine --------
				INSERT INTO [APCSProDB].[trans].[lot_combine]
				(
					[lot_id] 
					, [idx]
					, [member_lot_id] 
					, [created_at]
					, [created_by]
					, [updated_at]
					, [updated_by]
				)
				SELECT [lot_mas].[id] AS [lot_id] 
					, [row] AS [idx]
					, [lot_mem].[id] AS [member_lot_id] 
					, @date AS [created_at]
					--, CAST(@empnum AS INT) AS [created_by]
					, @empid AS [created_by] --new
					, @date AS [updated_at]
					--, CAST(@empnum AS INT) AS [updated_by]
					, @empid AS [updated_by] --new
				FROM (
					SELECT TRIM(value) AS [lot_no], (ROW_NUMBER() OVER(ORDER BY (SELECT 1)) - 1) AS [row]
					FROM STRING_SPLIT(@lot_no, ',')
					WHERE value != ''
				) AS [table_lot]
				INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mem] WITH (NOLOCK) ON [table_lot].[lot_no] = [lot_mem].[lot_no]
				INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mas] WITH (NOLOCK) ON [lot_mas].[lot_no] = @new_lotno;

				-------- set data to trans.lot_combine_records --------
				INSERT INTO [APCSProDB].[trans].[lot_combine_records]
				(
					[recorded_at]
					, [operated_by]
					, [record_class]
					, [lot_id] 
					, [idx]
					, [member_lot_id] 
					, [created_at]
					, [created_by]
					, [updated_at]
					, [updated_by]
				)
				SELECT @date AS [recorded_at]
					, CAST(@empnum AS INT) AS [operated_by]
					, 1 AS [record_class]
					, [lot_mas].[id] AS [lot_id] 
					, [row] AS [idx]
					, [lot_mem].[id] AS [member_lot_id] 
					, @date AS [created_at]
					--, CAST(@empnum AS INT) AS [created_by]
					, @empid AS [created_by] --new
					, @date AS [updated_at]
					--, CAST(@empnum AS INT) AS [updated_by]
					, @empid AS [updated_by] --new
				FROM (
					SELECT TRIM(value) AS [lot_no], (ROW_NUMBER() OVER(ORDER BY (SELECT 1)) - 1) AS [row]
					FROM STRING_SPLIT(@lot_no, ',')
					WHERE value != ''
				) AS [table_lot]
				INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mem] WITH (NOLOCK) ON [table_lot].[lot_no] = [lot_mem].[lot_no]
				INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mas] WITH (NOLOCK) ON [lot_mas].[lot_no] = @new_lotno;
				-----------------------------------------------------------------------------
				COMMIT TRANSACTION;
				SELECT 'TRUE' AS [Is_Pass] 
					, '' AS [Error_Message_ENG]
					, N'' AS [Error_Message_THA] 
					, N'' AS [Handling];
				RETURN;
				-----------------------------------------------------------------------------
			END
			ELSE
			BEGIN
				-----------------------------------------------------------------------------
				COMMIT TRANSACTION;
				SELECT 'FALSE' AS [Is_Pass] 
					, 'Data not found !!' AS [Error_Message_ENG]
					, N'ไม่พบข้อมูล' AS [Error_Message_THA] 
					, N'กรุณาติดต่อ system' AS [Handling];
				RETURN;
				-----------------------------------------------------------------------------
			END
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			SELECT 'FALSE' AS [Is_Pass] 
				, 'Insert data trans.lot_combine error !!' AS [Error_Message_ENG]
				, N'เพิ่มข้อมูล trans.lot_combine ไม่สำเร็จ !!' AS [Error_Message_THA] 
				, N'กรุณาติดต่อ system' AS [Handling];
			RETURN;
		END CATCH
	END
	ELSE IF ( @app_type = 1 )
	BEGIN
		-------- set data to trans.lot_combine --------
		INSERT INTO [APCSProDB].[trans].[lot_combine]
		(
			[lot_id] 
			, [idx]
			, [member_lot_id] 
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by]
		)
		SELECT [lot_mas].[id] AS [lot_id] 
			, [row] AS [idx]
			, [lot_mem].[id] AS [member_lot_id] 
			, @date AS [created_at]
			--, CAST(@empnum AS INT) AS [created_by]
			, @empid AS [created_by] --new
			, @date AS [updated_at]
			--, CAST(@empnum AS INT) AS [updated_by]
			, @empid AS [updated_by] --new
		FROM (
			SELECT TRIM(value) AS [lot_no], (ROW_NUMBER() OVER(ORDER BY (SELECT 1)) - 1) AS [row]
			FROM STRING_SPLIT(@lot_no, ',')
			WHERE value != ''
		) AS [table_lot]
		INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mem] WITH (NOLOCK) ON [table_lot].[lot_no] = [lot_mem].[lot_no]
		INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mas] WITH (NOLOCK) ON [lot_mas].[lot_no] = @new_lotno;

		-------- set data to trans.lot_combine_records --------
		INSERT INTO [APCSProDB].[trans].[lot_combine_records]
		(
			[recorded_at]
			, [operated_by]
			, [record_class]
			, [lot_id] 
			, [idx]
			, [member_lot_id] 
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by]
		)
		SELECT @date AS [recorded_at]
			, CAST(@empnum AS INT) AS [operated_by]
			, 1 AS [record_class]
			, [lot_mas].[id] AS [lot_id] 
			, [row] AS [idx]
			, [lot_mem].[id] AS [member_lot_id] 
			, @date AS [created_at]
			--, CAST(@empnum AS INT) AS [created_by]
			, @empid AS [created_by] --new
			, @date AS [updated_at]
			--, CAST(@empnum AS INT) AS [updated_by]
			, @empid AS [updated_by] --new
		FROM (
			SELECT TRIM(value) AS [lot_no], (ROW_NUMBER() OVER(ORDER BY (SELECT 1)) - 1) AS [row]
			FROM STRING_SPLIT(@lot_no, ',')
			WHERE value != ''
		) AS [table_lot]
		INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mem] WITH (NOLOCK) ON [table_lot].[lot_no] = [lot_mem].[lot_no]
		INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mas] WITH (NOLOCK) ON [lot_mas].[lot_no] = @new_lotno;	
	END
END
