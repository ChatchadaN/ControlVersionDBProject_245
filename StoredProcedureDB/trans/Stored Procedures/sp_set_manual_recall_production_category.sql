-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_manual_recall_production_category]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10),
	@opno VARCHAR(6),
	@qty_pass INT,
	@qty_combined INT,
	@qty_hasuu INT,
	@qty_out INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here
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
		, ISNULL('EXEC [trans].[sp_set_manual_recall_production_category] @lot_no = ''' + @lot_no + ''''
				+ ', @opno = ''' + ISNULL(CAST(@opno AS VARCHAR), 'NULL') + ''''
				+ ', @qty_pass = ' + ISNULL(CAST(@qty_pass AS VARCHAR), 'NULL')
				+ ', @qty_combined = ' + ISNULL(CAST(@qty_combined AS VARCHAR), 'NULL')
				+ ', @qty_hasuu = ' + ISNULL(CAST(@qty_hasuu AS VARCHAR), 'NULL')
				+ ', @qty_out = ' + ISNULL(CAST(@qty_out AS VARCHAR), 'NULL')
			,'EXEC [trans].[sp_set_manual_recall_production_category] @lot_no = NULL'
				+ ', @opno = ''' + ISNULL(CAST(@opno AS VARCHAR), 'NULL') + ''''
				+ ', @qty_pass = ' + ISNULL(CAST(@qty_pass AS VARCHAR), 'NULL')
				+ ', @qty_combined = ' + ISNULL(CAST(@qty_combined AS VARCHAR), 'NULL')
				+ ', @qty_hasuu = ' + ISNULL(CAST(@qty_hasuu AS VARCHAR), 'NULL')
				+ ', @qty_out = ' + ISNULL(CAST(@qty_out AS VARCHAR), 'NULL'))
		, @lot_no;

	DECLARE @production_category INT = 0;

	IF EXISTS ( SELECT [lot_no] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no )
	BEGIN
		IF EXISTS ( SELECT [NEWLOT] FROM [APCSProDWH].[dbo].[PROCESS_RECALL_IF] WHERE [NEWLOT] = @lot_no )
		BEGIN
			SET @production_category = (
				SELECT [production_category] 
				FROM [APCSProDB].[trans].[lots] 
				WHERE lot_no = @lot_no
			);

			BEGIN TRANSACTION
			BEGIN TRY
				UPDATE [APCSProDB].[trans].[lots] 
				SET	[qty_pass] = @qty_pass
					, [qty_combined] = @qty_combined
					, [qty_hasuu] = @qty_hasuu
					, [qty_out] = @qty_out
				WHERE [lot_no] = @lot_no;

				COMMIT TRANSACTION;
			END TRY
			BEGIN CATCH
				ROLLBACK TRANSACTION;
				SELECT 'FALSE' AS [Is_Pass] 
					, 'Insert data error !!' AS [Error_Message_ENG]
					, N'เพิ่มข้อมูลไม่สำเร็จ !!' AS [Error_Message_THA] 
					, N'กรุณาติดต่อ system' AS [Handling];
				RETURN;
			END CATCH

			IF (@production_category != 70)
			BEGIN
				BEGIN TRANSACTION
				BEGIN TRY
					UPDATE [APCSProDB].[trans].[lots] 
					SET [production_category] = 70
					WHERE [lot_no] = @lot_no;

					EXEC [StoredProcedureDB].[trans].[sp_set_record_class_lot_process_records] 
						@lot_no = @lot_no
						, @opno = '000000'
						, @record_class = 120
						, @mcno = 'ATOMMOVE';

					COMMIT TRANSACTION;
				END TRY
				BEGIN CATCH
					ROLLBACK TRANSACTION;
					SELECT 'FALSE' AS [Is_Pass] 
						, 'Insert data error !!' AS [Error_Message_ENG]
						, N'เพิ่มข้อมูลไม่สำเร็จ !!' AS [Error_Message_THA] 
						, N'กรุณาติดต่อ system' AS [Handling];
					RETURN;
				END CATCH
			END

			SELECT 'TRUE' AS Is_Pass 
				, '' AS Error_Message_ENG
				, N'' AS Error_Message_THA 
				, '' AS Handling;
			RETURN;
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS Is_Pass 
				, 'LotNo data not found in magic' AS Error_Message_ENG
				, N'ไม่พบข้อมูล LotNo ใน magic' AS Error_Message_THA 
				, '' AS Handling;
			RETURN;
		END
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS Is_Pass 
			, 'LotNo data not found' AS Error_Message_ENG
			, N'ไม่พบข้อมูล LotNo' AS Error_Message_THA 
			, '' AS Handling;
		RETURN;
	END
END
