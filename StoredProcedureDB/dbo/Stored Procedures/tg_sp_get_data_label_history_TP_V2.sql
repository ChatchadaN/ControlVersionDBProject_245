-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_label_history_TP_V2]
	-- Add the parameters for the stored procedure here
	 @lot_no varchar(10)
	,@type_label int = 0
	,@Reel_0 char(2) = ''
	,@Reel_1 char(2) = ''
	,@Reel_2 char(2) = ''
	,@Reel_3 char(2) = ''
	,@Reel_4 char(2) = ''
	,@Reel_5 char(2) = ''
	,@Reel_6 char(2) = ''
	,@Reel_7 char(2) = ''
	,@Reel_8 char(2) = ''
	,@Reel_9 char(2) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	--Last updaty by aun 2022/06/04
	IF @type_label = 0
	BEGIN
		IF @Reel_0 = '0'
		BEGIN
		SELECT * FROM (
			SELECT DISTINCT [id], [recorded_at]
				,[operated_by]
				,[type_of_label]
				,[label_issue_records].[lot_no]
				,[customer_device]
				,[rohm_model_name]
				,case when LEN(qty) = 5 then SUBSTRING(qty, 1, 2) + ',' + SUBSTRING(qty ,3,3)
				  when LEN(qty) = 4 then SUBSTRING(qty ,1,1) + ',' + SUBSTRING(qty ,2,3)
				  when LEN(qty) = 3 then TRIM(qty)
				  else TRIM(qty) end
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
			where label_issue_records.lot_no = @lot_no 
			and type_of_label in(1,2,3)
			) AS TB
			order by id asc
		END
		ELSE
		BEGIN
		SELECT * FROM (
			SELECT DISTINCT [id], [recorded_at]
			,[operated_by]
			,[type_of_label]
			,[label_issue_records].[lot_no]
			,[customer_device]
			,[rohm_model_name]
			,case when LEN(qty) = 5 then SUBSTRING(qty, 1, 2) + ',' + SUBSTRING(qty ,3,3)
			  when LEN(qty) = 4 then SUBSTRING(qty ,1,1) + ',' + SUBSTRING(qty ,2,3)
			  when LEN(qty) = 3 then TRIM(qty)
			  else  TRIM(qty) end
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
		where label_issue_records.lot_no = @lot_no 
			and type_of_label in(1,2,3)
		) AS TB
		order by id asc

		END
	END
	ELSE
	BEGIN
		IF @Reel_0 = '0'
		BEGIN
		SELECT * FROM (
			SELECT DISTINCT [id], [recorded_at]
			,[operated_by]
			,[type_of_label]
			,[label_issue_records].[lot_no]
			,[customer_device]
			,[rohm_model_name]
			,case when LEN(qty) = 5 then SUBSTRING(qty, 1, 2) + ',' + SUBSTRING(qty ,3,3)
			  when LEN(qty) = 4 then SUBSTRING(qty ,1,1) + ',' + SUBSTRING(qty ,2,3)
			  when LEN(qty) = 3 then TRIM(qty)
			  else TRIM(qty)  end
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
		where label_issue_records.lot_no = @lot_no 
			and type_of_label = @type_label
			) AS TB
			order by id asc
			
		END
		ELSE
		BEGIN
		SELECT * FROM (
			SELECT DISTINCT [id], [recorded_at]
				,[operated_by]
				,[type_of_label]
				,[label_issue_records].[lot_no]
				,[customer_device]
				,[rohm_model_name]
				,case when LEN(qty) = 5 then SUBSTRING(qty, 1, 2) + ',' + SUBSTRING(qty ,3,3)
				  when LEN(qty) = 4 then SUBSTRING(qty ,1,1) + ',' + SUBSTRING(qty ,2,3)
				  when LEN(qty) = 3 then TRIM(qty)
				  else TRIM(qty)  end
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
			where label_issue_records.lot_no = @lot_no 
				and type_of_label = @type_label
				and no_reel in (@Reel_0,@Reel_1,@Reel_2,@Reel_3,@Reel_4,@Reel_5,@Reel_6,@Reel_7,@Reel_8,@Reel_9)
				) AS TB
			order by id asc
		END
			
	END

END
