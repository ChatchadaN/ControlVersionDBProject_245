-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_hasuu_stock_pro] 
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

	--Add Parameter 2022/05/25 Time : 11.05
	DECLARE @datetime DATETIME
	DECLARE @year_now int = 0
	SET @datetime = GETDATE()
	SELECT @year_now = (FORMAT(@datetime,'yy') - 3)

    -- Insert statements for procedure here
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
		,'EXEC [dbo].[tg_sp_get_hasuu_stock_pro] @get_data = ''' + @get_data + ''',@package = ''' + @package + ''',@device = ''' + @device + ''',@rank = ''' + @rank + ''',@tomson3 = ''' + @tomson3 + ''''

	IF @get_data ='stock'
	BEGIN

		SELECT pk.short_name as Type_Name
			, dv.name as ASSY_Model_Name 
			, dv.pcs_per_pack as Packing_Standerd_QTY
			, dv.rank_value as Rank
			, SUM(sur.pcs) as HASU_Stock_QTY
			, SUM(sur.pcs)/(dv.pcs_per_pack) as TotalRell
			, COUNT(sur.serial_no) as QtyLot
			, SUM(sur.pcs)%(dv.pcs_per_pack) as Hasuu_Total
			, pk_g.name as package_group_name
			, sur.qc_instruction as Tomson3
	   from APCSProDB.trans.surpluses as sur
	   inner join APCSProDB.trans.lots as lot on sur.lot_id = lot.id
	   inner join (
			select case when dv1.rank is null then '' else dv1.rank end As rank_value,* 
			from APCSProDB.method.device_names as dv1
	   ) as dv on lot.act_device_name_id = dv.id
	   inner join APCSProDB.method.packages as pk on dv.package_id = pk.id
	   inner join APCSProDB.method.package_groups as pk_g on pk.package_group_id = pk_g.id
	   left join APCSProDB.trans.locations as locat on sur.location_id = locat.id
       WHERE (SUR.location_id IS NOT NULL and SUR.location_id != 0)
			and (lot.wip_state = 20 or lot.wip_state = 70 or lot.wip_state = 100)
			and lot.quality_state = 0
			and sur.in_stock = 2 
			--and sur.updated_at  >= (getdate() - 1095)  -- old patthen close 2022/05/25 Time : 11.10
			-- Add Condition is_ability = 1 สำหรับงาน hasuu long standing (เกิน 3 ปี) re-test กลับมาใช้งานได้ create date time : 2022/06/24 time 09.41
			and (SUBSTRING(sur.serial_no,1,2) >= @year_now or sur.is_ability = 1) --Change Patthen Condition 2022/05/25 Time : 11.10
			and sur.pcs != 0
			and SUBSTRING(sur.serial_no,5,1) !='E' 
			--and SUBSTRING(sur.serial_no,5,1) !='G' 
			and (SUBSTRING(sur.serial_no,5,1) !='G'  --allow device for G lot type do mixing (support claim) 2023/03/15 time : 10.55  //--add device support g-lot test BD1020HFV-TR        2025/02/13 time : 09.37 by Aomsin
				or (SUBSTRING(serial_no,5,1) = 'G' and dv.name in ('SV013-HE2           ','SV131-HE2           ','SV014-HE2           ','SV010-HE2           ','BV2HC045EFU-C       ','BV2HD045EFU-CE2     ','BV2HD070EFU-CE2    ','BV2HC045EFU-CE2     ','BD1020HFV-TR        ')) 
				) --Aomsin บอกให้ใส่ 3device ด่วน 2024/02/24 SV131-HE2,SV014-HE2,SV010-HE2
	   GROUP BY pk.short_name,dv.name,dv.rank_value,dv.pcs_per_pack,pk_g.name,sur.qc_instruction
	   Having SUM(sur.pcs) >= dv.pcs_per_pack 
			and SUM(sur.pcs)/(NULLIF(dv.pcs_per_pack, 0)) >= 1

	END
	ElSE IF @get_data ='lot'
	BEGIN

		SELECT 
	    ROW_NUMBER() OVER(ORDER BY sur.serial_no ASC) AS RowId 
	   ,pk_g.name as package_group_name
	   ,Trim(sur.serial_no) as LotNo
	   ,Trim(lot.lot_no) as tranlot_lotno
	   ,sur.pcs as HASU_Stock_QTY
	   ,sur.pcs/dv.pcs_per_pack as Rell
	   ,dv.pcs_per_pack as Packing_Standerd_QTY
	   ,lot.location_id
	   ,case when locat.name  is null then 'NoLocalion' else locat.name  end As Rack_Location_name
	   ,case when locat.address  is null then 'NoLocalion' else locat.address  end As Rack_Location_address
	   ,YEAR(sur.updated_at) as oldyear
	   ,YEAR(GETDATE()) as Currentyear
	   ,cast(YEAR(GETDATE()) as int) - CAST(YEAR(sur.updated_at) as int) as Overdueyear
	   ,sur.qc_instruction as Tomson3 --EDIT 2021/07/13 BY Aomsin
	   from APCSProDB.trans.surpluses as sur
	   inner join APCSProDB.trans.lots as lot on sur.lot_id = lot.id
	    inner join (select case when dv1.rank is null then '' else dv1.rank end As rank_value,* 
		from APCSProDB.method.device_names as dv1) as dv on lot.act_device_name_id = dv.id
		inner join APCSProDB.method.packages as pk on dv.package_id = pk.id
		inner join APCSProDB.method.package_groups as pk_g on pk.package_group_id = pk_g.id
	   LEFT join APCSProDB.trans.locations as locat on sur.location_id = locat.id
       WHERE pk.short_name like @package and dv.name like @device and dv.rank_value like @rank  and sur.qc_instruction like @tomson3
	   and (SUR.location_id IS NOT NULL and SUR.location_id != 0)
	   and (lot.wip_state = 20 or lot.wip_state = 70 or lot.wip_state = 100)
	   and lot.quality_state = 0
	   and sur.in_stock = 2 
	   --and sur.updated_at  >= (getdate() - 1095) -- old patthen close 2022/05/25 Time : 11.10
	   -- Add Condition is_ability = 1 สำหรับงาน hasuu long standing (เกิน 3 ปี) re-test กลับมาใช้งานได้ create date time : 2022/06/24 time 09.41
	   and (SUBSTRING(sur.serial_no,1,2) >= @year_now or sur.is_ability = 1) --Change Patthen Condition 2022/05/25 Time : 11.10
	   and sur.pcs != 0
	   and SUBSTRING(sur.serial_no,5,1) !='E' 
	   --and SUBSTRING(sur.serial_no,5,1) !='G' 
	   and (SUBSTRING(sur.serial_no,5,1) !='G' --allow device for G lot type do mixing (support claim) 2023/03/15 time : 10.55
			or (SUBSTRING(serial_no,5,1) = 'G' and dv.name in ('SV013-HE2           ','SV131-HE2           ','SV014-HE2           ','SV010-HE2           ','BV2HC045EFU-C       ','BV2HD045EFU-CE2     ','BV2HD070EFU-CE2    ','BV2HC045EFU-CE2     ','BD1020HFV-TR        '))
	   )--Aomsin บอกให้ใส่ 3device ด่วน 2024/02/24 SV131-HE2,SV014-HE2,SV010-HE2
	   ORDER BY sur.pcs ASC

	END

	IF @@ERROR <> 0
	GOTO ErrorHandler

	SET NOCOUNT OFF
	RETURN (0)
	ErrorHandler:
	RETURN (@@ERROR)


END
