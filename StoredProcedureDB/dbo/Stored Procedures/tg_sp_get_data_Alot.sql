-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_Alot]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10),
	@hasuu_lotno varchar(10)


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
		,'EXEC [dbo].[tg_sp_get_data_Alot] @lotno = ''' + @lotno + ''',@hasuu_lotno = ''' + @hasuu_lotno + ''''


    -- Insert statements for procedure here
	SELECT top 1
	 (tranlot.lot_no) as Lotno_Standard
	,case when SUBSTRING(tranlot.lot_no,5,1) = 'F' then 'MX'
	 else denpyo.MNO2 end as MNo_Standard
	--, [packages].[name]  as package
	,H_STOCK.[Rank] as Rack
	, tranlot.qty_pass as QTY_Lot_Standard
	, H_STOCK.[Packing_Standerd_QTY]
	, H_STOCK.[MNo] as M_no_hasuu
	, [device_names].[assy_name]  
	, H_STOCK.[LotNo] as Hasuu_Lotno_Hstock
	, H_STOCK.[HASU_Stock_QTY]  as HASU_Stock_QTY
	,(tranlot.[qty_pass] + H_STOCK.[HASU_Stock_QTY]) as Total
	, (tranlot.[qty_pass] + H_STOCK.[HASU_Stock_QTY])/(allocat.[Packing_Standerd_QTY]) as Reel
	, (tranlot.[qty_pass] + H_STOCK.[HASU_Stock_QTY])%(allocat.[Packing_Standerd_QTY])  as Totalhasuu
	--, ([device_names].[pcs_per_pack]) * (tranlot.[qty_pass]/([device_names].[pcs_per_pack]))  as Qty_Full_Reel_All
	, ([device_names].[pcs_per_pack]) * ((tranlot.[qty_pass]+ H_STOCK.HASU_Stock_QTY)/([device_names].[pcs_per_pack]))  as Qty_Full_Reel_All
	, H_STOCK.Stock_Class
	, allocat.PDCD
	, allocat.Type_Name as package
	, allocat.ROHM_Model_Name
	, allocat.ASSY_Model_Name
	, allocat.R_Fukuoka_Model_Name
	, allocat.TIRank
	, allocat.TPRank
	, allocat.SUBRank
	, allocat.Mask
	, allocat.KNo
	, allocat.Tomson1 as Tomson_Mark_1
	, allocat.Tomson2 as Tomson_Mark_2
	, allocat.Tomson3 as Tomson_Mark_3
	, allocat.ORNo
	, allocat.WFLotNo
	, allocat.LotNo_Class
	, Product_Control_Clas
	, allocat.Product_Class
	, allocat.Production_Class
	, allocat.Rank_No
	, allocat.HINSYU_Class
	, allocat.Label_Class
	, allocat.OUT_OUT_FLAG
	, allocat.allocation_Date
	,trasecdata.ETC1 as DeviceTpRank
	from APCSProDB.trans.lots as tranlot
	LEFT join [APCSProDB].[method].[packages] on [packages].[id] = tranlot.[act_package_id]
	LEFT join [APCSProDB].[method].[device_names] on [device_names].[id] = tranlot.[act_device_name_id]
	LEFT join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo on denpyo.LOT_NO_1 = tranlot.lot_no 
	INNER join DBx.dbo.TransactionData as trasecdata on trasecdata.LotNo = tranlot.lot_no
	INNER join [StoredProcedureDB].[dbo].[IS_ALLOCAT] as allocat on allocat.LotNo = @lotno
	--left join OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;' ).[DBLSISHT].[dbo].[H_STOCK] as H_STOCK
	inner join [DBxDW].[TGOG].[Temp_H_STOCK] as H_STOCK on H_STOCK.LotNo = @hasuu_lotno
	--inner join [DBxDW].[TGOG].H_STOCK as H_STOCK on H_STOCK.LotNo = @hasuu_lotno
	where lot_no = @lotno
	and Derivery_Date  >= (getdate() - 1095)
	and lot_no COLLATE Latin1_General_CI_AS like '21%' 
	and lot_no COLLATE Latin1_General_CI_AS != H_STOCK.LotNo
	order by H_STOCK.LotNo Asc

END
