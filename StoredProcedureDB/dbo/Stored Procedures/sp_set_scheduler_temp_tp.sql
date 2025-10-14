-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_temp_tp] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	DECLARE @PKG varchar(MAX)
	SET @PKG  = 'HTSSOP-B40,HRP5,HRP7,HTQFP64AV,HTQFP64BV,HTQFP64V,HTQFP64V-HF,QFP32,SQFP-T52,VQFP64,VQFP48C,SSON004R1010,SSON004X1010,SSON004X1216,USON006X1212,USON008X1216,USON014X3020,VSON008X2030,VSON04Z1114A,VSON008X22,SSOP-B20W,SSOP-B10W,SSOP-B28W,TO252-J5,TO252-J5F,HSON8,HSON8-HF,HSON-A8,MSOP8,SSOP-B20W,SSOP-B10W,SSOP-B28W,TO252S-3,TO252S-5,TO252S-5+,TO252S-7+,SSOP-A54_23,SSOP-A54_36,SSOP-A54_42,SSOP-A26_20,SSOP-B24,SSOP-B28,SSOP-B30,SSOP-A32,SSOP-B40,SOP-JW8,HSSOP-C16,HTSSOP-B20,HTSSOP-C48R,HTSSOP-C48,HTSSOP-C48E,HTSSOP-B40,SSOP-C38W,TSSOP-C48V,TO252-3,TO252-5,HTSSOPB20E,HTSSOPC48E'
    SET @PKG += 'SSOP-A32,SSOP-B40,TO263-3,TO263-5,TO263-7,HTSSOP-A44,HTSSOP-A44R,HTSSOP-B54,HTSSOP-B54R,HTSSOP-B54E,TO252-J3,SSOP-A20,SSOP-A24,HSOP-M36,SOP20,SOP22,SOP24,TO263-3F,TO263-5F,SOT223-4,SOT223-4F,TO263-7L,HTSSOPC48E,HTSSOP-C64A,TSSOP-B30,SSOPB28WR6,TSSOP-B8J,MSOP8-HF,SSOPB30W19,MSOP8E-HF,SSOP-C26W,SSOPB20WR1,SSOP-B20WA,HTSSOPB20X'
	-- Insert statements for procedure here

