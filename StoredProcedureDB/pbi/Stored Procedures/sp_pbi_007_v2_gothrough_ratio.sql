




-- =============================================
-- Author:		<A.Kosato>
-- Create date: <12th Oct 2018>
-- Description:	<LOT1_TABLE to Lots>
-- =============================================
CREATE PROCEDURE [pbi].[sp_pbi_007_v2_gothrough_ratio] (
	@ServerName_APCSPro NVARCHAR(128) 
    ,@DatabaseName_APCSPro NVARCHAR(128)
	,@ServerName_APCSProDWH NVARCHAR(128) 
    ,@DatabaseName_APCSProDWH NVARCHAR(128)
	,@StartDay DATE
	,@EndDay DATE
	,@logtext NVARCHAR(max) output
	,@errnum  int output
	,@errline int output
	,@errmsg nvarchar(max) output
	) AS
BEGIN

    ---------------------------------------------------------------------------
	--(1) declare
    ---------------------------------------------------------------------------
	DECLARE @pObjAPCSPro NVARCHAR(128) = N''
	DECLARE @pObjAPCSProDWH NVARCHAR(128) = N''

	DECLARE @pFunctionName NVARCHAR(128) = N'';
	DECLARE @pStartDay DATE = null;
	DECLARE @pEndDay DATE = null;
	DECLARE @pRet INT = 0;
	DECLARE @pStepNo INT = 0; 

   ---------------------------------------------------------------------------
	--(2) connection string
   ---------------------------------------------------------------------------

	-- ''=local
	/*
	BEGIN
		IF RTRIM(@ServerName_APCSPro_) = '' RETURN 1;
	END;
	*/
	BEGIN
		IF RTRIM(@DatabaseName_APCSPro) = '' RETURN 1;
	END;
	-- ''=local
	/*
	BEGIN
		IF RTRIM(@ServerName_APCSProDWH_) = '' RETURN 1;
	END;
	*/
	BEGIN
		IF RTRIM(@DatabaseName_APCSProDWH) = '' RETURN 1;
	END;

	BEGIN
		IF RTRIM(@ServerName_APCSPro) = '' 
			BEGIN
				SET @pObjAPCSPro = '[' + @DatabaseName_APCSPro + ']'
			END;
		ELSE
		BEGIN
			SET @pObjAPCSPro = '[' + @ServerName_APCSPro + '].[' + @DatabaseName_APCSPro + ']'
		END;
	END;

	BEGIN
		IF RTRIM(@ServerName_APCSProDWH) = '' 
			BEGIN
				SET @pObjAPCSProDWH = '[' + @DatabaseName_APCSProDWH + ']'
			END;
		ELSE
		BEGIN
			SET @pObjAPCSProDWH = '[' + @ServerName_APCSProDWH + '].[' + @DatabaseName_APCSProDWH + ']'
		END;
	END;

	BEGIN
		IF RTRIM(@StartDay) = '' or RTRIM(@StartDay) is null
			BEGIN
				SET @pStartDay =  CONVERT(DATE, DATEADD(DAY,-1,GETDATE()))
			END;
		ELSE
		BEGIN
			SET @pStartDay = @StartDay
		END;
	END;

	BEGIN
		IF RTRIM(@EndDay) = '' or RTRIM(@EndDay) is null
			BEGIN
				SET @pEndDay = CONVERT(DATE, GETDATE())
			END;
		ELSE
		BEGIN
			SET @pEndDay = @EndDay
		END;
	END;

   ---------------------------------------------------------------------------
	--(3) main script1
   ---------------------------------------------------------------------------	
    insert into APCSProDWH.pbi.factory_data (
        [factory_code]
		,[factory_name]
		,[category]
		,[category2]
		,[product_code]
		,[prod_code]
		,[level1]
		,[level2]
		,[package_name]
		,[line_code]
		,[date1]
		,[time1]
		,[date2]
		,[time2]
		,[order_no]
		,[lot_no]
		,[rohm_pn]
		,[process_no]
		,[process_code]
		,[process_name]
		,[machine_no]
		,[operation_category]
		,[act_qty1]
		,[act_qty_lot1]
		,[act_qty2]
		,[act_qty_lot2]
		,[in_out]
		,[run_planstop]
		,[process_code2]
	    ,[process_name2]
		,[input_level]
		,[level0]
		,[machine_no2] )
	select DISTINCT
		FC.factory_code as 'FactoryCode'
		,FC.name as 'FactoryName'
		,'GoThroughRatio' as 'Category'
		,'Actual' as 'Category2'
		,PF.product_code as 'ProductCode'
		,PK.item_code as 'ProdCode'
		,PK.form_code as 'Level1'
		,PK.pin_num_code as 'Level2'
		,PK.name as 'PackageName'
		,'' as 'LineCode'
		,replace(CONVERT(DATE,DY.date_value, 114),'-','') as 'Date1'
		,'' as 'Time1'
		,'' as 'Date2'
		,'' as 'Time2'
		,case when AO.order_no is null then '' else AO.order_no end as 'OrderNo'
		,LO.lot_no as 'LotNo'
		,DN.name as 'RohmPN'
		,0 as 'ProcessNo'
		,'' as 'ProcessCode'
		,'' as 'ProcessName'
		,'' as 'MachineNo'
