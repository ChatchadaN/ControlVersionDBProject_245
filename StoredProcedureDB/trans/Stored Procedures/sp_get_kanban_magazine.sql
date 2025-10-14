-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_kanban_magazine] 
	
	--PASS 2 Parameters HERE 
	@method as VARCHAR(30),
	@packageId as VARCHAR(30) = '%'
AS
BEGIN

	SET NOCOUNT ON;
	DECLARE @condition VARCHAR(30) = IIF(@packageId is null or @packageId = 0 ,'%',@packageId)

	IF(@method = 'record-back') 
	BEGIN

	select carrierName,packageId INTO #pRecordLatest from
	(
		select carrierName,packageId,RANK() OVER (partition by packageId order by latestInGroup DESC  ) as rankDate from 
		(
			select distinct carrierName, packageId,MAX(lastestDate) as latestInGroup from
			(
					select SUBSTRING(carrier_no,2,2) as carrierName,packages.id as packageId,MAX(recorded_at) as lastestDate from APCSProDB.trans.lot_process_records WITH (NOLOCK)
					inner join APCSProDB.method.device_names WITH (NOLOCK) on device_names.id = lot_process_records.act_device_name_id
					inner join APCSProDB.method.packages WITH (NOLOCK) on packages.id = device_names.package_id 
					where carrier_no is not null  and carrier_no NOT IN ('-','') and day_id > 2250 group by carrier_no,packages.id 
					) AS allTransCarrirer where carrierName IN ('LF','LL','LM','0M','NO','0S') group by carrierName,packageId 
				) AS bestOfDate 
	) AS rankDateTable where rankDate = 1


	
	select carrierName, act_package_id INTO #tranCarrier from
	(
		select SUBSTRING(carrier_no,2,2) as carrierName,act_package_id 
		from APCSProDB.trans.lots WITH (NOLOCK)
		where carrier_no is not null and carrier_no NOT IN ('-','') and in_plan_date_id > 2180 
	) AS allTransCarrirer where carrierName IN ('LF','LL','LM','0M','NO','0S') group by carrierName,act_package_id


	select distinct packages.name as pkgName,ISNULL(#tranCarrier.carrierName,#pRecordLatest.carrierName) as carrierName INTO #ActCarrirer from  APCSProDB.method.packages
	left join  #tranCarrier on packages.id = #tranCarrier.act_package_id 
	left join	#pRecordLatest on packages.id = #pRecordLatest.packageId  


	--REFFERENCE BY MONITORING ITEM PACKAGE LOGIC--

	--select distinct packages.name as pkgName,ISNULL(#tranCarrier.carrierName,#pRecordLatest.carrierName) as carrierName INTO #ActCarrirer from [APCSProDWH].[wip_control].[monitoring_items]
	--inner join APCSProDB.method.packages WITH (NOLOCK) on packages.id = monitoring_items.package_id
	--left join  #tranCarrier on packages.id = #tranCarrier.act_package_id 
	--left join	#pRecordLatest on packages.id = #pRecordLatest.packageId  
	--where control_unit_type = 0 and [monitoring_items].name LIKE '%MP%'


	select carrierName,COUNT(carrierName) as Unit from
	(
	select SUBSTRING(carrier_no,2,2) as carrierName from APCSProDB.trans.lot_process_records WITH (NOLOCK)
	inner join APCSProDB.method.device_names WITH (NOLOCK) on device_names.id = lot_process_records.act_device_name_id 
	inner join APCSProDB.method.packages WITH (NOLOCK) on packages.id = device_names.package_id 
	inner join 	#ActCarrirer on packages.name = #ActCarrirer.pkgName and SUBSTRING(lot_process_records.carrier_no,2,2) = #ActCarrirer.carrierName
			 
	where carrier_no is not null  and carrier_no NOT IN ('-','') and day_id > 2495 and packages.id LIKE @condition group by carrier_no
	) AS allTransCarrirer group by carrierName 

	drop table #pRecordLatest
	drop table #tranCarrier
	drop table #ActCarrirer


	RETURN
	END


	IF(@method = 'kanban-back')
	BEGIN
		select carrierName,SUM(mornitor) as Unit  from
			(
				select distinct packages.name,CAST(alarm_value as int) as mornitor,ISNULL(TRANtypeMatchPackage.carrierName,RecordtypeMatchPackage.carrierName) as carrierName from [APCSProDWH].[wip_control].[monitoring_items] 
				inner join APCSProDB.method.packages on packages.id = monitoring_items.package_id
				left join 
							(
								select carrierName, act_package_id  from
								(
								select SUBSTRING(carrier_no,2,2) as carrierName,act_package_id
								from APCSProDB.trans.lots 
								where carrier_no is not null and carrier_no NOT IN ('-','') and in_plan_date_id > 2180 
								) AS allTransCarrirer where carrierName IN ('LF','LL','LM','0M','NO','0S') group by carrierName,act_package_id
							) 
			
							as TRANtypeMatchPackage on packages.id = TRANtypeMatchPackage.act_package_id 

				left join	(
								select carrierName,packageId from
								(
								select carrierName,packageId,RANK() OVER (partition by packageId order by latestInGroup DESC  ) as rankDate from 
								(
								select distinct carrierName, packageId,MAX(lastestDate) as latestInGroup from
								(
								select SUBSTRING(carrier_no,2,2) as carrierName,packages.id as packageId,MAX(recorded_at) as lastestDate from APCSProDB.trans.lot_process_records
								inner join APCSProDB.method.device_names on device_names.id = lot_process_records.act_device_name_id
								inner join APCSProDB.method.packages on packages.id = device_names.package_id 
								where carrier_no is not null  and carrier_no NOT IN ('-','') and day_id > 2250 group by carrier_no,packages.id 
								) AS allTransCarrirer where carrierName IN ('LF','LL','LM','0M','NO','0S') group by carrierName,packageId 
								) AS bestOfDate 
								) AS rankDateTable where rankDate = 1

							) as RecordtypeMatchPackage on packages.id = RecordtypeMatchPackage.packageId 

				where control_unit_type = 0 and [monitoring_items].name LIKE '%MP%' and [monitoring_items].package_id LIKE  @condition

			) as monitorCarrier group by carrierName
	RETURN
	END
    

	IF(@method = 'kanban-front')
	BEGIN
		select carrierName,SUM(mornitor) as Unit  from
		(
			select distinct packages.name,CAST(alarm_value as int) as mornitor,ISNULL(TRANtypeMatchPackage.carrierName,RecordtypeMatchPackage.carrierName) as carrierName from [APCSProDWH].[wip_control].[monitoring_items] 
			inner join APCSProDB.method.packages on packages.id = monitoring_items.package_id
			left join 
						(
							select carrierName, act_package_id  from
							(
							select SUBSTRING(carrier_no,1,3) as carrierName,act_package_id
							from APCSProDB.trans.lots 
							where carrier_no is not null and carrier_no NOT IN ('-','') and in_plan_date_id > 2180 
							) AS allTransCarrirer where carrierName IN ('T63','TBI','THS','TMA','TSM') group by carrierName,act_package_id
						) 
			
						as TRANtypeMatchPackage on packages.id = TRANtypeMatchPackage.act_package_id 

			left join	(
							select carrierName,packageId from
							(
							select carrierName,packageId,RANK() OVER (partition by packageId order by latestInGroup DESC  ) as rankDate from 
							(
							select distinct carrierName, packageId,MAX(lastestDate) as latestInGroup from
							(
							select SUBSTRING(carrier_no,1,3) as carrierName,packages.id as packageId,MAX(recorded_at) as lastestDate from APCSProDB.trans.lot_process_records
							inner join APCSProDB.method.device_names on device_names.id = lot_process_records.act_device_name_id
							inner join APCSProDB.method.packages on packages.id = device_names.package_id 
							where carrier_no is not null  and carrier_no NOT IN ('-','') and day_id > 2250 group by carrier_no,packages.id 
							) AS allTransCarrirer where carrierName IN ('T63','TBI','THS','TMA','TSM') group by carrierName,packageId 
							) AS bestOfDate 
							) AS rankDateTable where rankDate = 1

						) as RecordtypeMatchPackage on packages.id = RecordtypeMatchPackage.packageId 

			where control_unit_type = 0 and [monitoring_items].name LIKE '%DB%' and [monitoring_items].package_id LIKE  @condition

		) as monitorCarrier group by carrierName
	RETURN
	END


	IF(@method = 'record-front') 
		BEGIN


		select carrierName,packageId INTO #pRecordLatestF from
		(
			select carrierName,packageId,RANK() OVER (partition by packageId order by latestInGroup DESC  ) as rankDate from 
			(
				select distinct carrierName, packageId,MAX(lastestDate) as latestInGroup from
				(
						select SUBSTRING(carrier_no,1,3) as carrierName,packages.id as packageId,MAX(recorded_at) as lastestDate from APCSProDB.trans.lot_process_records WITH (NOLOCK)
						inner join APCSProDB.method.device_names WITH (NOLOCK) on device_names.id = lot_process_records.act_device_name_id
						inner join APCSProDB.method.packages WITH (NOLOCK) on packages.id = device_names.package_id 
						where carrier_no is not null  and carrier_no NOT IN ('-','') and day_id > 2250 group by carrier_no,packages.id 
						) AS allTransCarrirer where carrierName IN ('T63','TBI','THS','TMA','TSM') group by carrierName,packageId 
					) AS bestOfDate 
		) AS rankDateTable where rankDate = 1


	
		select carrierName, act_package_id INTO #tranCarrierF from
		(
			select SUBSTRING(carrier_no,1,3) as carrierName,act_package_id 
			from APCSProDB.trans.lots WITH (NOLOCK)
			where carrier_no is not null and carrier_no NOT IN ('-','') and in_plan_date_id > 2180 
		) AS allTransCarrirer where carrierName IN ('T63','TBI','THS','TMA','TSM') group by carrierName,act_package_id


		select distinct packages.name as pkgName,ISNULL(#tranCarrierF.carrierName,#pRecordLatestF.carrierName) as carrierName INTO #ActCarrirerF from  APCSProDB.method.packages
		left join  #tranCarrierF on packages.id = #tranCarrierF.act_package_id 
		left join	#pRecordLatestF on packages.id = #pRecordLatestF.packageId  



		select carrierName,COUNT(carrierName) as Unit from
		(
		select SUBSTRING(carrier_no,1,3) as carrierName from APCSProDB.trans.lot_process_records WITH (NOLOCK)
		inner join APCSProDB.method.device_names WITH (NOLOCK) on device_names.id = lot_process_records.act_device_name_id 
		inner join APCSProDB.method.packages WITH (NOLOCK) on packages.id = device_names.package_id 
		inner join 	#ActCarrirerF on packages.name = #ActCarrirerF.pkgName and SUBSTRING(lot_process_records.carrier_no,1,3) = #ActCarrirerF.carrierName
			 
		where carrier_no is not null  and carrier_no NOT IN ('-','') and day_id > 2495 and packages.id LIKE @condition group by carrier_no
		) AS allTransCarrirer group by carrierName 

		drop table #pRecordLatestF
		drop table #tranCarrierF
		drop table #ActCarrirerF


		RETURN
	END
END
