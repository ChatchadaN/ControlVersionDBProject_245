
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_Alot_V2]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10),
	@hasuu_lotno varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @MNo_hasuu char(10);
	DECLARE @Lot_Type char(1);

	--Add Parameter 2022/05/25 Time : 11.15
	DECLARE @datetime DATETIME
	DECLARE @year_now int = 0
	SET @datetime = GETDATE()
	SELECT @year_now = (FORMAT(@datetime,'yy') - 3)

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
	
	
	 select @Lot_Type = SUBSTRING(lot_no,5,1) from APCSProDB.trans.lots where lot_no = @hasuu_lotno

	IF @Lot_Type = 'A'
	BEGIN
		select @MNo_hasuu = MNo from  APCSProDB.method.allocat_temp where LotNo = @hasuu_lotno
	END
	ELSE  IF @Lot_Type = 'D' 
	BEGIN
		select @MNo_hasuu = 'MX'
	END
	ELSE 
	BEGIN
		select @MNo_hasuu = MNo from  APCSProDB.method.allocat_temp where LotNo = @hasuu_lotno
	END

	DECLARE @Check_Record_Allocat int = 0
	select @Check_Record_Allocat = COUNT(*) from [APCSProDB].[method].[allocat] where LotNo = @lotno

	IF @Check_Record_Allocat <> 0
	BEGIN
		SELECT top 1
		 (tranlot.lot_no) as Lotno_Standard
		,case when SUBSTRING(tranlot.lot_no,5,1) = 'F' then 'MX'
		 else allocat.MNo end as MNo_Standard
		, device_names.rank as Rack
		, tranlot.qty_pass as QTY_Lot_Standard
		, device_names.pcs_per_pack as Packing_Standerd_QTY
		, @MNo_hasuu as M_no_hasuu
		, [device_names].[assy_name]  
		, SUR.serial_no as Hasuu_Lotno_Hstock
		, SUR.pcs  as HASU_Stock_QTY
		,(tranlot.[qty_pass] + SUR.pcs) as Total
		, (tranlot.[qty_pass] + SUR.pcs)/(allocat.[Packing_Standerd_QTY]) as Reel
		, (tranlot.[qty_pass] + SUR.pcs)%(allocat.[Packing_Standerd_QTY])  as Totalhasuu
		, ([device_names].[pcs_per_pack]) * ((tranlot.[qty_pass]+ SUR.pcs)/([device_names].[pcs_per_pack]))  as Qty_Full_Reel_All
		, '01' as Stock_Class
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
		, allocat.Product_Control_Cl_1 as Product_Control_Clas
		, allocat.Product_Class
		, allocat.Production_Class
		, allocat.Rank_No
		, allocat.HINSYU_Class
		, allocat.Label_Class
		, allocat.OUT_OUT_FLAG
		, allocat.allocation_Date
		, device_names.name as DeviceTpRank
		from APCSProDB.trans.lots as tranlot
		LEFT join [APCSProDB].[method].[packages] on [packages].[id] = tranlot.[act_package_id]
		LEFT join [APCSProDB].[method].[device_names] on [device_names].[id] = tranlot.[act_device_name_id]
		INNER join [APCSProDB].[method].[allocat] as allocat on allocat.LotNo = @lotno
		inner join APCSProDB.trans.surpluses as SUR on SUR.serial_no = @hasuu_lotno
		where lot_no = @lotno
		and SUR.created_at >= (getdate() - 1095) 
		and (substring(lot_no COLLATE Latin1_General_CI_AS,0,3) >= 21)
		and lot_no COLLATE Latin1_General_CI_AS != SUR.serial_no
		order by SUR.serial_no Asc
	END
	ELSE
	BEGIN
		SELECT top 1
		 (tranlot.lot_no) as Lotno_Standard
		,case when SUBSTRING(tranlot.lot_no,5,1) = 'F' then 'MX'
		 else allocat.MNo end as MNo_Standard
		, device_names.rank as Rack
		, tranlot.qty_pass as QTY_Lot_Standard
		, device_names.pcs_per_pack as Packing_Standerd_QTY
		, @MNo_hasuu as M_no_hasuu
		, [device_names].[assy_name]  
		, SUR.serial_no as Hasuu_Lotno_Hstock
		, SUR.pcs  as HASU_Stock_QTY
		,(tranlot.[qty_pass] + SUR.pcs) as Total
		, (tranlot.[qty_pass] + SUR.pcs)/(allocat.[Packing_Standerd_QTY]) as Reel
		, (tranlot.[qty_pass] + SUR.pcs)%(allocat.[Packing_Standerd_QTY])  as Totalhasuu
		, ([device_names].[pcs_per_pack]) * ((tranlot.[qty_pass]+ SUR.pcs)/([device_names].[pcs_per_pack]))  as Qty_Full_Reel_All
		, '01' as Stock_Class
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
		, allocat.Product_Control_Cl_1 as Product_Control_Clas
		, allocat.Product_Class
		, allocat.Production_Class
		, allocat.Rank_No
		, allocat.HINSYU_Class
		, allocat.Label_Class
		, allocat.OUT_OUT_FLAG
		, allocat.allocation_Date
		, device_names.name as DeviceTpRank
		from APCSProDB.trans.lots as tranlot
		LEFT join [APCSProDB].[method].[packages] on [packages].[id] = tranlot.[act_package_id]
		LEFT join [APCSProDB].[method].[device_names] on [device_names].[id] = tranlot.[act_device_name_id]
		INNER join [APCSProDB].[method].[allocat_temp] as allocat on allocat.LotNo = @lotno
		inner join APCSProDB.trans.surpluses as SUR on SUR.serial_no = @hasuu_lotno
		where lot_no = @lotno
		and SUR.created_at >= (getdate() - 1095) 
		and (substring(lot_no COLLATE Latin1_General_CI_AS,0,3) >= 21)
		and lot_no COLLATE Latin1_General_CI_AS != SUR.serial_no
		order by SUR.serial_no Asc
	END

END
