-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [dbo].[tg_sp_get_lot_stock_V2_Backup20230411]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Process_Value char(20) = '' , @lot_id AS INT

	--update 2021/12/09 time : 11.47
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
		,'EXEC [dbo].[tg_sp_get_lot_stock_V2] @lotno = ''' + @lotno + ''''
		,@lotno
   
		select @lot_id = id from APCSProDB.trans.lots
		where lot_no = @lotno

		--Add Parameter Check Record in Allocat : 2022/11/17 time : 11.45
		DECLARE @Lotno_Allocat_Count Int = 0
		SELECT @Lotno_Allocat_Count = COUNT(*) FROM APCSProDB.method.allocat where LotNo = @lotno

		IF @Lotno_Allocat_Count != 0
		BEGIN
			SELECT top 1
			 allocat.LotNo as lot_no
			,tranlot.qty_pass 
			,case when TRIM(H_STOCK.serial_no)  is null then '-'
				  else TRIM(H_STOCK.serial_no)  end As Hasuu_LotNo 
			,case when H_STOCK.MNo is null then H_STOCK.MNo_his
				  else H_STOCK.MNo end As MNo_H_Stock
			,case when H_STOCK.pcs  is null then '-'
				  else H_STOCK.pcs  end As Hasuu_Qty 
			,Cast(YEAR(GETDATE()) as int) - Cast(YEAR(H_STOCK.created_at) as int) as Over_Year
			,allocat.Type_Name as Package
			,allocat.ROHM_Model_Name as Device
			,allocat.TIRank
			,allocat.rank
			,allocat.TPRank
			,allocat.SUBRank
			,allocat.PDCD
			,allocat.Mask
			,allocat.KNo
			,allocat.MNo as MNo_Standard
			,allocat.ORNo
			,case when allocat.Packing_Standerd_QTY is null then '-' 
				  else allocat.Packing_Standerd_QTY end  As Standerd_QTY
			,allocat.Tomson1
			,allocat.Tomson2
			,allocat.Tomson3
			,allocat.WFLotNo
			,allocat.LotNo_Class
			,allocat.User_Code
			,allocat.Product_Control_Cl_1
			,allocat.Product_Class
			,allocat.Production_Class
			,allocat.Rank_No
			,allocat.HINSYU_Class
			,allocat.Label_Class
			,allocat.OUT_OUT_FLAG
			,trasecdata.ETC1 as DeviceTpRank
			,case when tranlot.[qty_pass] + H_STOCK.pcs  is null then '-'
				  else tranlot.[qty_pass] + H_STOCK.pcs  end As Total 
			,case when (tranlot.[qty_pass] + H_STOCK.pcs)/(allocat.[Packing_Standerd_QTY])  is null then '-'
				  else (tranlot.[qty_pass] + H_STOCK.pcs)/(allocat.[Packing_Standerd_QTY])  end As Reel 
			,case when (tranlot.[qty_pass] + H_STOCK.pcs)/(allocat.[Packing_Standerd_QTY])  is null then '-'
				  else (tranlot.[qty_pass] + H_STOCK.pcs)%(allocat.[Packing_Standerd_QTY])  end As TotalHasuu
			,rao.order_no As OrderNo
			,case when (H_STOCK.location_name) is null then 'nolocation'
				  else(H_STOCK.location_name) end As location_name
			,case when  (H_STOCK.location_address) is null then 'noaddress'
				  else(H_STOCK.location_address) end As location_address
			FROM APCSProDB.method.allocat as allocat
			inner join APCSProDB.trans.lots as tranlot on tranlot.lot_no = allocat.LotNo
			inner join DBx.dbo.TransactionData as trasecdata on trasecdata.LotNo = tranlot.lot_no
			left join [APCSProDB].[robin].[assy_orders] as rao on rao.id = tranlot.order_id
					left join (select SUR.*
					,locations.name As location_name
					,locations.address As location_address
					,tl.wip_state
					,dn.name as ROHM_Model_Name
					,case when dn.rank is null or dn.rank = '' then '' else dn.rank end as Rank_dn
					,denpyo.TOMSON_INDICATION as Tomson_Mark_3
					,denpyo.MNO4 as MNo
					,label_his.tomson_3 as Tomson_3_his
					,label_his.mno_std as MNo_his
					from APCSProDB.trans.surpluses as SUR
					LEFT JOIN APCSProDB.trans.lots as tl on  tl.lot_no COLLATE Latin1_General_CI_AS = SUR.serial_no COLLATE Latin1_General_CI_AS
					LEFT JOIN APCSProDB.trans.locations as locations on SUR.location_id = locations.id
					LEFT JOIN APCSProDB.method.device_names as dn on tl.act_device_name_id = dn.id
					LEFT JOIN APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo on tl.lot_no = denpyo.LOT_NO_2
					LEFT JOIN APCSProDB.trans.label_issue_records as label_his on SUR.serial_no = label_his.lot_no
					where (SUBSTRING(serial_no, 5, 1) = 'A' 
						or SUBSTRING(serial_no, 5, 1) = 'B' 
						or SUBSTRING(serial_no, 5, 1) = 'F'
						or (SUBSTRING(serial_no, 5, 1) = 'G' or dn.name in ('BV2HC045EFU-C       ','BV2HD045EFU-CE2     ','BV2HD070EFU-CE2    ','BV2HC045EFU-CE2     '))  --add 2023/03/24 time : 11.56
					)
					and (SUR.location_id IS NOT NULL and SUR.location_id != 0)
					and (tl.wip_state = '20' or tl.wip_state = '70' or tl.wip_state = '100')
					and tl.quality_state ='0'
					and SUR.in_stock = '2') As H_STOCK 
					on H_STOCK.ROHM_Model_Name COLLATE Latin1_General_CI_AS = allocat.ROHM_Model_Name COLLATE Latin1_General_CI_AS
					and allocat.Rank COLLATE Latin1_General_CI_AS = H_STOCK.Rank_dn COLLATE Latin1_General_CI_AS
					and ( allocat.Tomson3 COLLATE Latin1_General_CI_AS = H_STOCK.Tomson_Mark_3 COLLATE Latin1_General_CI_AS
					or allocat.Tomson3 COLLATE Latin1_General_CI_AS = H_STOCK.Tomson_3_his COLLATE Latin1_General_CI_AS )
			where tranlot.id = @lot_id	
			and H_STOCK.created_at  >= (getdate() - 1095)
			and (substring(allocat.LotNo COLLATE Latin1_General_CI_AS,0,3) >= 21)
			and allocat.LotNo COLLATE Latin1_General_CI_AS != H_STOCK.serial_no --lot ใน Allocat ต้อง ไม่มีอยู่ใน Surpluses
			order by H_STOCK.serial_no Asc
		END
		ELSE
		BEGIN
			SELECT top 1
			 allocat.LotNo as lot_no
			,tranlot.qty_pass 
			,case when TRIM(H_STOCK.serial_no)  is null then '-'
				  else TRIM(H_STOCK.serial_no)  end As Hasuu_LotNo 
			,case when H_STOCK.MNo is null then H_STOCK.MNo_his
				  else H_STOCK.MNo end As MNo_H_Stock
			,case when H_STOCK.pcs  is null then '-'
				  else H_STOCK.pcs  end As Hasuu_Qty 
			,Cast(YEAR(GETDATE()) as int) - Cast(YEAR(H_STOCK.created_at) as int) as Over_Year
			,allocat.Type_Name as Package
			,allocat.ROHM_Model_Name as Device
			,allocat.TIRank
			,allocat.rank
			,allocat.TPRank
			,allocat.SUBRank
			,allocat.PDCD
			,allocat.Mask
			,allocat.KNo
			,allocat.MNo as MNo_Standard
			,allocat.ORNo
			,case when allocat.Packing_Standerd_QTY is null then '-' 
				  else allocat.Packing_Standerd_QTY end  As Standerd_QTY
			,allocat.Tomson1
			,allocat.Tomson2
			,allocat.Tomson3
			,allocat.WFLotNo
			,allocat.LotNo_Class
			,allocat.User_Code
			,allocat.Product_Control_Cl_1
			,allocat.Product_Class
			,allocat.Production_Class
			,allocat.Rank_No
			,allocat.HINSYU_Class
			,allocat.Label_Class
			,allocat.OUT_OUT_FLAG
			,trasecdata.ETC1 as DeviceTpRank
			,case when tranlot.[qty_pass] + H_STOCK.pcs  is null then '-'
				  else tranlot.[qty_pass] + H_STOCK.pcs  end As Total 
			,case when (tranlot.[qty_pass] + H_STOCK.pcs)/(allocat.[Packing_Standerd_QTY])  is null then '-'
				  else (tranlot.[qty_pass] + H_STOCK.pcs)/(allocat.[Packing_Standerd_QTY])  end As Reel 
			,case when (tranlot.[qty_pass] + H_STOCK.pcs)/(allocat.[Packing_Standerd_QTY])  is null then '-'
				  else (tranlot.[qty_pass] + H_STOCK.pcs)%(allocat.[Packing_Standerd_QTY])  end As TotalHasuu
			,rao.order_no As OrderNo
			,case when (H_STOCK.location_name) is null then 'nolocation'
				  else(H_STOCK.location_name) end As location_name
			,case when  (H_STOCK.location_address) is null then 'noaddress'
				  else(H_STOCK.location_address) end As location_address
			FROM APCSProDB.method.allocat_temp as allocat
			inner join APCSProDB.trans.lots as tranlot on tranlot.lot_no = allocat.LotNo
			inner join DBx.dbo.TransactionData as trasecdata on trasecdata.LotNo = tranlot.lot_no
			left join [APCSProDB].[robin].[assy_orders] as rao on rao.id = tranlot.order_id
					left join (select SUR.*
					,locations.name As location_name
					,locations.address As location_address
					,tl.wip_state
					,dn.name as ROHM_Model_Name
					,case when dn.rank is null or dn.rank = '' then '' else dn.rank end as Rank_dn
					,denpyo.TOMSON_INDICATION as Tomson_Mark_3
					,denpyo.MNO4 as MNo
					,label_his.tomson_3 as Tomson_3_his
					,label_his.mno_std as MNo_his
					from APCSProDB.trans.surpluses as SUR
					LEFT JOIN APCSProDB.trans.lots as tl on  tl.lot_no COLLATE Latin1_General_CI_AS = SUR.serial_no COLLATE Latin1_General_CI_AS
					LEFT JOIN APCSProDB.trans.locations as locations on SUR.location_id = locations.id
					LEFT JOIN APCSProDB.method.device_names as dn on tl.act_device_name_id = dn.id
					LEFT JOIN APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo on tl.lot_no = denpyo.LOT_NO_2
					LEFT JOIN APCSProDB.trans.label_issue_records as label_his on SUR.serial_no = label_his.lot_no
					where (SUBSTRING(serial_no, 5, 1) = 'A' 
						or SUBSTRING(serial_no, 5, 1) = 'B' 
						or SUBSTRING(serial_no, 5, 1) = 'F'
						or (SUBSTRING(serial_no, 5, 1) = 'G' or dn.name in ('BV2HC045EFU-C       ','BV2HD045EFU-CE2     ','BV2HD070EFU-CE2    ','BV2HC045EFU-CE2     ')) --add 2023/03/24 time : 11.56
					)
					and (SUR.location_id IS NOT NULL and SUR.location_id != 0)
					and (tl.wip_state = '20' or tl.wip_state = '70' or tl.wip_state = '100')
					and tl.quality_state ='0'
					and SUR.in_stock = '2') As H_STOCK 
					on H_STOCK.ROHM_Model_Name COLLATE Latin1_General_CI_AS = allocat.ROHM_Model_Name COLLATE Latin1_General_CI_AS
					and allocat.Rank COLLATE Latin1_General_CI_AS = H_STOCK.Rank_dn COLLATE Latin1_General_CI_AS
					and ( allocat.Tomson3 COLLATE Latin1_General_CI_AS = H_STOCK.Tomson_Mark_3 COLLATE Latin1_General_CI_AS
					or allocat.Tomson3 COLLATE Latin1_General_CI_AS = H_STOCK.Tomson_3_his COLLATE Latin1_General_CI_AS )
			where tranlot.id = @lot_id	
			and H_STOCK.created_at  >= (getdate() - 1095)
			and (substring(allocat.LotNo COLLATE Latin1_General_CI_AS,0,3) >= 21)
			and allocat.LotNo COLLATE Latin1_General_CI_AS != H_STOCK.serial_no --lot ใน Allocat ต้อง ไม่มีอยู่ใน Surpluses
			order by H_STOCK.serial_no Asc
		END
END