　	    ,'' as 'OperatingCategory'	
		,LO.qty_fail + LO.qty_pass as 'ActQty1'
		,1 as 'ActQtyLot1'
		,0 as 'ActQty2'
		,0 as 'ActQtyLot2'
		,'' as 'InOut'
		,'' as 'RunPlanstop' 
		,'' as 'ProcessCode2'
		,'' as 'ProcessName2'
		,'' as 'InputLevel'
		,'' as 'Level0'
		,'' as 'MachineNo2'
	from APCSProDWH.dwh.dim_lots as DLO with(nolock)
		inner join APCSProDB.trans.lots as LO with(nolock)on LO.id = DLO.id
		inner join APCSProDB.method.device_slips as DS with(nolock)on DS.device_slip_id = LO.device_slip_id
		inner join APCSProDB.method.device_versions as DV with(nolock)on DV.device_id = DS.device_id
		inner join APCSProDB.method.device_names as DN with(nolock)on DN.id = DV.device_name_id
		inner join APCSProDB.method.packages as PK with(nolock)on PK.id = DN.package_id
		left outer join APCSProDB.robin.assy_orders as AO with(nolock)on AO.id = LO.order_id
		inner join APCSProDB.trans.days as DY with(nolock)on DY.id = DLO.lotout_day_id
		inner join APCSProDB.man.factories as FC with(nolock) on FC.id = DLO.factory_id
		inner join APCSProDB.man.headquarters as HQ with(nolock) on HQ.factory_id = FC.id
		inner join APCSProDB.man.product_headquarters as PHQ with(nolock) on PHQ.headquarter_id = HQ.id
		inner join APCSProDB.man.product_families as PF with(nolock) on PF.id = PHQ.product_family_id
	where (DLO.is_sent is null or DLO.is_sent = 0 ) and
	      (DLO.lotout_day_id is not null) and
		  DN.is_assy_only < 2
		  and (PK.item_code is not null and PK.form_code is not null and PK.pin_num_code is not null)
	group by 
		FC.factory_code
		,DN.name
		,FC.name
		,PF.product_code
		,PK.item_code
		,PK.form_code
		,PK.pin_num_code
		,PK.name
		,PK.id
		,LO.lot_no
		,LO.qty_pass
		,LO.qty_fail
		,AO.order_no
		,DY.date_value
	order by replace(CONVERT(DATE,DY.date_value, 114),'-',''), LO.lot_no

   ---------------------------------------------------------------------------
	--(4) main script2
   ---------------------------------------------------------------------------	

	update DLO set
		DLO.is_sent = 1
	from APCSProDWH.dwh.dim_lots as DLO with(nolock)
		inner join APCSProDB.trans.lots as LO with(nolock)on LO.id = DLO.id
		inner join APCSProDB.method.device_slips as DS with(nolock)on DS.device_slip_id = LO.device_slip_id
		inner join APCSProDB.method.device_versions as DV with(nolock)on DV.device_id = DS.device_id
		inner join APCSProDB.method.device_names as DN with(nolock)on DN.id = DV.device_name_id
		inner join APCSProDB.method.packages as PK with(nolock)on PK.id = DN.package_id
	where (DLO.is_sent is null or DLO.is_sent = 0 ) and
		  (DLO.lotout_day_id is not null) and
		  DN.is_assy_only < 2

RETURN 0;

END ;
