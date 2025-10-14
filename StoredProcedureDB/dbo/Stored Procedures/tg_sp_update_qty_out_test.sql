-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_update_qty_out_test]
	-- Add the parameters for the stored procedure here
	 @standard_lot varchar(10) = ''
	,@hasuu_lot varchar(10) = ''
	,@qty_hasuu_before INT = 0
	,@qty_hasuu_now INT = 0
	,@qty_pass_now INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @lot_id INT = 0;
	DECLARE @r int= 0;
	DECLARE @qty_shipment INT = 0;
	DECLARE @qty_sum INT = 0;
	DECLARE @pcs_per_pack int = 0;
    -- Insert statements for procedure here

	begin
	SELECT @lot_id = [lots].[id]
	--, @qty_out = ((device_names.pcs_per_pack) * ((lots.qty_pass)/(device_names.pcs_per_pack)) - @qty_hasuu_now)
	, @qty_shipment = ((device_names.pcs_per_pack) * ((@qty_pass_now + @qty_hasuu_before)/(device_names.pcs_per_pack))) --Update 2021/10/01
	, @pcs_per_pack = device_names.pcs_per_pack
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	WHERE [lots].[lot_no] = @standard_lot;
	end
	--EXEC [StoredProcedureDB].[dbo].[tg_sp_update_qty_out_after_lot_end] 
	-- @lotno = @standard_lot
	--,@qty_ship = @qty_shipment
	--,@qty_hasuu_now_value = @qty_hasuu_now

	--CREATE 2021/10/04 Time : 12.00
	--GET DATA QTY SUM [qty_shipment + qty_hasuu_now]

	SET @qty_sum = (@qty_shipment + @qty_hasuu_now);
	select @qty_hasuu_before,@standard_lot
	--IF EXISTS(SELECT * FROM [APCSProDB].[trans].[surpluses] WHERE lot_id = @lot_id)
	--	BEGIN
			--UPDATE [APCSProDB].[trans].[surpluses]
			--SET [pcs] = @qty_hasuu_now
			--, [in_stock] = iif(@qty_hasuu_now = 0,'0','2')
			--, [location_id] = ''
			--, [acc_location_id] = ''
			--, [updated_at] = GETDATE()
			--, [updated_by] = '1'
			--WHERE [serial_no] = @standard_lot
			
			--UPDATE APCSProDB.trans.lots 
			--SET qty_hasuu = @qty_hasuu_now
			--	,qty_out = (case when @qty_shipment = 0 then 0 
			--				else @qty_shipment end)
			--where lot_no = @standard_lot
			

			--DECLARE	@return_value int
			--EXEC [StoredProcedureDB].[dbo].[tg_sp_set_qty_fristlot_update] @lot_no = @standard_lot,@qty = @qty_sum;
			
		
		--END
	--ELSE
		
	--	BEGIN
	--		BEGIN TRY 
	--			-- INSERT DATA HASUU
	--			INSERT INTO [APCSProDB].[trans].[surpluses]
	--		   ([id]
	--		   , [lot_id]
	--		   , [pcs]
	--		   , [serial_no]
	--		   , [in_stock]
	--		   , [location_id]
	--		   , [acc_location_id]
	--		   , [created_at]
	--		   , [created_by]
	--		   , [updated_at]
	--		   , [updated_by])
	--			--SELECT [nu].[id] - 1 + row_number() over (order by [surpluses].[id]) AS id
	--			SELECT top(1) [nu].[id] + row_number() over (order by [surpluses].[id]) AS id
	--			, @lot_id AS lot_id
	--			, @qty_hasuu_now AS pcs
	--			, @standard_lot AS serial_no
	--			, '2' AS in_stock
	--			, '' AS location_id
	--			, '' AS acc_location_id
	--			, GETDATE() AS created_at
	--			, '1' AS created_by
	--			, GETDATE() AS updated_at
	--			, '1' AS updated_by
	--			FROM [APCSProDB].[trans].[surpluses]
	--			INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'surpluses.id';

	--			set @r = @@ROWCOUNT
	--			update [APCSProDB].[trans].[numbers]
	--			set id = id + @r 
	--			from [APCSProDB].[trans].[numbers]
	--			where name = 'surpluses.id';

	--		END TRY
	--		BEGIN CATCH  
	--			SELECT 'FALSE' AS Status ,'INSERT ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Insert ข้อมูลเข้า Surpluses ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
	--			RETURN
	--		END CATCH  


	--		BEGIN TRY 
	--			--INSERT TO TABEL RECORD CLASS
	--			EXEC [dbo].[tg_sp_set_surpluse_records] @lotno = @standard_lot,@sataus_record_class = 1;
	--		END TRY
	--		BEGIN CATCH  
	--			SELECT 'FALSE' AS Status ,'INSERT ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Insert ข้อมูลเข้า Surpluses_record ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
	--			RETURN
	--		END CATCH  


	--		--CREATE 2021/04/08
	--		--UPDATE QTY PASS IN TABLE : TRAN.LOT
	--		BEGIN TRY  
	--			-- UPDATE QTY PASS IN TABLE : TRAN.LOT
	--			UPDATE APCSProDB.trans.lots 
	--			SET qty_hasuu = @qty_hasuu_now
	--			,qty_out = case when @qty_shipment = 0 then 0 else @qty_shipment end
	--			where lot_no = @standard_lot;
	--		END TRY
	--		BEGIN CATCH  
	--			SELECT 'FALSE' AS Status ,'UPDATE ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Update ข้อมูล จำนวน hasuu ใน Tran.lots ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
	--			RETURN
	--		END CATCH  


	--		--CREATE 2021/10/04 Time : 12.00
	--		--AUTO UPDATE QTY ON LABEL
	--		BEGIN TRY
	--			EXEC [dbo].[tg_sp_set_qty_fristlot_update] @lot_no = @standard_lot,@qty = @qty_sum;
	--		END TRY
	--		BEGIN CATCH  
	--			SELECT 'FALSE' AS Status ,'UPDATE QTY ON LABEL ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Update ข้อมูล จำนวนงาน ใน Tran.Label_Issue_Record ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
	--			RETURN
	--		END CATCH

	--	END	
END
