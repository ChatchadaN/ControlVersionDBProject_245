-- =============================================
-- Author:		<009131,,Vanatjaya>
-- Create date: <Create Date,2021/05/05,>
-- Description:	<Description,,TP Cellcon USE>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_update_version_reprint] 
	-- Add the parameters for the stored procedure here
	 @lot_no varchar(10)
	,@type_of_label int = 0
	,@Reel_Num int = 0 --add parameter date : 2021/12/08 time : 10.35
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRY 
		--Add Log Date : 2023/01/23 Time : 15.00
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		([record_at]
		  , [record_class]
		  , [login_name]
		  , [hostname]
		  , [appname]
		  , [command_text]
		  , [lot_no])
		SELECT GETDATE()
			,'4'
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			,'EXEC [dbo].[tg_sp_update_version_reprint_on_tp_cellcon] @Lotno = ''' + @lot_no + ''', @type_of_label = ''' + CONVERT(VARCHAR(2),@type_of_label) + ''', @Reel_Num = ''' + CONVERT(VARCHAR(2),@Reel_Num) + ''''
			,@lot_no

		--add condition date : 2021/12/08 time : 10.35
		IF @Reel_Num = 0
		BEGIN
			--print all reel old version
			update APCSProDB.trans.label_issue_records 
			set version = version + 1  
			where lot_no = @lot_no
			and type_of_label = @type_of_label

			--insert data reprint on label his date modify : 2022/02/18 time : 15.30
			INSERT INTO APCSProDB.trans.[label_issue_records_hist] (
				  label_issue_id
				, recorded_at
				, record_class
				, operated_by
				, type_of_label
				, lot_no
				, customer_device
				, rohm_model_name
				, qty
				, barcode_lotno
				, tomson_box
				, tomson_3
				, box_type
				, barcode_bottom
				, mno_std
				, std_qty_before
				, mno_hasuu
				, hasuu_qty_before
				, no_reel
				, qrcode_detail
				, type_label_laterat
				, mno_std_laterat
				, mno_hasuu_laterat
				, barcode_device_detail
				, op_no
				, op_name
				, seq
				, ip_address
				, msl_label
				, floor_life
				, ppbt
				, re_comment
				, version
				, is_logo
				, mc_name
				, barcode_1_mod
				, barcode_2_mod
				, seal
				, create_at
				, create_by
				, update_at
				, update_by
				)
				SELECT 
				  id
				, GETDATE()
				, 1 --fix 1
				, operated_by
				, type_of_label
				, lot_no
				, customer_device
				, rohm_model_name
				, qty
				, barcode_lotno
				, tomson_box
				, tomson_3
				, box_type
				, barcode_bottom
				, mno_std
				, std_qty_before
				, mno_hasuu
				, hasuu_qty_before
				, no_reel
				, qrcode_detail
				, type_label_laterat
				, mno_std_laterat
				, mno_hasuu_laterat
				, barcode_device_detail
				, op_no
				, op_name
				, seq
				, ip_address
				, msl_label
				, floor_life
				, ppbt
				, re_comment
				, version 
				, is_logo
				, mc_name
				, barcode_1_mod
				, barcode_2_mod
				, seal
				, GETDATE()
				, create_by
				, GETDATE()
				, update_by
				FROM APCSProDB.trans.label_issue_records 
				where lot_no = @lot_no
		END
		ELSE
		BEGIN
			--print reel one reel new version
			update APCSProDB.trans.label_issue_records 
			set version = version + 1  
			where lot_no = @lot_no
			and type_of_label = @type_of_label
			and no_reel = @Reel_Num

			--insert data reprint on label his date modify : 2022/02/18 time : 15.30
			INSERT INTO APCSProDB.trans.[label_issue_records_hist] (
				  label_issue_id
				, recorded_at
				, record_class
				, operated_by
				, type_of_label
				, lot_no
				, customer_device
				, rohm_model_name
				, qty
				, barcode_lotno
				, tomson_box
				, tomson_3
				, box_type
				, barcode_bottom
				, mno_std
				, std_qty_before
				, mno_hasuu
				, hasuu_qty_before
				, no_reel
				, qrcode_detail
				, type_label_laterat
				, mno_std_laterat
				, mno_hasuu_laterat
				, barcode_device_detail
				, op_no
				, op_name
				, seq
				, ip_address
				, msl_label
				, floor_life
				, ppbt
				, re_comment
				, version
				, is_logo
				, mc_name
				, barcode_1_mod
				, barcode_2_mod
				, seal
				, create_at
				, create_by
				, update_at
				, update_by
				)
				SELECT 
				  id
				, GETDATE()
				, 1 --fix 1
				, operated_by
				, type_of_label
				, lot_no
				, customer_device
				, rohm_model_name
				, qty
				, barcode_lotno
				, tomson_box
				, tomson_3
				, box_type
				, barcode_bottom
				, mno_std
				, std_qty_before
				, mno_hasuu
				, hasuu_qty_before
				, no_reel
				, qrcode_detail
				, type_label_laterat
				, mno_std_laterat
				, mno_hasuu_laterat
				, barcode_device_detail
				, op_no
				, op_name
				, seq
				, ip_address
				, msl_label
				, floor_life
				, ppbt
				, re_comment
				, version 
				, is_logo
				, mc_name
				, barcode_1_mod
				, barcode_2_mod
				, seal
				, GETDATE()
				, create_by
				, GETDATE()
				, update_by
				FROM APCSProDB.trans.label_issue_records 
				where lot_no = @lot_no
				and type_of_label = @type_of_label
				and no_reel = @Reel_Num
		END
	END TRY
	BEGIN CATCH

		--Add Log Date : 2023/01/23 Time : 15.00
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		([record_at]
		  , [record_class]
		  , [login_name]
		  , [hostname]
		  , [appname]
		  , [command_text]
		  , [lot_no])
		SELECT GETDATE()
			,'4'
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			,'EXEC [dbo].[tg_sp_update_version_reprint_on_tp_cellcon update fail] @Lotno = ''' + @lot_no + ''', @type_of_label = ''' + CONVERT(VARCHAR(2),@type_of_label) + ''', @Reel_Num = ''' + CONVERT(VARCHAR(2),@Reel_Num) + ''''
			,@lot_no

		
		SELECT 'FALSE' AS Status ,'UPDATE REPRINT VERSION ERROR !!' AS Error_Message_ENG,N'ไม่เข้า function update version print count ' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END CATCH
END
