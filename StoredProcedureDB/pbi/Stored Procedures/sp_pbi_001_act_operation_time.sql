

-- =============================================
-- Author:		<A.Kosato>
-- Create date: <12th Oct 2018>
-- Description:	<LOT1_TABLE to Lots>
-- =============================================
CREATE PROCEDURE [pbi].[sp_pbi_001_act_operation_time] (
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
		,[machine_no2])
   select DISTINCT
		LPR.FactoryCode
		,LPR.FactoryName
		,LPR.Category
		,LPR.Category2
		,LPR.ProductCode
		,LPR.ProdCode
		,LPR.Level1
		,LPR.Level2
		,LPR.PackageName
		,LPR.LineCode
		,replace(CONVERT(DATE,LPR_Before.recorded_at, 114),'-','') as 'Date1'
		,replace(CONVERT(char(12),LPR_Before.recorded_at, 114),':','') as 'Time1'
		,LPR.Date2
		,LPR.Time2
		,LPR.OrderNo
		,LPR.LotNo
		,LPR.RohmPN
		,LPR.ProcessNo
		,LPR.ProcessCode
		,LPR.ProcessName
		,LPR.MachineNo
　	    ,LPR.OperatingCategory	
		,LPR.ActQty1
		,LPR.ActQtyLot1
		,LPR.ActQty2
		,LPR.ActQtyLot2
		,LPR.InOut
		,LPR.RunPlanstop
		,LPR.ProcessCode2
		,LPR.ProcessName2
		,LPR.InputLevel
		,LPR.Level0
		,LPR.MachineNo2
	from APCSProDB.trans.lot_process_records as LPR_Before
	inner join (
	select DISTINCT
		Max(LPR_Before.id) as 'Before_id'
		,FC.factory_code as 'FactoryCode'
		,FC.name as 'FactoryName'
		,'OperationTime' as 'Category'
		,'Actual' as 'Category2'
		,PF.product_code as 'ProductCode'
		,PK.item_code as 'ProdCode'
		,PK.form_code as 'Level1'
		,PK.pin_num_code as 'Level2'
		,PK.name as 'PackageName'
		,'' as 'LineCode'
		,'' as 'Date1'
		,'' as 'Time1'
		,replace(CONVERT(DATE,LPR.recorded_at, 114),'-','') as 'Date2'
		,replace(CONVERT(char(12),LPR.recorded_at,114),':','') as 'Time2'
		,case when AO.order_no is null then '' else AO.order_no end as 'OrderNo'
		,LO.lot_no as 'LotNo'
		,DN.name as 'RohmPN'
		,MAX(DF.step_no) as 'ProcessNo'
		,JB.id as 'ProcessCode'
		,JB.name as 'ProcessName'
		,MC.name as 'MachineNo'
　	    ,'A01' as OperatingCategory	
		,DATEDIFF(second,Max(LPR_Before.recorded_at),LPR.recorded_at) as 'ActQty1'
		,0 as 'ActQtyLot1'
		,0 as 'ActQty2'
		,0 as 'ActQtyLot2'
		,'' as 'InOut'
		,'' as 'RunPlanstop' 
		,PR.process_no as 'ProcessCode2'
		,PR.name as 'ProcessName2'
		,case when PR.name = 'FT' then '9' else '2' end as 'InputLevel'
		,case when PR.name = 'FT' then MD.name else PK.name end as 'Level0'
		,case when MD.name is null then LTRIM(RTRIM(PK.name)) + '/' + LTRIM(RTRIM(PR.name)) else MD.name end as 'MachineNo2'
	from APCSProDB.trans.lot_process_records as LPR with(nolock)
	inner join APCSProDB.trans.lots as LO with(nolock)on LO.id = LPR.lot_id and LPR.record_class = 2
	inner join APCSProDB.trans.lot_process_records as LPR_Before with(nolock)
		on LPR_Before.record_class IN ( 1, 2 ) and LPR_Before.job_id = LPR.job_id and LPR_Before.lot_id = LPR.lot_id and LPR_Before.machine_id = LPR_Before.machine_id and LPR_Before.id < LPR.id
	left outer join APCSProDB.robin.assy_orders as AO with(nolock)on AO.id = LO.order_id
	inner join APCSProDB.method.device_names as DN with(nolock)on DN.id = LO.act_device_name_id
	inner join APCSProDB.method.packages as PK with(nolock)on PK.id = DN.package_id
	inner join APCSProDB.mc.machines as MC with(nolock)on MC.id = LPR.machine_id
	inner join APCSProDB.mc.models as MD with(nolock)on MD.id = MC.machine_model_id
	inner join APCSProDB.mc.makers as MK with(nolock) on MK.id = MD.maker_id
	inner join APCSProDB.mc.group_models as GM with(nolock) on GM.machine_model_id = MD.id
	inner join APCSProDB.man.headquarters as HQ with(nolock) on HQ.id = MC.headquarter_id
	inner join APCSProDB.man.factories as FC with(nolock) on FC.id = HQ.factory_id
	inner join APCSProDB.man.product_headquarters as PHQ with(nolock) on PHQ.headquarter_id = HQ.id
	inner join APCSProDB.man.product_families as PF with(nolock) on PF.id = PHQ.product_family_id
	inner join APCSProDB.method.jobs as JB with(nolock) on JB.id = LPR.job_id
	inner join APCSProDB.method.device_flows as DF with(nolock)on DF.device_slip_id = LO.device_slip_id and DF.job_id = JB.id
	inner join APCSProDB.method.Processes as PR with(nolock)on PR.id = JB.process_id
	inner join APCSProDB.method.package_groups as PKG with(nolock) on PKG.id = PK.package_group_id
	where LPR.recorded_at >= @pStartDay and LPR.recorded_at < @pEndDay
		  and PR.name != 'O/G'
		  and DN.is_assy_only < 2
	group by 
		FC.factory_code
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
		,MC.name
		,LO.lot_no
		,AO.order_no
		,LPR.recorded_at
		,LPR.qty_pass
		,LPR.qty_fail
		,DN.name
		,PR.process_no
		,PR.name
		,MD.name ) as LPR on LPR.Before_id = LPR_Before.id and LPR_Before.record_class = 1
	order by LPR.ProcessNo, replace(CONVERT(DATE,LPR_Before.recorded_at, 114),'-',''), replace(CONVERT(char(12),LPR_Before.recorded_at, 114),':',''), LPR.ProcessName
RETURN 0;

END ;

