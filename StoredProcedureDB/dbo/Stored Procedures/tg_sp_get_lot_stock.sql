-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_lot_stock]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
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
		,'EXEC [dbo].[tg_sp_get_lot_stock] @lotno = ''' + @lotno + ''''


    -- Insert statements for procedure here

			SELECT top 1
			 allocat.LotNo as lot_no
			,tranlot.qty_pass 
			,case when H_STOCK.[LotNo]  is null then '-'
				  else H_STOCK.[LotNo]  end As Hasuu_LotNo 
			,case when H_STOCK.MNo is null then '-' 
				  else H_STOCK.MNo end As MNo_H_Stock
			,case when H_STOCK.[HASU_Stock_QTY]  is null then '-'
				  else H_STOCK.[HASU_Stock_QTY]  end As Hasuu_Qty 
			,Cast(YEAR(GETDATE()) as int) - Cast(YEAR(H_STOCK.Timestamp_Date) as int) as Over_Year
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
			--,H_STOCK.Type_Name as HPackage
			--,H_STOCK.ROHM_Model_Name as HDevice
			--,H_STOCK.TPRank as HTPRank
			--,H_STOCK.Timestamp_Date as Dates_Hasuu
			,case when tranlot.[qty_pass] + H_STOCK.[HASU_Stock_QTY]  is null then '-'
				  else tranlot.[qty_pass] + H_STOCK.[HASU_Stock_QTY]  end As Total 
			,case when (tranlot.[qty_pass] + H_STOCK.[HASU_Stock_QTY])/(allocat.[Packing_Standerd_QTY])  is null then '-'
				  else (tranlot.[qty_pass] + H_STOCK.[HASU_Stock_QTY])/(allocat.[Packing_Standerd_QTY])  end As Reel 
			,case when (tranlot.[qty_pass] + H_STOCK.[HASU_Stock_QTY])/(allocat.[Packing_Standerd_QTY])  is null then '-'
				  else (tranlot.[qty_pass] + H_STOCK.[HASU_Stock_QTY])%(allocat.[Packing_Standerd_QTY])  end As TotalHasuu
			,rao.order_no As OrderNo
			,case when (H_STOCK.location_name) is null then 'nolocation'
				  else(H_STOCK.location_name) end As location_name
			,case when  (H_STOCK.location_address) is null then 'noaddress'
				  else(H_STOCK.location_address) end As location_address
			--,'-' as location_name
			--,'-' as location_address
			FROM [StoredProcedureDB].[dbo].[IS_ALLOCAT] as allocat
			inner join APCSProDB.trans.lots as tranlot on tranlot.lot_no = allocat.LotNo
			inner join DBx.dbo.TransactionData as trasecdata on trasecdata.LotNo = tranlot.lot_no
			left join [APCSProDB].[robin].[assy_orders] as rao on rao.id = tranlot.order_id
					left join (select hasuustock.*,tl.location_id
					,locations.name As location_name
					,locations.address As location_address
					,tl.wip_state 
					from [DBxDW].[TGOG].[Temp_H_STOCK] as hasuustock
					--from [DBxDW].[TGOG].H_STOCK as hasuustock
					LEFT JOIN APCSProDB.trans.surpluses AS SUR ON hasuustock.LotNo COLLATE Latin1_General_CI_AS = SUR.serial_no COLLATE Latin1_General_CI_AS
					LEFT JOIN APCSProDB.trans.lots as tl on  tl.lot_no COLLATE Latin1_General_CI_AS = hasuustock.LotNo COLLATE Latin1_General_CI_AS
					LEFT join APCSProDB.trans.locations as locations on SUR.location_id = locations.id
					--LEFT join APCSProDB.trans.locations as locations on tl.location_id = locations.id
					where (SUBSTRING([LotNo], 5, 1) = 'A' 
					or SUBSTRING([LotNo], 5, 1) = 'B' 
					or SUBSTRING([LotNo], 5, 1) = 'D' 
					or SUBSTRING([LotNo], 5, 1) = 'F')
					and (SUR.location_id IS NOT NULL and SUR.location_id != 0)
					and (tl.wip_state = '20' or tl.wip_state = '70' or tl.wip_state = '100')
					and tl.quality_state ='0'
					and hasuustock.DMY_OUT_Flag != '1') as H_STOCK 
					on H_STOCK.ROHM_Model_Name COLLATE Latin1_General_CI_AS = allocat.ROHM_Model_Name COLLATE Latin1_General_CI_AS
					--and allocat.TIRank COLLATE Latin1_General_CI_AS = H_STOCK.TIRank COLLATE Latin1_General_CI_AS
					and allocat.TPRank COLLATE Latin1_General_CI_AS = H_STOCK.TPRank COLLATE Latin1_General_CI_AS
					--and allocat.PDCD COLLATE Latin1_General_CI_AS = H_STOCK.PDCD COLLATE Latin1_General_CI_AS
					and allocat.Tomson3 COLLATE Latin1_General_CI_AS = H_STOCK.Tomson_Mark_3 COLLATE Latin1_General_CI_AS
			where  allocat.LotNo = @lotno
			and Derivery_Date  >= (getdate() - 1095)
			and allocat.LotNo COLLATE Latin1_General_CI_AS like '21%' 
			and allocat.LotNo COLLATE Latin1_General_CI_AS != H_STOCK.LotNo --lot ใน tranlot ต้อง ไม่มีอยู่ใน H_stock
			order by H_STOCK.LotNo Asc

END

