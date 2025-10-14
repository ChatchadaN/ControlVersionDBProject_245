-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_label_history_TP_testbass_ver_001]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10) = '2116A4451V' 
	, @type_label int = 0
	, @Reel_number char(1) = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @OUT_OUT_FLAG char(5) = ''
	DECLARE @OUT_OUT_FLAG_Value char(5) = ''
    -- Insert statements for procedure here
	
	select @OUT_OUT_FLAG = pdcd 
	from APCSProDB.trans.surpluses where serial_no = '2116A4451V' 

	IF @OUT_OUT_FLAG = 'QI000'
	BEGIN
		select @OUT_OUT_FLAG_Value = 'B'
	END
	ELSE IF @OUT_OUT_FLAG = 'QI001'
	BEGIN
		select @OUT_OUT_FLAG_Value = 'C'
	END



	IF @type_label = 0
	BEGIN
		SELECT DISTINCT [recorded_at]
			,[operated_by]
			,[type_of_label]
			,[label_issue_records].[lot_no]
			,[customer_device]
			,[rohm_model_name]
			,case when LEN(qty) = 5 then SUBSTRING(qty, 1, 2) + ',' + SUBSTRING(qty ,3,3)
			  when LEN(qty) = 4 then SUBSTRING(qty ,1,1) + ',' + SUBSTRING(qty ,2,3)
			  when LEN(qty) = 3 then qty
			  else  qty end
				As qty  
			,[barcode_lotno]
			,case when [tomson_box] = ' ' then ' '
				else 'T:'+ [tomson_box] end as tomson_box
			,[tomson_3]
			,case when [box_type] is null or[box_type] = ''  then ' '
				else 'C:'+ [box_type] end as box_type
			,[barcode_bottom]
			,[mno_std]
			,[std_qty_before]
			,case when hasuu_qty_before = '0' then '' else [mno_hasuu] end as mno_hasuu
			,[hasuu_qty_before]
			,[no_reel]
			,[qrcode_detail]
			,[type_label_laterat]
			,[mno_std_laterat]
			,[mno_hasuu_laterat]
			,[barcode_device_detail]
			,[op_no]
			,[op_name]
			,[seq]
			,[ip_address]
			,[msl_label] as MSL_LAVEL
			,[floor_life]
			,[ppbt]
			,[re_comment]
			,[version]
			,[is_logo]
			,[mc_name]
			,[barcode_1_mod]
			,[barcode_2_mod]
			,case when seal is null or seal = '' then ' ' else seal end as seal
			,[create_at]
			,[create_by]
			,[update_at]
			,[update_by]
			,@OUT_OUT_FLAG_Value as out_out_flag
			,case 
				when symbo_lot.lot_no is null then 
					case 
						when symbo_device.lot_no is null then 0
						else 1
					end
				else 
					case 
						when symbo_lot.device_name is null then 0
						else 1
					end
			end as [is_symbol]
		FROM APCSProDB.trans.label_issue_records
		left join [DBxDW].[dbo].[device_condition_symbol] as symbo_lot on symbo_lot.lot_no = label_issue_records.lot_no
		left join [DBxDW].[dbo].[device_condition_symbol] as symbo_device on symbo_lot.lot_no is null 
			and symbo_device.device_name = label_issue_records.rohm_model_name
			and symbo_device.lot_no = 'ALL'
		where label_issue_records.lot_no = '2116A4451V'  
			and type_of_label in(1,2,3)
			
	END
	ELSE
	BEGIN
		SELECT DISTINCT [recorded_at]
			,[operated_by]
			,[type_of_label]
			,[label_issue_records].[lot_no]
			,[customer_device]
			,[rohm_model_name]
			,case when LEN(qty) = 5 then SUBSTRING(qty, 1, 2) + ',' + SUBSTRING(qty ,3,3)
			  when LEN(qty) = 4 then SUBSTRING(qty ,1,1) + ',' + SUBSTRING(qty ,2,3)
			  when LEN(qty) = 3 then qty
			  else  qty  end
				As qty  
			,[barcode_lotno]
			,case when [tomson_box] = ' ' then ' '
				else 'T:'+ [tomson_box] end as tomson_box
			,[tomson_3]
			--,case when @lot_no = '2118A3207V' then N'⚫' + [tomson_3] else [tomson_3] end as tomson_3
			,case when [box_type] is null or[box_type] = ''  then ' '
				else 'C:'+ [box_type] end as box_type
			,[barcode_bottom]
			,[mno_std]
			,[std_qty_before]
			,case when hasuu_qty_before = '0' then '' else [mno_hasuu] end as mno_hasuu
			,[hasuu_qty_before]
			,[no_reel]
			,[qrcode_detail]
			,[type_label_laterat]
			,[mno_std_laterat]
			,[mno_hasuu_laterat]
			,[barcode_device_detail]
			,[op_no]
			,[op_name]
			,[seq]
			,[ip_address]
			,[msl_label] as MSL_LAVEL
			,[floor_life]
			,[ppbt]
			,[re_comment]
			,[version]
			,[is_logo]
			,[mc_name]
			,[barcode_1_mod]
			,[barcode_2_mod]
			,case when seal is null or seal = '' then ' ' else seal end as seal
			,[create_at]
			,[create_by]
			,[update_at]
			,[update_by]
			,@OUT_OUT_FLAG_Value as out_out_flag
			,case 
				when symbo_lot.lot_no is null then 
					case 
						when symbo_device.lot_no is null then 0
						else 1
					end
				else 
					case 
						when symbo_lot.device_name is null then 0
						else 1
					end
			end as [is_symbol]
		FROM APCSProDB.trans.label_issue_records
		left join [DBxDW].[dbo].[device_condition_symbol] as symbo_lot on symbo_lot.lot_no = label_issue_records.lot_no
		left join [DBxDW].[dbo].[device_condition_symbol] as symbo_device on symbo_lot.lot_no is null 
			and symbo_device.device_name = label_issue_records.rohm_model_name
			and symbo_device.lot_no = 'ALL'
		where label_issue_records.lot_no = '2116A4451V'  
			and type_of_label = @type_label
			and no_reel like (case when @type_label = 3 and @Reel_number != '' then @Reel_number else '%' end)
	END
		


END
