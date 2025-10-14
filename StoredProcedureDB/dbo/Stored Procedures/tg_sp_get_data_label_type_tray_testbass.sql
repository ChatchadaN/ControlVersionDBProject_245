-- =============================================
-- Author:		<Author,,Vanatjaya S. 009131 and Kittithat P. 009670>
-- Create date: <Create Date,2021/09/29,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_label_type_tray_testbass]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
	,@type_label int = 0
	,@tomson_num int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @type_label = 5
	BEGIN
		SELECT [recorded_at]
			, [operated_by]
			, [type_of_label]
			, [label_rec].[lot_no]
			, [customer_device]
			, [rohm_model_name] 
			, FORMAT(CONVERT(int,qty),'#,0') as [qty]
			, [barcode_lotno]
			, [tomson_box]
			, [tomson_3]
			, [box_type]
			, [barcode_bottom]
			, [mno_std]
			, [std_qty_before]
			, [mno_hasuu]
			, [hasuu_qty_before]
			, [no_reel]
			, [qrcode_detail]
			, [type_label_laterat]
			, [mno_std_laterat]
			, [mno_hasuu_laterat]
			, [barcode_device_detail]
			, [op_no]
			, [op_name]
			, [seq]
			, [ip_address]
			, [msl_label] as MSL_LAVEL
			, [floor_life]
			, [ppbt]
			, [re_comment]
			, [version]
			, [is_logo]
			, [mc_name]
			, [barcode_1_mod]
			, [barcode_2_mod]
			, ISNULL(NULLIF(seal, ' '), ' ') as seal
			, [create_at]
			, [create_by]
			, [update_at]
			, [update_by]
			, ISNULL(NULLIF(sur.pdcd, ' '), ' ') as PDCD
			, dn.assy_name as Assy_Name
			, case 
				when symbo_lot.lot_no is null then 
					case 
						when symbo_device.lot_no is null then 0
						else 1
					end
				else 1
			end as [is_symbol]
		FROM APCSProDB.trans.label_issue_records as label_rec WITH (NOLOCK)
		left join APCSProDB.trans.lots as lot WITH (NOLOCK) on label_rec.lot_no = lot.lot_no
		left join APCSProDB.trans.surpluses as sur WITH (NOLOCK) on lot.lot_no = sur.serial_no
		left join APCSProDB.method.device_names as dn  WITH (NOLOCK) on lot.act_device_name_id = dn.id
		left join [DBxDW].[dbo].[device_condition_symbol] as symbo_lot on symbo_lot.lot_no = label_rec.lot_no
		left join [DBxDW].[dbo].[device_condition_symbol] as symbo_device on symbo_lot.lot_no is null 
			and symbo_device.device_name = label_rec.rohm_model_name
			and symbo_device.lot_no = 'ALL'
		where label_rec.lot_no = @lotno and type_of_label = @type_label and no_reel = @tomson_num
		order by type_of_label desc,no_reel asc
	END
	ELSE IF @type_label = 6
	BEGIN
		SELECT [recorded_at]
			, [operated_by]
			, [type_of_label]
			, [label_rec].[lot_no]
			, [customer_device]
			, [rohm_model_name] 
			, FORMAT(CONVERT(int,qty),'#,0') as [qty]
			, [barcode_lotno]
			, [tomson_box]
			, [tomson_3]
			, [box_type]
			, [barcode_bottom]
			, [mno_std]
			, [std_qty_before]
			, [mno_hasuu]
			, [hasuu_qty_before]
			, [no_reel]
			, [qrcode_detail]
			, [type_label_laterat]
			, [mno_std_laterat]
			, [mno_hasuu_laterat]
			, [barcode_device_detail]
			, [op_no]
			, [op_name]
			, [seq]
			, [ip_address]
			, [msl_label] as MSL_LAVEL
			, [floor_life]
			, [ppbt]
			, [re_comment]
			, [version]
			, [is_logo]
			, [mc_name]
			, [barcode_1_mod]
			, [barcode_2_mod]
			, ISNULL(NULLIF(seal, ' '), ' ') as seal
			, [create_at]
			, [create_by]
			, [update_at]
			, [update_by]
			, ISNULL(NULLIF(sur.pdcd, ' '), ' ') as PDCD
			, dn.assy_name as Assy_Name
			, case 
				when symbo_lot.lot_no is null then 
					case 
						when symbo_device.lot_no is null then 0
						else 1
					end
				else 1
			end as [is_symbol]
		FROM APCSProDB.trans.label_issue_records as label_rec WITH (NOLOCK)
		left join APCSProDB.trans.lots as lot WITH (NOLOCK) on label_rec.lot_no = lot.lot_no
		left join APCSProDB.trans.surpluses as sur WITH (NOLOCK) on lot.lot_no = sur.serial_no
		left join APCSProDB.method.device_names as dn  WITH (NOLOCK) on lot.act_device_name_id = dn.id
		left join [DBxDW].[dbo].[device_condition_symbol] as symbo_lot on symbo_lot.lot_no = label_rec.lot_no
		left join [DBxDW].[dbo].[device_condition_symbol] as symbo_device on symbo_lot.lot_no is null 
			and symbo_device.device_name = label_rec.rohm_model_name
			and symbo_device.lot_no = 'ALL'
		where label_rec.lot_no = @lotno and type_of_label = @type_label and seq = @tomson_num
		order by type_of_label desc,no_reel asc
	END

	

END
