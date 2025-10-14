-- =============================================
-- Author:		<Jakkapong>
-- Create date: <4/8/2022>
-- Description:	<Get KanbanBarData and append top(1) when data doesn't contain 00:00 >
-- =============================================
CREATE PROCEDURE [trans].[sp_get_kanban_BarChartData]
	-- Add the parameters for the stored procedure here
	@Date  DATETIME = null,
	@PackageId  INT = null


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	Set @Date = Coalesce(@Date , GetDate())
	Set @PackageId = Coalesce(@PackageId , 177)

SELECT name as GroupName,TimeGroup,SeqHours,CONVERT(DECIMAL(18,2),AVG(current_value)) as averageChangeInHR INTO #TestTemp FROM 
	(
		SELECT main_table.name,[recorded_at],record.current_value, FORMAT([recorded_at],'yyyy-MM-dd HH:00') as TimeGroup, DATENAME(hour, [recorded_at]) as SeqHours
		FROM [APCSProDWH].[wip_control].[monitoring_item_records] as record 
		inner join APCSProDWH.wip_control.monitoring_items as main_table on main_table.id = record.monitoring_item_id and record.recorded_at BETWEEN FORMAT(@Date,'d') and FORMAT(DATEADD(DAY, 1, @Date),'d')
		inner join APCSProDB.method.packages on main_table.package_id = packages.id 
		inner join APCSProDB.method.package_groups on packages.package_group_id = package_groups.id 
		where main_table.control_unit_type != 2 and main_table.package_id = @PackageId  and (main_table.name NOT LIKE '%wip%' and main_table.name NOT LIKE '%input%') and (main_table.name LIKE '%@MP%' OR main_table.name LIKE '%@DB%')

	) as BeforeGroup  group by name,TimeGroup,SeqHours order by TimeGroup DESC




