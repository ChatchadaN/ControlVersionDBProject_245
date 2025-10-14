
CREATE PROCEDURE [lsms].[sp_set_mixing_tg]
	-- Add the parameters for the stored procedure here
	  @master_lot VARCHAR(10)
	, @hasuu_lot TG_List READONLY
	, @emp_id INT
	, @is_return INT --#0: no return, 1: retrun
	, @Is_Pass NVARCHAR(MAX) = NULL OUTPUT
	, @Error_Message_ENG NVARCHAR(MAX) = NULL OUTPUT
	, @Error_Message_THA NVARCHAR(MAX) = NULL OUTPUT
	, @Handling NVARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--add log date modify : 2024.DEC.04 Time : 11.06 by Aomsin
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
		, 'EXEC [lsms].[sp_set_mixing_tg]  @master_lot = ''' + ISNULL(@master_lot, '') 
				+ ''', @emp_id = ''' + ISNULL(CAST(@emp_id AS VARCHAR(10)),'') 
				+ ''', @is_return = ''' + ISNULL(CAST(@is_return AS VARCHAR(10)),'') + ''''
		, ISNULL(@master_lot,'NULL');

	----------------------------------------------------------------------------
	----- # create lot in trans.lot_combine, trans.lot_combine_records
	----------------------------------------------------------------------------
	DECLARE @date DATETIME = GETDATE();

	BEGIN TRANSACTION
	BEGIN TRY
		IF NOT EXISTS (
			SELECT [lot_mas].[lot_no] AS [lot_no]  
				, [lot_mas].[id] AS [lot_id] 
			FROM [APCSProDB].[trans].[lot_informations] AS [lot_mas]
			INNER JOIN [APCSProDB].[trans].[lot_combine] ON [lot_combine].[lot_id] = [lot_mas].[id]
			WHERE [lot_mas].[lot_no] = @master_lot
		)
		BEGIN
			-----------------------------------------------------------------------------
			IF EXISTS(SELECT TOP 1 [lot_no] FROM @hasuu_lot)
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
					, @emp_id AS [created_by]
					, @date AS [updated_at]
					, @emp_id AS [updated_by]
				FROM (
					SELECT [lot_no]
						, (ROW_NUMBER() OVER(ORDER BY (SELECT 1)) - 1) AS [row]
					FROM @hasuu_lot
				) AS [table_lot]
				INNER JOIN [APCSProDB].[trans].[lot_informations] AS [lot_mem] ON [table_lot].[lot_no] = [lot_mem].[lot_no]
				INNER JOIN [APCSProDB].[trans].[lot_informations] AS [lot_mas] ON [lot_mas].[lot_no] = @master_lot;

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
					, @emp_id AS [operated_by]
					, 1 AS [record_class]
					, [lot_mas].[id] AS [lot_id] 
					, [row] AS [idx]
					, [lot_mem].[id] AS [member_lot_id] 
					, @date AS [created_at]
					, @emp_id AS [created_by]
					, @date AS [updated_at]
					, @emp_id AS [updated_by]
				FROM (
					SELECT [lot_no]
						, (ROW_NUMBER() OVER(ORDER BY (SELECT 1)) - 1) AS [row]
					FROM @hasuu_lot
				) AS [table_lot]
				INNER JOIN [APCSProDB].[trans].[lot_informations] AS [lot_mem] ON [table_lot].[lot_no] = [lot_mem].[lot_no]
				INNER JOIN [APCSProDB].[trans].[lot_informations] AS [lot_mas] ON [lot_mas].[lot_no] = @master_lot;
			END
			ELSE
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
				SELECT [id] AS [lot_id] 
					, 0 AS [idx]
					, [id] AS [member_lot_id] 
					, @date AS [created_at]
					, @emp_id AS [created_by]
					, @date AS [updated_at]
					, @emp_id AS [updated_by]
				FROM [APCSProDB].[trans].[lot_informations] 
				WHERE [lot_no] = @master_lot;

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
					, @emp_id AS [operated_by]
					, 1 AS [record_class]
					, [id] AS [lot_id] 
					, 0 AS [idx]
					, [id] AS [member_lot_id] 
					, @date AS [created_at]
					, @emp_id AS [created_by]
					, @date AS [updated_at]
					, @emp_id AS [updated_by]
				FROM [APCSProDB].[trans].[lot_informations] 
				WHERE [lot_no] = @master_lot;
			END

			-----------------------------------------------------------------------------
			COMMIT TRANSACTION;
			SET @Is_Pass = 'TRUE';
			SET @Error_Message_ENG = '';
			SET @Error_Message_THA = '';
			SET @Handling = '';

			IF (@is_return = 1)
			BEGIN
				SELECT @Is_Pass AS [Is_Pass] 
					, @Error_Message_ENG AS [Error_Message_ENG]
					, @Error_Message_THA AS [Error_Message_THA] 
					, @Handling AS [Handling];
			END
			RETURN;
			-----------------------------------------------------------------------------
		END
		ELSE
		BEGIN
			-----------------------------------------------------------------------------
			COMMIT TRANSACTION;
			SET @Is_Pass = 'FALSE';
			SET @Error_Message_ENG = 'Lot is combine !!';
			SET @Error_Message_THA = N'Lot นี้ถูกรวม Lot แล้ว';
			SET @Handling = N'กรุณาติดต่อ system';

			IF (@is_return = 1)
			BEGIN
				SELECT @Is_Pass AS [Is_Pass] 
					, @Error_Message_ENG AS [Error_Message_ENG]
					, @Error_Message_THA AS [Error_Message_THA] 
					, @Handling AS [Handling];
			END
			RETURN;
			-----------------------------------------------------------------------------
		END
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @Is_Pass = 'FALSE';
		SET @Error_Message_ENG = 'Insert data trans.lot_combine error !!';
		SET @Error_Message_THA = N'เพิ่มข้อมูล trans.lot_combine ไม่สำเร็จ !!';
		SET @Handling = N'กรุณาติดต่อ system';

		IF (@is_return = 1)
		BEGIN
			SELECT @Is_Pass AS [Is_Pass] 
				, @Error_Message_ENG AS [Error_Message_ENG]
				, @Error_Message_THA AS [Error_Message_THA] 
				, @Handling AS [Handling];
		END
		RETURN;
	END CATCH
END
