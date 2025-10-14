-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,Update Call Table Interface to Is Server 2023/02/02 time : 11.24 ,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [tg].[sp_set_data_tg_on_is_server_bk001]
	-- Add the parameters for the stored procedure here
	 @lotno varchar(10)
	,@shipment_qty int = null

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

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
		, 'EXEC [tg].[sp_set_data_tg_on_is_server] @lotno = ''' + ISNULL(CAST(@lotno AS varchar),'NULL') 
			+ ''', @@shipment_qty = ' + ISNULL(CAST(@shipment_qty AS varchar),'NULL')  + '' 
		, ISNULL(CAST(@lotno AS varchar),'NULL');

	IF (@shipment_qty IS NULL)
	BEGIN
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
			, 'Result [tg].[sp_set_data_tg_on_is_server] : '
				+ 'Status = FALSE' 
				+ N',Error_Message_ENG = SHIPMENT QTY IS EMPTY !!' 
				+ N',Error_Message_THA = จำนวน shipment เป็นค่าว่าง !!' 
			, ISNULL(CAST(@lotno AS varchar),'NULL');

		SELECT 'FALSE' AS Status 
			, 'SHIPMENT QTY IS EMPTY !!' AS Error_Message_ENG
			, N'จำนวน shipment เป็นค่าว่าง !!' AS Error_Message_THA 
			, N'กรุณาติดต่อ System' AS Handling;
		RETURN;
	END

	DECLARE @TypeLot varchar(10) = ''
	DECLARE @PC_Instruction_Code int = null

	SELECT @TypeLot = SUBSTRING(@lotno,5,1)
	
	SELECT @PC_Instruction_Code = pc_instruction_code FROM APCSProDB.trans.lots where lot_no = @lotno

	BEGIN TRY
		-- 01 UPDATE DATA TABLE H_STOCK, LSI_SHIP --
	    IF @PC_Instruction_Code = 13
		BEGIN
			--LSI_SHIP
			UPDATE APCSProDWH.dbo.LSI_SHIP_IF
			SET [Delete_Flag] = '1'  --fix data = 1
			WHERE [LotNo] = @lotno;
		END
		ELSE
		BEGIN
			IF @TypeLot = 'A' or @TypeLot = 'F'
			BEGIN
				--H_STOCK
				UPDATE APCSProDWH.dbo.H_STOCK_IF
				SET [DMY_IN__Flag] = ''  --fix blank
				WHERE [LotNo] = @lotno;

				--LSI_SHIP
				UPDATE APCSProDWH.dbo.LSI_SHIP_IF
				SET [Shipment_QTY] = @shipment_qty
					, [Delete_Flag] = '1'  --fix data = 1
				WHERE [LotNo] = @lotno;
			END
			ELSE IF @TypeLot = 'D'
			BEGIN
				--H_STOCK
				UPDATE APCSProDWH.dbo.H_STOCK_IF
				SET [HASU_WIP_QTY] = 0 --fix data = 0
					, [DMY_IN__Flag] = ''  --fix blank
				WHERE [LotNo] = @lotno;

				--LSI_SHIP
				UPDATE APCSProDWH.dbo.LSI_SHIP_IF
				SET [Shipment_QTY] = @shipment_qty
				   , [Delete_Flag] = '1'  --fix data = 1
				WHERE [LotNo] = @lotno;
			END
			ELSE IF @TypeLot = 'E'
			BEGIN
				--LSI_SHIP
				UPDATE APCSProDWH.dbo.LSI_SHIP_IF
				SET [Shipment_QTY] = @shipment_qty
					, [Delete_Flag] = '1'  --fix data = 1
				WHERE [LotNo] = @lotno;
			END
			ELSE
			BEGIN
				--Support Type Lot H,B,G
				--H_STOCK
				UPDATE APCSProDWH.dbo.H_STOCK_IF
				SET  [DMY_IN__Flag] = ''  --fix blank
				WHERE [LotNo] = @lotno;

				--LSI_SHIP
				UPDATE APCSProDWH.dbo.LSI_SHIP_IF
				SET [Shipment_QTY] = @shipment_qty
					, [Delete_Flag] = '1'  --fix data = 1
				WHERE [LotNo] = @lotno;
			END
		END
	END TRY
	BEGIN CATCH
		SELECT 'FALSE' AS Status 
			, 'UPDATE DATA SHIPMENT ERROR !!' AS Error_Message_ENG
			, N'ไม่สามารถ update ข้อมูลฝั่ง Is ได้ !!' AS Error_Message_THA 
			, N'กรุณาติดต่อ System' AS Handling;
		RETURN;
	END CATCH

	-- USING TRANSACTION
	BEGIN TRANSACTION;
	BEGIN TRY	
		-- 02 SET DATA MLIO2 --
		BEGIN TRY
		    DECLARE @count_rec_mli02 int = null
			select @count_rec_mli02 = COUNT(*) from APCSProDB.trans.mli02_lsi where LOTN = @lotno

			IF @count_rec_mli02 is not null
			BEGIN
				IF @count_rec_mli02 = 0
				BEGIN
				    --SET DATA MLI02
					EXEC [StoredProcedureDB].[dbo].[sp_set_data_cps_new] @lotno = @lotno
				END
				ELSE
				BEGIN
					--DELETE DATA MLI02
					DELETE APCSProDB.trans.mli02_lsi where LOTN = @lotno
					--SET DATA MLI02
					EXEC [StoredProcedureDB].[dbo].[sp_set_data_cps_new] @lotno = @lotno
				END
			END
		END TRY
		BEGIN CATCH
			-- ROLLBACK DATA
			ROLLBACK TRANSACTION;
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
				, 'Result [tg].[sp_set_data_tg_on_is_server] : '
					+ 'Status = FALSE' 
					+ N',Error_Message_ENG = INSERT MLI02 DATA ERROR !!' 
					+ N',Error_Message_THA = บันทึกข้อมูล mli02 ผิดพลาด !!' 
				, ISNULL(CAST(@lotno AS varchar),'NULL');

			SELECT 'FALSE' AS Status 
				,'INSERT MLI02 DATA ERROR !!' AS Error_Message_ENG
				, N'บันทึกข้อมูล mli02 ผิดพลาด !!' AS Error_Message_THA 
				, N'กรุณาติดต่อ System' AS Handling;
			RETURN;
		END CATCH

		-- 03 SET WIPSTATE MEMBER LOT --
		BEGIN TRY
			EXEC [StoredProcedureDB].[trans].[sp_set_wip_state_memberlot_new] @lot_no = @lotno
		END TRY
		BEGIN CATCH
			-- ROLLBACK DATA
			ROLLBACK TRANSACTION;
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
				, 'Result [tg].[sp_set_data_tg_on_is_server] : '
					+ 'Status = FALSE' 
					+ N',Error_Message_ENG = UPDATE WIP_STATE ERROR !!' 
					+ N',Error_Message_THA = บันทึกข้อมูล wip_state ผิดพลาด !!' 
				, ISNULL(CAST(@lotno AS varchar),'NULL');

			SELECT 'FALSE' AS Status 
				,'UPDATE WIP_STATE ERROR !!' AS Error_Message_ENG
				, N'บันทึกข้อมูล wip_state ผิดพลาด !!' AS Error_Message_THA 
				, N'กรุณาติดต่อ System' AS Handling;
			RETURN;
		END CATCH

		-- COMMIT DATA
		COMMIT TRANSACTION;	
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
			, 'Result [tg].[sp_set_data_tg_on_is_server] : '
				+ 'Status = TRUE'
			, ISNULL(CAST(@lotno AS varchar),'NULL');

		SELECT 'TRUE' AS Status 
			,'' AS Error_Message_ENG
			, N'' AS Error_Message_THA 
			, N'' AS Handling;
		RETURN;
	END TRY
	BEGIN CATCH
		-- ROLLBACK DATA
		ROLLBACK TRANSACTION;
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
			, 'Result [tg].[sp_set_data_tg_on_is_server] : '
				+ 'Status = FALSE' 
				+ N',Error_Message_ENG = UPDATE DATA ERROR !!' 
				+ N',Error_Message_THA = บันทึกข้อมูลผิดพลาด !!' 
			, ISNULL(CAST(@lotno AS varchar),'NULL');

		SELECT 'FALSE' AS Status 
		,ERROR_MESSAGE ()  AS Error_Message_ENG
			--,'UPDATE DATA ERROR !!' AS Error_Message_ENG
			, N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA 
			, N'กรุณาติดต่อ System' AS Handling;
		RETURN;
	END CATCH



END