IF ((select TimeGroup from #TestTemp where GroupName LIKE '%@MP%' and FORMAT(CONVERT(DATETIME,TimeGroup),'HH:00') = '00:00') IS NULL)
	BEGIN

		INSERT INTO #TestTemp
		--Frist Day have day before.
		--00:00 First Record of the day
		SELECT TOP(1) name as GroupName, FORMAT(@Date,'yyyy-MM-dd 00:00') as TimeGroupDefault,'0' as SeqHours,CONVERT(DECIMAL(18,2),AVG(current_value)) as averageChangeInHR  FROM 
		(
			SELECT main_table.name,[recorded_at],record.current_value, FORMAT([recorded_at],'yyyy-MM-dd HH:00') as TimeGroup
			FROM [APCSProDWH].[wip_control].[monitoring_item_records] as record 
			inner join APCSProDWH.wip_control.monitoring_items as main_table on main_table.id = record.monitoring_item_id and record.recorded_at <= FORMAT(@Date,'d')
			inner join APCSProDB.method.packages on main_table.package_id = packages.id 
			inner join APCSProDB.method.package_groups on packages.package_group_id = package_groups.id 
			where main_table.control_unit_type != 2 and main_table.package_id = @PackageId  and (main_table.name NOT LIKE '%wip%' and main_table.name NOT LIKE '%input%') and (main_table.name LIKE '%@MP%')

		) as BeforeGroup  group by name,TimeGroup order by TimeGroup DESC

		--First Day of record not contain 00:00
	    --Frist Day Doesn't have day before.
		IF ((select TimeGroup from #TestTemp where GroupName LIKE '%@MP%' and FORMAT(CONVERT(DATETIME,TimeGroup),'HH:00') = '00:00') IS NULL)
		BEGIN
				INSERT INTO #TestTemp
				SELECT TOP(1) name as GroupName,FORMAT(@Date,'yyyy-MM-dd 00:00') as TimeGroupDefault,'0' as SeqHours,CONVERT(DECIMAL(18,2),AVG(current_value)) as averageChangeInHR  FROM 
				(
					SELECT main_table.name,[recorded_at],record.current_value, FORMAT([recorded_at],'yyyy-MM-dd HH:00') as TimeGroup
					FROM [APCSProDWH].[wip_control].[monitoring_item_records] as record 
					inner join APCSProDWH.wip_control.monitoring_items as main_table on main_table.id = record.monitoring_item_id and record.recorded_at <= FORMAT(@Date,'d') + ' 23:59' 
					inner join APCSProDB.method.packages on main_table.package_id = packages.id 
					inner join APCSProDB.method.package_groups on packages.package_group_id = package_groups.id 
					where main_table.control_unit_type != 2 and main_table.package_id = @PackageId  and (main_table.name NOT LIKE '%wip%' and main_table.name NOT LIKE '%input%') and (main_table.name LIKE '%@MP%')

				) as BeforeGroup  group by name,TimeGroup order by TimeGroup DESC

		END

	END



IF ((select TimeGroup from #TestTemp where GroupName LIKE '%@DB%' and FORMAT(CONVERT(DATETIME,TimeGroup),'HH:00') = '00:00') IS NULL)
	BEGIN
		INSERT INTO #TestTemp
		--Frist Day Doesn't have day before.


		SELECT TOP(1) name as GroupName,FORMAT(@Date,'yyyy-MM-dd 00:00') as TimeGroupDefault,'0' as SeqHours,CONVERT(DECIMAL(18,2),AVG(current_value)) as averageChangeInHR  FROM 
		(
			SELECT main_table.name,[recorded_at],record.current_value, FORMAT([recorded_at],'yyyy-MM-dd HH:00') as TimeGroup
			FROM [APCSProDWH].[wip_control].[monitoring_item_records] as record 
			inner join APCSProDWH.wip_control.monitoring_items as main_table on main_table.id = record.monitoring_item_id and record.recorded_at <= FORMAT(@Date,'d')
			inner join APCSProDB.method.packages on main_table.package_id = packages.id 
			inner join APCSProDB.method.package_groups on packages.package_group_id = package_groups.id 
			where main_table.control_unit_type != 2 and main_table.package_id = @PackageId  and (main_table.name NOT LIKE '%wip%' and main_table.name NOT LIKE '%input%') and (main_table.name LIKE '%@DB%')

		) as BeforeGroup  group by name,TimeGroup order by TimeGroup DESC



		--First Day of record not contain 00:00
		IF ((select TimeGroup from #TestTemp where GroupName LIKE '%@DB%' and FORMAT(CONVERT(DATETIME,TimeGroup),'HH:00') = '00:00') IS NULL)
		BEGIN
				INSERT INTO #TestTemp
				SELECT TOP(1) name as GroupName,FORMAT(@Date,'yyyy-MM-dd 00:00') as TimeGroupDefault,'0' as SeqHours,CONVERT(DECIMAL(18,2),AVG(current_value)) as averageChangeInHR  FROM 
				(
					SELECT main_table.name,[recorded_at],record.current_value, FORMAT([recorded_at],'yyyy-MM-dd HH:00') as TimeGroup
					FROM [APCSProDWH].[wip_control].[monitoring_item_records] as record 
					inner join APCSProDWH.wip_control.monitoring_items as main_table on main_table.id = record.monitoring_item_id and record.recorded_at <= FORMAT(@Date,'d') + ' 23:59' 
					inner join APCSProDB.method.packages on main_table.package_id = packages.id 
					inner join APCSProDB.method.package_groups on packages.package_group_id = package_groups.id 
					where main_table.control_unit_type != 2 and main_table.package_id = @PackageId  and (main_table.name NOT LIKE '%wip%' and main_table.name NOT LIKE '%input%') and (main_table.name LIKE '%@DB%')

				) as BeforeGroup  group by name,TimeGroup order by TimeGroup DESC

		END

	END



SELECT * from #TestTemp order by TimeGroup

drop table #TestTemp

END
