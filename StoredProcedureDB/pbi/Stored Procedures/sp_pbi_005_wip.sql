

-- =============================================
-- Author:		<A.Kosato>
-- Create date: <12th Oct 2018>
-- Description:	<LOT1_TABLE to Lots>
-- =============================================
CREATE PROCEDURE [pbi].[sp_pbi_005_wip] (
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
	--(3) main script
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
    select
		TEMP.FactoryCode
		,TEMP.FactoryName
		,TEMP.Category
		,TEMP.Category2
		,TEMP.ProductCode
		,TEMP.ProdCode
		,TEMP.Level1
		,TEMP.Level2
		,TEMP.PackageName
		,TEMP.LineCode
		,TEMP.Date1
		,TEMP.Time1
		,TEMP.Date2
		,TEMP.Time2
		,TEMP.OrderNo
		,TEMP.LotNo
		,TEMP.RohmPN
		,TEMP.ProcessNo
		,TEMP.ProcessCode
		,TEMP.ProcessName
		,TEMP.MachineNo
　		,TEMP.OperatingCategory	
		,SUM(TEMP.ActQty1) as 'ActQty1' 
		,SUM(TEMP.ActQtyLot1) as 'ActQtyLot1' 
		,TEMP.ActQty2
		,TEMP.ActQtyLot2
		,TEMP.InOut as 'In/Out'
		,TEMP.RunPlanstop
		,TEMP.ProcessCode2
		,TEMP.ProcessName2
		,TEMP.InputLevel
		,'' as 'Level0'
		,'' as 'MachineNo2'
	from ( select DISTINCT
		FC.factory_code as 'FactoryCode'
		,FC.name as 'FactoryName'
		,'Wip' as 'Category'
		,'Actual' as 'Category2'
		,PF.product_code as 'ProductCode'
		,PK.item_code as 'ProdCode'
		,PK.form_code as 'Level1'
		,PK.pin_num_code as 'Level2'
		,PK.name as 'PackageName'
		,'' as 'LineCode'
		,replace(CONVERT(DATE,DY.date_value, 114),'-','') as 'Date1'
		,replace(CONVERT(char(12),DATEADD(hour,(FW.hour_code),CONVERT(datetime,0)),114),':','') as 'Time1'
		,'' as 'Date2'
		,'' as 'Time2'
		,'' as 'OrderNo'
		,'' as 'LotNo'
		,DN.name as 'RohmPN'
		,0 as 'ProcessNo'
		,JB.id as 'ProcessCode'
		,JB.name as 'ProcessName'
		,'' as 'MachineNo'
　	    ,'' as 'OperatingCategory'	
		,FW.pcs as 'ActQty1'
		,FW.lot_count as 'ActQtyLot1'
		,0 as 'ActQty2'
		,0 as 'ActQtyLot2'
		,'' as 'InOut'
		,'' as 'RunPlanstop' 
		,PR.process_no as 'ProcessCode2'
		,PR.name as 'ProcessName2'
		,case when PR.name = 'FT' then '9'
		else '2' end as 'InputLevel'
		,'' as 'Level0'
		,'' as 'MachineNo2'
	from APCSProDWH.dwh.fact_wip as FW with(nolock)
	inner join APCSProDB.trans.days as DY with(nolock)on DY.id = FW.day_id
	inner join APCSProDB.method.packages as PK with(nolock)on PK.id = FW.package_id
	inner join APCSProDB.method.device_names as DN with(nolock)on DN.package_id = PK.id and DN.id = FW.assy_name_id
	inner join APCSProDB.man.factories as FC with(nolock) on FC.id = FW.factory_id
	inner join APCSProDB.man.headquarters as HQ with(nolock) on HQ.factory_id = FC.id
	inner join APCSProDB.man.product_headquarters as PHQ with(nolock) on PHQ.headquarter_id = HQ.id
	inner join APCSProDB.man.product_families as PF with(nolock) on PF.id = PHQ.product_family_id
	inner join APCSProDB.method.jobs as JB with(nolock)on JB.id = FW.job_id
	inner join APCSProDB.method.Processes as PR with(nolock)on PR.id = JB.process_id
	inner join APCSProDB.method.package_groups as PKG with(nolock) on PKG.id = PK.package_group_id
	where DY.date_value >= @pStartDay and DY.date_value < @pEndDay
		and DN.is_assy_only < 2
		and FW.hour_code = 8
	group by 
		FC.factory_code
		,FW.hour_code
		,FW.package_id
		,FW.day_id
		,FW.pcs
		,FW.lot_count
		,DN.name
		,FC.name
		,PF.product_code
		,PK.item_code
		,PK.form_code
		,PK.pin_num_code
		,PK.name
		,PK.id
		,JB.id
		,JB.name
		,PR.name
		,PR.process_no
		,DY.date_value) as TEMP
	group by
		 TEMP.FactoryCode
		,TEMP.FactoryName
		,TEMP.Category
		,TEMP.Category2
		,TEMP.ProductCode
		,TEMP.ProdCode
		,TEMP.Level1
		,TEMP.Level2
		,TEMP.PackageName
		,TEMP.LineCode
		,TEMP.Date1
		,TEMP.Time1
		,TEMP.Date2
		,TEMP.Time2
		,TEMP.OrderNo
		,TEMP.LotNo
		,TEMP.RohmPN
		,TEMP.ProcessNo
		,TEMP.ProcessCode
		,TEMP.ProcessName
		,TEMP.MachineNo
　		,TEMP.OperatingCategory	
		,TEMP.ActQty2
		,TEMP.ActQtyLot2
		,TEMP.InOut
		,TEMP.RunPlanstop
		,TEMP.ProcessCode2
		,TEMP.ProcessName2
		,TEMP.InputLevel
	order by TEMP.ProcessNo, TEMP.Date1, TEMP.Date2, TEMP.ProcessName
RETURN 0;

END ;
