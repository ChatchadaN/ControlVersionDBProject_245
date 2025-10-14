-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_label_history]
	-- Add the parameters for the stored procedure here
	 @lot_no varchar(10)
	,@type_label_drypack int = 0
	,@type_label_tomson int = 0
	--,@type_label_tray int = 0 --add parameter date : 2021/09/29
	,@Reel_number char(3) = ' '
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--DECLARE @Process_Code nvarchar(5);
	--select @Process_Code = PROCESS_POST_CODE from APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT where LOT_NO_2 = @lot_no

    -- Insert statements for procedure here
	IF @lot_no != ''
	BEGIN
		--Add Condition check work shipment all Date modify : 2022/02/09 time : 08.53
		IF @Reel_number = '0'
		BEGIN
			SELECT  
			   [recorded_at]
			  ,[operated_by]
			  ,[type_of_label]
			  ,[label_rec].[lot_no]
			  ,[customer_device]
			  ,[rohm_model_name]
			  --,[qty]
			  ,case when LEN(qty) = 5 then SUBSTRING(qty, 1, 2) + ',' + SUBSTRING(qty ,3,3)
			  when LEN(qty) = 4 then SUBSTRING(qty ,1,1) + ',' + SUBSTRING(qty ,2,3)
			  when LEN(qty) = 3 then TRIM(qty) --edit trim qty 2021/09/06
			  else  TRIM(qty) end
				As qty  
			  ,[barcode_lotno]
			  ,[tomson_box]
			  ,[tomson_3]
			  ,[box_type]
			  ,[barcode_bottom]
			  ,[mno_std]
			  ,[std_qty_before]
			  ,[mno_hasuu]
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
			  --,case when @Process_Code ! = '' then @Process_Code else sur.pdcd  end as PDCD --Edit 2021/08/24
			  ,sur.pdcd as PDCD  --Edit 2024/05/03 time : 10:46 by Aomsin
			  ,dn.assy_name as Assy_Name
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
			   FROM APCSProDB.trans.label_issue_records as label_rec
			   left join APCSProDB.trans.lots as lot on label_rec.lot_no = lot.lot_no
			   left join APCSProDB.trans.surpluses as sur on lot.id = sur.lot_id --chang lotno is lo_id Edit 2021/11/05 Time : 14.10
			   left join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
			   left join [DBxDW].[dbo].[device_condition_symbol] as symbo_lot on symbo_lot.lot_no = label_rec.lot_no
			   left join [DBxDW].[dbo].[device_condition_symbol] as symbo_device on symbo_lot.lot_no is null 
					and symbo_device.device_name = label_rec.rohm_model_name
					and symbo_device.lot_no = 'ALL'
			   where label_rec.lot_no = @lot_no and type_of_label in(@type_label_drypack,@type_label_tomson)
			   and type_of_label <> 0  --add condition cut data disable reel #2025/02/27 time : 09.05 by Aomsin
			   order by no_reel,type_of_label asc
		END
		ELSE
		BEGIN
			SELECT  
			   [recorded_at]
			  ,[operated_by]
			  ,[type_of_label]
			  ,[label_rec].[lot_no]
			  ,[customer_device]
			  ,[rohm_model_name]
			  --,[qty]
			  ,case when LEN(qty) = 5 then SUBSTRING(qty, 1, 2) + ',' + SUBSTRING(qty ,3,3)
			  when LEN(qty) = 4 then SUBSTRING(qty ,1,1) + ',' + SUBSTRING(qty ,2,3)
			  when LEN(qty) = 3 then TRIM(qty) --edit trim qty 2021/09/06
			  else  TRIM(qty) end
				As qty  
			  ,[barcode_lotno]
			  ,[tomson_box]
			  ,[tomson_3]
			  ,[box_type]
			  ,[barcode_bottom]
			  ,[mno_std]
			  ,[std_qty_before]
			  ,[mno_hasuu]
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
			  --,case when @Process_Code ! = '' then @Process_Code else sur.pdcd  end as PDCD --Edit 2021/08/24
			  ,sur.pdcd as PDCD  --Edit 2024/05/03 time : 10:46 by Aomsin
			  ,dn.assy_name as Assy_Name
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
			   FROM APCSProDB.trans.label_issue_records as label_rec
			   left join APCSProDB.trans.lots as lot on label_rec.lot_no = lot.lot_no
			   left join APCSProDB.trans.surpluses as sur on lot.id = sur.lot_id --chang lotno is lo_id Edit 2021/11/05 Time : 14.10
			   left join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
			   left join [DBxDW].[dbo].[device_condition_symbol] as symbo_lot on symbo_lot.lot_no = label_rec.lot_no
			   left join [DBxDW].[dbo].[device_condition_symbol] as symbo_device on symbo_lot.lot_no is null 
					and symbo_device.device_name = label_rec.rohm_model_name
					and symbo_device.lot_no = 'ALL'
			   where label_rec.lot_no = @lot_no and type_of_label in(@type_label_drypack,@type_label_tomson) and no_reel = @Reel_number
		END
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS Status ,'SELECT DATA ERROR !!' AS Error_Message_ENG,N'ไม่พบข้อมูลใน Label History' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END

END
