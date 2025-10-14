-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_tp_qa_calculate]
	-- Add the parameters for the stored procedure here
	@value int = 0
AS
BEGIN

	SET NOCOUNT ON;

	--Be careful, this stored procedure not only return tp but it return qc wip count too.

	SELECT DISTINCT pkgname,devicename,jobname,jobid,sumlots --Only On rack Wip
	,sumkpcs,[state],standardtime,hold,
	alllot --include not on rack WIP
	,sumWipQa,[group],cal.tp_rank
	,case when APCSProDB.method.device_names.alias_package_group_id != 33 THEN 
		case when pkgname = 'SSOP-B20W' THEN
			CASE WHEN APCSProDB.method.device_names.rank = 'M' THEN 2
				WHEN APCSProDB.method.device_names.rank = 'BZM' THEN 2
				WHEN APCSProDB.method.device_names.rank = 'C' THEN 2
				WHEN APCSProDB.method.device_names.rank = 'BZC' THEN 2
				WHEN APCSProDB.method.device_names.rank = 'H' THEN 2
			ELSE 0 END
		ELSE 0 END
	ELSE 1 END AS Is_GDIC 
	FROM [DBx].[dbo].scheduler_tp_qa_calculate as cal
	INNER JOIN APCSProDB.method.device_names on APCSProDB.method.device_names.name = cal.devicename
	where  sumlots >= @value AND APCSProDB.method.device_names.alias_package_group_id is not null
	order by pkgname,devicename,[group]
END
