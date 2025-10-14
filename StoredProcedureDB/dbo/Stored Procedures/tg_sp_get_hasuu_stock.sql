-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_hasuu_stock]
	-- Add the parameters for the stored procedure here
	@get_data varchar(10),
	@package varchar(20) = '',
	@device varchar(20) = '',
	@rank varchar(5) = '',
	@tomson3 char(4) = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	 SET NOCOUNT ON;
	 DECLARE @HasuuStockMax char(10)
	 DECLARE @HasuuTotal char(10)

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
		,'EXEC [dbo].[tg_sp_get_hasuu_stock] @get_data = ''' + @get_data + ''',@package = ''' + @package + ''',@device = ''' + @device + ''',@rank = ''' + @rank + ''',@tomson3 = ''' + @tomson3 + ''''



	/****** Script for SelectTopNRows command from SSMS  ******/
	IF @get_data ='stock'
	BEGIN

	   SELECT 
        H_STOCK.[Type_Name] 
	   ,H_STOCK.[ROHM_Model_Name] as ASSY_Model_Name
	   ,H_STOCK.[Packing_Standerd_QTY] 
       ,H_STOCK.[TPRank] as Rank
	   ,SUM(HASU_Stock_QTY) as HASU_Stock_QTY
	   ,SUM(HASU_Stock_QTY)/(H_STOCK.Packing_Standerd_QTY) as TotalRell
	   ,COUNT(H_STOCK.LotNo) as QtyLot
	   ,SUM([HASU_Stock_QTY])%(H_STOCK.[Packing_Standerd_QTY]) as Hasuu_Total
	   ,'Rack1' as Rack_Location
	   ,[APCSProDB].[method].[package_groups].[name] as package_group_name
	   --,denpyo.TOMSON_INDICATION as Tomson3 --EDIT 2021/03/15 BY Aomsin
	   ,H_STOCK.Tomson_Mark_3 as Tomson3 --EDIT 2021/03/15 BY Aomsin
	   from DBxDW.TGOG.Temp_H_STOCK  as H_STOCK
	   INNER JOIN APCSProDB.method.packages on H_STOCK.Type_Name COLLATE Latin1_General_CI_AS = APCSProDB.method.packages.short_name COLLATE Latin1_General_CI_AS
	   INNER JOIN APCSProDB.method.package_groups on APCSProDB.method.packages.package_group_id  =  APCSProDB.method.package_groups.id 
	   INNER JOIN APCSProDB.trans.lots as tranlot on H_STOCK.LotNo COLLATE Latin1_General_CI_AS = tranlot.lot_no COLLATE Latin1_General_CI_AS --lot ใน hstock ต้องมีเหมือนกับใน tranlots
	   INNER JOIN APCSProDB.trans.surpluses AS SUR ON H_STOCK.LotNo COLLATE Latin1_General_CI_AS = SUR.serial_no COLLATE Latin1_General_CI_AS
	   --LEFT JOIN APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo ON tranlot.lot_no = denpyo.LOT_NO_4  --EDIT 2021/03/15 BY Aomsin
	   where DMY_OUT_Flag != '1'
	   and (SUR.location_id IS NOT NULL and SUR.location_id != 0)
	   and (tranlot.wip_state = '20' or tranlot.wip_state = '70' or tranlot.wip_state = '100')
	   and tranlot.quality_state = '0'
	   and Derivery_Date  >= (getdate() - 1095)
	   and SUBSTRING(H_STOCK.[LotNo],5,1) !='E' 
	   and SUBSTRING(H_STOCK.[LotNo],5,1) !='G' 
       GROUP BY H_STOCK.[Type_Name],H_STOCK.[ROHM_Model_Name],H_STOCK.[TPRank],H_STOCK.[Packing_Standerd_QTY],[APCSProDB].[method].[package_groups].[name],[H_STOCK].[Tomson_Mark_3] --[denpyo].[TOMSON_INDICATION]
	   Having SUM(HASU_Stock_QTY) >= H_STOCK.Packing_Standerd_QTY 
	   and SUM(HASU_Stock_QTY)/(NULLIF(H_STOCK.Packing_Standerd_QTY, 0)) >= 1
	   and SUM([HASU_Stock_QTY])%(H_STOCK.[Packing_Standerd_QTY]) < MAX(HASU_Stock_QTY) --เงื่อนไข hasuu_total < max_qty_hasuu_lot
	   ORDER BY HASU_Stock_QTY ASC

	   --------------------------------------- GET DATA Hasuu in Surpluses -----------------------------------------------------------------
		--select 
		-- pk_g.name as package_group_name
		--,pk.name as Package
		--,dv.name as Device
		--,dv.pcs_per_pack as Standard_Reel
		--,dv.tp_rank  
		--,SUM(sur.pcs) as HASU_Stock_QTY
		--,SUM(sur.pcs)/(dv.pcs_per_pack) as TotalRell
		--,COUNT(sur.serial_no) as QtyLot
		--,SUM(sur.pcs)%(dv.pcs_per_pack) as Hasuu_Total
		----,denpyo.TOMSON_INDICATION as Tomson3
		--,lb_his.tomson_3 as Tomson3
		--from APCSProDB.trans.surpluses as sur
		--inner join APCSProDB.trans.lots as lot on sur.lot_id = lot.id
		--inner join APCSProDB.method.device_names as dv on lot.act_device_name_id = dv.id
		--inner join APCSProDB.method.packages as pk on dv.package_id = pk.id
		--inner join APCSProDB.method.package_groups as pk_g on pk.package_group_id = pk_g.id
		----LEFT JOIN APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo ON sur.serial_no = denpyo.LOT_NO_4  --EDIT 2021/03/15 BY Aomsin
		--left join APCSProDB.trans.label_history as lb_his on sur.serial_no = lb_his.lot_no 
		--where sur.in_stock != 0 and type_of_label = '1'
		--and (sur.location_id IS NOT NULL and SUR.location_id != 0)
		--and (lot.wip_state = '20' or lot.wip_state = '70' or lot.wip_state = '100')
		--and lot.quality_state = '0'
		--and sur.updated_at  >= (getdate() - 1095)
		--and SUBSTRING(sur.serial_no,5,1) !='E' 
		--and SUBSTRING(sur.serial_no,5,1) !='G' 
		--GROUP BY pk.name,dv.name,dv.tp_rank,dv.pcs_per_pack,pk_g.name,lb_his.tomson_3--denpyo.TOMSON_INDICATION
		--Having SUM(sur.pcs) >= dv.pcs_per_pack 
		--and SUM(sur.pcs)/(NULLIF(dv.pcs_per_pack, 0)) >= 1
		--and SUM(sur.pcs)%(dv.pcs_per_pack) < MAX(sur.pcs) --เงื่อนไข hasuu_total < max_qty_hasuu_lot
		--ORDER BY HASU_Stock_QTY ASC

   END
   ElSE IF @get_data ='lot'
   BEGIN

		SELECT 
	    ROW_NUMBER() OVER(ORDER BY [H_STOCK].[LotNo] ASC) AS RowId 
	   ,[APCSProDB].[method].[package_groups].[name] as package_group_name
	   ,Stock_Class
	   ,H_STOCK.[LotNo] 
	   ,tranlot.lot_no as tranlot_lotno
	   ,HASU_Stock_QTY
	   ,HASU_Stock_QTY/H_STOCK.Packing_Standerd_QTY as Rell
	   ,H_STOCK.Packing_Standerd_QTY
	   ,tranlot.location_id
	   ,case when locat.name  is null then 'NoLocalion' else locat.name  end As Rack_Location_name
	   ,case when locat.address  is null then 'NoLocalion' else locat.address  end As Rack_Location_address
	   ,YEAR(H_STOCK.Timestamp_Date) as oldyear
	   ,YEAR(GETDATE()) as Currentyear
	   ,cast(YEAR(GETDATE()) as int) - CAST(YEAR(H_STOCK.Timestamp_Date) as int) as Overdueyear
	   --,denpyo.TOMSON_INDICATION AS Tomson3 --EDIT 2021/03/15 BY Aomsin
	   ,H_STOCK.Tomson_Mark_3 as Tomson3 --EDIT 2021/03/15 BY Aomsin
	   from DBxDW.TGOG.Temp_H_STOCK  as H_STOCK
	   inner join APCSProDB.method.packages on H_STOCK.Type_Name COLLATE Latin1_General_CI_AS = APCSProDB.method.packages.short_name COLLATE Latin1_General_CI_AS
	   inner join APCSProDB.method.package_groups on APCSProDB.method.packages.package_group_id =  APCSProDB.method.package_groups.id
	   LEFT join APCSProDB.trans.lots as tranlot on H_STOCK.LotNo COLLATE Latin1_General_CI_AS = tranlot.lot_no COLLATE Latin1_General_CI_AS
	   INNER JOIN APCSProDB.trans.surpluses AS SUR ON H_STOCK.LotNo COLLATE Latin1_General_CI_AS = SUR.serial_no COLLATE Latin1_General_CI_AS
	   LEFT join APCSProDB.trans.locations as locat on SUR.location_id = locat.id
	   --LEFT JOIN APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo ON tranlot.lot_no = denpyo.LOT_NO_4  --EDIT 2021/03/15 BY Aomsin
	   --LEFT join [StoredProcedureDB].[dbo].[IS_ALLOCAT] as allocat on allocat.LotNo = tranlot.lot_no
       WHERE [H_STOCK].[Type_Name] like @package and [H_STOCK].[ROHM_Model_Name] like @device and [H_STOCK].[TPRank] like @rank --and H_STOCK.Tomson_Mark_3 like @tomson3 --and allocat.Tomson3 like @tomson3
	   --and tranlot.location_id IS NOT NULL
	   and (SUR.location_id IS NOT NULL and SUR.location_id != 0)
	   and (tranlot.wip_state = '20' or tranlot.wip_state = '70' or tranlot.wip_state = '100')
	   and tranlot.quality_state = '0'
	   and DMY_OUT_Flag != '1' 
	   and Derivery_Date  >= (getdate() - 1095)
	   and HASU_Stock_QTY != '0'
	   and SUBSTRING(H_STOCK.[LotNo],5,1) !='E' 
	   and SUBSTRING(H_STOCK.[LotNo],5,1) !='G' 
	   ORDER BY HASU_Stock_QTY ASC

	   --------------------------------------- GET DATA Hasuu in Surpluses -----------------------------------------------------------------
	 --  SELECT 
	 --   ROW_NUMBER() OVER(ORDER BY sur.serial_no ASC) AS RowId 
	 --  ,pk_g.name as package_group_name
	 --  --,Stock_Class
	 --  ,sur.serial_no 
	 --  ,lot.lot_no as tranlot_lotno
	 --  ,sur.pcs as hasuu_stock_qty
	 --  ,sur.pcs/dv.pcs_per_pack as Rell
	 --  ,dv.pcs_per_pack
	 --  ,lot.location_id
	 --  ,case when locat.name  is null then 'NoLocalion' else locat.name  end As Rack_Location_name
	 --  ,case when locat.address  is null then 'NoLocalion' else locat.address  end As Rack_Location_address
	 --  ,YEAR(sur.updated_at) as oldyear
	 --  ,YEAR(GETDATE()) as Currentyear
	 --  ,cast(YEAR(GETDATE()) as int) - CAST(YEAR(sur.updated_at) as int) as Overdueyear
	 --  --,denpyo.TOMSON_INDICATION AS Tomson3 --EDIT 2021/03/15 BY Aomsin
	 --  --,H_STOCK.Tomson_Mark_3 as Tomson3 --EDIT 2021/03/15 BY Aomsin
	 --  from APCSProDB.trans.surpluses as sur
	 --   inner join APCSProDB.trans.lots as lot on sur.lot_id = lot.id
		--inner join APCSProDB.method.device_names as dv on lot.act_device_name_id = dv.id
		--inner join APCSProDB.method.packages as pk on dv.package_id = pk.id
		--inner join APCSProDB.method.package_groups as pk_g on pk.package_group_id = pk_g.id
	 --  LEFT join APCSProDB.trans.locations as locat on sur.location_id = locat.id
  --     WHERE pk.name like 'HSON-A8' and dv.name like 'BV1LB085HFS-CTR' and dv.tp_rank like 'TR' --and allocat.Tomson3 like @tomson3
	 --  and (SUR.location_id IS NOT NULL and SUR.location_id != 0)
	 --  and (lot.wip_state = '20' or lot.wip_state = '70' or lot.wip_state = '100')
	 --  and lot.quality_state = '0'
	 --  and sur.in_stock != '0' 
	 --  and sur.updated_at  >= (getdate() - 1095)
	 --  and sur.pcs != '0'
	 --  and SUBSTRING(sur.serial_no,5,1) !='E' 
	 --  and SUBSTRING(sur.serial_no,5,1) !='G' 
	 --  ORDER BY sur.serial_no ASC

   END

   IF @@ERROR <> 0
	GOTO ErrorHandler

	SET NOCOUNT OFF
	RETURN (0)
	ErrorHandler:
	RETURN (@@ERROR)

END
