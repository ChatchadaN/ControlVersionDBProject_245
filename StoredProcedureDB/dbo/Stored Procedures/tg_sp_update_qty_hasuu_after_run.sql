-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_update_qty_hasuu_after_run]
	-- Add the parameters for the stored procedure here
	 @standard_lot varchar(10) = ''
	,@hasuu_lot varchar(10) = ''
	,@qty_hasuu_before INT = 0
	,@qty_hasuu_now INT = 0

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @lot_id INT = 0
	DECLARE @r int= 0;
	DECLARE @qty_out INT;
	
    -- Insert statements for procedure here
	
	SELECT @lot_id = [lots].[id]
	--, @qty_out = ((device_names.pcs_per_pack) * ((lots.qty_pass)/(device_names.pcs_per_pack)) - @qty_hasuu_now)
	, @qty_out = ((device_names.pcs_per_pack) * ((lots.qty_pass)/(device_names.pcs_per_pack)))
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	WHERE [lots].[lot_no] = @standard_lot

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[tg_sp_update_qty_hasuu_after_run] @lotno = ''' + @standard_lot + ''',@qty_hasuu_before = ''' + CONVERT (varchar (10), @qty_hasuu_before) + ''',@qty_hasuu_now = ''' + CONVERT (varchar (10), @qty_hasuu_now) + ''''


		IF EXISTS(SELECT * FROM [APCSProDB].[trans].[surpluses] WHERE lot_id = @lot_id)
		BEGIN
			BEGIN TRY  
				-- UPDATE QTY_HASUU
				UPDATE [APCSProDB].[trans].[surpluses]
				SET 
				  [pcs] = @qty_hasuu_now
				, [in_stock] = '2'
				, [location_id] = NULL
				, [acc_location_id] = NULL
				, [updated_at] = GETDATE()
				, [updated_by] = '1'
				WHERE [serial_no] = @standard_lot
			END TRY
			BEGIN CATCH  
				SELECT 'FALSE' AS Status ,'UPDATE ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Update ข้อมูลใน Surplueses ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH  

			BEGIN TRY  
				--UPDATE TIME 
				UPDATE APCSProDB.trans.surpluse_records
				SET record_class = 2
				,updated_at = GETDATE()
				WHERE lot_id = @lot_id
			END TRY
			BEGIN CATCH  
				SELECT 'FALSE' AS Status ,'UPDATE ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Update ข้อมูลใน Surplueses_record ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH  


			--CREATE 2021/04/08
			--UPDATE QTY PASS IN TABLE : TRAN.LOT
			BEGIN TRY  
				-- UPDATE QTY PASS IN TABLE : TRAN.LOT
				UPDATE APCSProDB.trans.lots 
				SET qty_hasuu = @qty_hasuu_now
				,qty_out = @qty_out
				--,qty_combined = @qty_hasuu_before
				where lot_no = @standard_lot
			END TRY
			BEGIN CATCH  
				SELECT 'FALSE' AS Status ,'UPDATE ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Update ข้อมูล จำนวน hasuu ใน Tran.lots ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH  


			--IF  @hasuu_lot != ''
			--BEGIN
			--	BEGIN TRY 
			--	-- UPDATE IN_STOCK TO SURPLUSES
			--	UPDATE [APCSProDB].[trans].[surpluses]
			--	SET 
			--	  [in_stock] = '0'
			--	, [location_id] = ''
			--	, [acc_location_id] = ''
			--	, [updated_at] = GETDATE()
			--	, [updated_by] = '1'
			--	WHERE [serial_no] = @hasuu_lot
			--	--UPDATE WIP STATE
			--	--UPDATE [APCSProDB].[trans].[lots]
			--	--SET 
			--	--	[qty_hasuu] = @qty_hasuu_now
			--	--	, [wip_state] = '100'
			--	--WHERE [lot_no] = @hasuu_lot
			--END TRY
			--	BEGIN CATCH  
			--		SELECT 'FALSE' AS Status ,'UPDATE HASUU INSTOCK ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Update INSTOCK ของ Hasuu_lot ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			--		RETURN
			--	END CATCH  
			--END
		END
		ELSE
		BEGIN
			BEGIN TRY 
				-- INSERT DATA HASUU
				INSERT INTO [APCSProDB].[trans].[surpluses]
			   ([id]
			   , [lot_id]
			   , [pcs]
			   , [serial_no]
			   , [in_stock]
			   , [location_id]
			   , [acc_location_id]
			   , [created_at]
			   , [created_by]
			   , [updated_at]
			   , [updated_by])
				--SELECT [nu].[id] - 1 + row_number() over (order by [surpluses].[id]) AS id
				SELECT top(1) [nu].[id] + row_number() over (order by [surpluses].[id]) AS id
				, @lot_id AS lot_id
				, @qty_hasuu_now AS pcs
				, @standard_lot AS serial_no
				, '2' AS in_stock
				, NULL AS location_id
				, NULL AS acc_location_id
				, GETDATE() AS created_at
				, '1' AS created_by
				, GETDATE() AS updated_at
				, '1' AS updated_by
				FROM [APCSProDB].[trans].[surpluses]
				INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'surpluses.id'

				set @r = @@ROWCOUNT
				update [APCSProDB].[trans].[numbers]
				set id = id + @r 
				from [APCSProDB].[trans].[numbers]
				where name = 'surpluses.id'

			END TRY
			BEGIN CATCH  
				SELECT 'FALSE' AS Status ,'INSERT ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Insert ข้อมูลเข้า Surpluses ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH  

			BEGIN TRY 
				--INSERT TO TABEL RECORD CLASS
				EXEC [dbo].[tg_sp_set_surpluse_records] @lotno = @standard_lot,@sataus_record_class = 1
			END TRY
			BEGIN CATCH  
				SELECT 'FALSE' AS Status ,'INSERT ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Insert ข้อมูลเข้า Surpluses_record ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH  

			--CREATE 2021/04/08
			--UPDATE QTY PASS IN TABLE : TRAN.LOT
			BEGIN TRY  
				-- UPDATE QTY PASS IN TABLE : TRAN.LOT
				UPDATE APCSProDB.trans.lots 
				SET qty_hasuu = @qty_hasuu_now
				,qty_out = @qty_out
				--,qty_combined = @qty_hasuu_before
				where lot_no = @standard_lot
			END TRY
			BEGIN CATCH  
				SELECT 'FALSE' AS Status ,'UPDATE ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Update ข้อมูล จำนวน hasuu ใน Tran.lots ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH  

			--IF  @hasuu_lot != ''
			--	BEGIN
			--		BEGIN TRY 
			--		-- UPDATE IN_STOCK TO SURPLUSES
			--		UPDATE [APCSProDB].[trans].[surpluses]
			--		SET 
			--		  [in_stock] = '0'
			--		, [location_id] = ''
			--		, [acc_location_id] = ''
			--		, [updated_at] = GETDATE()
			--		, [updated_by] = '1'
			--		WHERE [serial_no] = @hasuu_lot
			--		--UPDATE WIP STATE 
			--		--UPDATE [APCSProDB].[trans].[lots]
			--		--SET 
			--		--	  [qty_hasuu] = @qty_hasuu_now
			--		--	, [qty_out] = @qty_out
			--		--	, [qty_combined] = @qty_hasuu_before
			--		--	, [wip_state] = '100'
			--		--WHERE [lot_no] = @hasuu_lot
			--	END TRY
			--	BEGIN CATCH  
			--		SELECT 'FALSE' AS Status ,'UPDATE ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ UPDATE WIP STATE ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			--		RETURN
			--	END CATCH 
			--END
		END	
	

END