BEGIN TRANSACTION;
BEGIN TRY
	DELETE FROM DBxDW.dbo.scheduler_temp_tp
	WHERE PackageName in (SELECT * from STRING_SPLIT ( @PKG , ',' ))

	--FIND Material data
	SELECT * INTO #matPackage FROM (
	SELECT pk.name as pkgName,p.name as matName,p.details
									FROM [APCSProDB].[method].[device_names] AS [dn]
									INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [dn].[package_id] = [pk].[id]
									INNER JOIN [APCSProDB].[method].[device_versions] AS [d_vs] ON [dn].[id] = [d_vs].[device_name_id]
									INNER JOIN [APCSProDB].[method].[device_slips] AS [ds] ON [d_vs].[device_id] = [ds].[device_id]
 										AND [ds].[is_released] = 1 
 										AND [d_vs].[device_type] = 6
										AND [d_vs].[version_num] = [ds].[version_num]
									INNER JOIN [APCSProDB].[method].[device_flows] AS [dv_f] ON [ds].[device_slip_id] = [dv_f].[device_slip_id]
									LEFT JOIN [APCSProDB].method.material_sets ms ON ms.id = dv_f.material_set_id
									INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id 
									INNER JOIN [APCSProDB].material.productions p ON ml.material_group_id = p.id
					WHERE 
					dv_f.job_id  IN (231,236,289,397,428)
					and dv_f.material_set_id IS NOT NULL 
					and dv_f.recipe IS NULL
					) as dataSet
	PIVOT (
		max(matName)
		for details
		In([EMBOSS TAPE],[COVER TAPE],[REEL])
	) as pvTable
	order by pkgName



	INSERT INTO DBxDW.dbo.scheduler_temp_tp
	SELECT tpsetup.mcname ,tpsetup.mcid,tpsetup.mctype,tpsetup.pkgname,tpsetup.devicename,NULL as kote,NULL as colette,
	(select [EMBOSS TAPE] from #matPackage where #matPackage.pkgName = tpsetup.pkgname ) as emboss,
	(select [COVER TAPE] from #matPackage where #matPackage.pkgName = tpsetup.pkgname ) as cover,NULL as recipe
	, case when [State].run_state = 10 THEN 'PlanStop'
				when AllLot.LOT1 != '' THEN 'Run'
				when AllLot.LOT2 = '' THEN 'Wait'
				when AllLot.LOT2 collate SQL_Latin1_General_CP1_CI_AS = tpsetup.mcname THEN 'Wait' 
				when AllLot.LOT2 != '' THEN 'Ready'
			ELSE 'Wait' END as [Status]
	, AllLot.LOT1
		, AllLot.LOT2
		, AllLot.LOT3
		, AllLot.LOT4
		, AllLot.LOT5
		, AllLot.LOT6
		, AllLot.LOT7
		, AllLot.LOT8
		, AllLot.LOT9
		, AllLot.LOT10
		, AllLot.DEVICE1
		, AllLot.DEVICE2
		, AllLot.DEVICE3
		, AllLot.DEVICE4
		, AllLot.DEVICE5
		, AllLot.DEVICE6
		, AllLot.DEVICE7
		, AllLot.DEVICE8
		, AllLot.DEVICE9
		, AllLot.DEVICE10
		, AllLot.LOT2_RackAddress
		, AllLot.LOT2_RackName
		, case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 then 1 ELSE 0 end as DelayLot
		, AllLot.LOT1_LOTEND as Lot1Date
		, AllLot.LOT1_LOTSTART as Lot1Start
	FROM DBx.dbo.scheduler_tp_qa_mc_setup as tpsetup
	left join APCSProDB.trans.machine_states as [State] on tpsetup.mcid = State.machine_id
	inner join (select mcname
			, min(LOT1) as LOT1
			, min(LOT2) as LOT2
			, min(LOT3) as LOT3
			, min(LOT4) as LOT4
			, min(LOT5) as LOT5
			, min(LOT6) as LOT6
			, min(LOT7) as LOT7
			, min(LOT8) as LOT8
			, min(LOT9) as LOT9
			, min(LOT10) as LOT10
			, min(DEVICE1) as DEVICE1
			, min(DEVICE2) as DEVICE2
			, min(DEVICE3) as DEVICE3
			, min(DEVICE4) as DEVICE4
			, min(DEVICE5) as DEVICE5
			, min(DEVICE6) as DEVICE6
			, min(DEVICE7) as DEVICE7
			, min(DEVICE8) as DEVICE8
			, min(DEVICE9) as DEVICE9
			, min(DEVICE10) as DEVICE10
			, min(LOT2_RackAddress) as LOT2_RackAddress
			, min(LOT2_RackName) as LOT2_RackName
			, min(LOT1_LOTEND) as LOT1_LOTEND
			, min(LOT1_LOTSTART) as LOT1_LOTSTART
			from
			(SELECT scheduler_tp_qa_mc_setup.mcname
			, case when scheduler_temp_seq_tp.[seq_no] = 1 then scheduler_temp_seq_tp.[lot_no] else null end as LOT1
			, case when scheduler_temp_seq_tp.[seq_no] = 2 then scheduler_temp_seq_tp.[lot_no] else null end as LOT2
			, case when scheduler_temp_seq_tp.[seq_no] = 3 then scheduler_temp_seq_tp.[lot_no] else null end as LOT3
			, case when scheduler_temp_seq_tp.[seq_no] = 4 then scheduler_temp_seq_tp.[lot_no] else null end as LOT4
			, case when scheduler_temp_seq_tp.[seq_no] = 5 then scheduler_temp_seq_tp.[lot_no] else null end as LOT5
			, case when scheduler_temp_seq_tp.[seq_no] = 6 then scheduler_temp_seq_tp.[lot_no] else null end as LOT6
			, case when scheduler_temp_seq_tp.[seq_no] = 7 then scheduler_temp_seq_tp.[lot_no] else null end as LOT7
			, case when scheduler_temp_seq_tp.[seq_no] = 8 then scheduler_temp_seq_tp.[lot_no] else null end as LOT8
			, case when scheduler_temp_seq_tp.[seq_no] = 9 then scheduler_temp_seq_tp.[lot_no] else null end as LOT9
			, case when scheduler_temp_seq_tp.[seq_no] = 10 then scheduler_temp_seq_tp.[lot_no] else null end as LOT10
			, case when scheduler_temp_seq_tp.[seq_no] = 1 then scheduler_temp_seq_tp.ft_device else null end as DEVICE1
			, case when scheduler_temp_seq_tp.[seq_no] = 2 then scheduler_temp_seq_tp.ft_device else null end as DEVICE2
			, case when scheduler_temp_seq_tp.[seq_no] = 3 then scheduler_temp_seq_tp.ft_device else null end as DEVICE3
			, case when scheduler_temp_seq_tp.[seq_no] = 4 then scheduler_temp_seq_tp.ft_device else null end as DEVICE4
			, case when scheduler_temp_seq_tp.[seq_no] = 5 then scheduler_temp_seq_tp.ft_device else null end as DEVICE5
			, case when scheduler_temp_seq_tp.[seq_no] = 6 then scheduler_temp_seq_tp.ft_device else null end as DEVICE6
			, case when scheduler_temp_seq_tp.[seq_no] = 7 then scheduler_temp_seq_tp.ft_device else null end as DEVICE7
			, case when scheduler_temp_seq_tp.[seq_no] = 8 then scheduler_temp_seq_tp.ft_device else null end as DEVICE8
			, case when scheduler_temp_seq_tp.[seq_no] = 9 then scheduler_temp_seq_tp.ft_device else null end as DEVICE9
			, case when scheduler_temp_seq_tp.[seq_no] = 10 then scheduler_temp_seq_tp.ft_device else null end as DEVICE10
			, case when scheduler_temp_seq_tp.[seq_no] = 2 then scheduler_temp_seq_tp.rack_address else null end as LOT2_RackAddress
			, case when scheduler_temp_seq_tp.[seq_no] = 2 then scheduler_temp_seq_tp.rack_name else null end as LOT2_RackName
			, case when scheduler_temp_seq_tp.[seq_no] = 1 then scheduler_temp_seq_tp.lot_end else null end as LOT1_LOTEND
			, case when scheduler_temp_seq_tp.[seq_no] = 1 then scheduler_temp_seq_tp.lot_start else null end as LOT1_LOTSTART
			  FROM [DBx].[dbo].scheduler_tp_qa_mc_setup
			  left join [DBxDW].[dbo].scheduler_temp_seq_tp on scheduler_temp_seq_tp.[machine_name] collate SQL_Latin1_General_CP1_CI_AS = scheduler_tp_qa_mc_setup.mcname) as lot
		group by lot.mcname) as AllLot on AllLot.mcname = tpsetup.mcname
	left join [APCSProDB].[trans].[lots] on [lots].[lot_no] = [AllLot].[LOT1] collate SQL_Latin1_General_CP1_CI_AS
	left join [APCSProDB].[trans].[days] as [days2] on [days2].[id] = [lots].[out_plan_date_id]
	WHERE pkgname in (SELECT * from STRING_SPLIT ( @PKG , ',' ))

	drop table #matPackage
	
	COMMIT;
END TRY
BEGIN CATCH
	PRINT '---> Error <----' +  ERROR_MESSAGE() + '---> Error <----'; 
	ROLLBACK;
END CATCH
END