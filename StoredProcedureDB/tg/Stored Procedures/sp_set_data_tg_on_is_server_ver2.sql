-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,Update Call Table Interface to Is Server 2023/02/02 time : 11.24 ,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [tg].[sp_set_data_tg_on_is_server_ver2]
	-- Add the parameters for the stored procedure here
	 @lotno varchar(10)
	,@shipment_qty int = null
	,@is_function int = null   --1 : LSMS, 0 : Default (OGI Cellcon)
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

	-- USING TRANSACTION
	BEGIN TRANSACTION;
	BEGIN TRY
		-- 01 SET DATA IF --
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

			IF @is_function = 1 -- is LSMS (Function : Add Hasuu in rack)
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
					, 'Result [tg].[sp_set_data_tg_on_is_server_ver2] : '
						+ '@is_function = Clear data HASU_WIP_QTY (Hasuu stock in Rack)' 
						+ N',Error_Message_ENG = In Auto function clear data HASU_WIP_QTY and Other !!' 
						+ N',Error_Message_THA = เข้า function clear ข้อมูล ของ HASU_WIP_QTY และอื่นๆ !!' 
					, ISNULL(CAST(@lotno AS varchar),'NULL');
				RETURN
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
					+ N',Error_Message_ENG = UPDATE DATA SHIPMENT ERROR !!' 
					+ N',Error_Message_THA = ไม่สามารถ update ข้อมูลฝั่ง Is ได้ !!' 
				, ISNULL(CAST(@lotno AS varchar),'NULL');

			SELECT 'FALSE' AS Status 
				, 'UPDATE DATA SHIPMENT ERROR !!' AS Error_Message_ENG
				, N'ไม่สามารถ update ข้อมูลฝั่ง Is ได้ !!' AS Error_Message_THA 
				, N'กรุณาติดต่อ System' AS Handling;
			RETURN;
		END CATCH
		
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

		----> add 2023/02/24 10:00
		-- 04 SET IN_STOCK QTY = 0, SET FLAG H_STOCK --
		BEGIN TRY
			DECLARE @pcs INT
			IF EXISTS (SELECT [serial_no] FROM [APCSProDB].[trans].[surpluses] WHERE [serial_no] = @lotno)
			BEGIN
				SELECT TOP 1 @pcs = ISNULL(pcs,0)
				FROM [APCSProDB].[trans].[surpluses] 
				WHERE [serial_no] = @lotno;

				IF (@pcs = 0)
				BEGIN
					-- SET IN_STOCK --
					UPDATE [APCSProDB].[trans].[surpluses]
					SET [in_stock] = 0
					,[updated_at] = GETDATE()
					WHERE [serial_no] = @lotno;

					-- INSERT RECORD CLASS TO TABEL tg_sp_set_surpluse_records
					EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno
					,@sataus_record_class = 2
					,@emp_no_int = 1  --fix admin

					-- SET FLAG H_STOCK --
					UPDATE [APCSProDWH].[dbo].[H_STOCK_IF]
					SET [DMY_IN__Flag] = ''
						, [DMY_OUT_Flag] = 1
					WHERE [LotNo] = @lotno;
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
					+ N',Error_Message_ENG = update in_stock surpluses data error !!' 
					+ N',Error_Message_THA = บันทึกข้อมูล in_stock surpluses ผิดพลาด !!' 
				, ISNULL(CAST(@lotno AS varchar),'NULL');

			SELECT 'FALSE' AS Status 
				,'update in_stock surpluses data error !!' AS Error_Message_ENG
				, N'บันทึกข้อมูล in_stock surpluses ผิดพลาด !!' AS Error_Message_THA 
				, N'กรุณาติดต่อ System' AS Handling;
			RETURN;
		END CATCH
		----> add 2023/02/24 10:00

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
