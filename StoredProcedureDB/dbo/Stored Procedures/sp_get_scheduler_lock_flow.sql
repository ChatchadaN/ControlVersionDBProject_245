-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_lock_flow] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT  wipcontrol.id
	,wipcontrol.name as [Name] 
	, pkg.id as PkId
	, pkg.name as PKG
	,case when (SELECT CHARINDEX('[', wipcontrol.name)) < ((SELECT CHARINDEX('@', wipcontrol.name))-1) 
	 THEN SUBSTRING(wipcontrol.name ,(SELECT CHARINDEX('@', wipcontrol.name))+1, ((SELECT LEN(wipcontrol.name))-(SELECT CHARINDEX('@', wipcontrol.name))))
	 ELSE SUBSTRING(wipcontrol.name ,(SELECT CHARINDEX('@', wipcontrol.name))+1, ((SELECT CHARINDEX('[', wipcontrol.name))-(SELECT CHARINDEX('@', wipcontrol.name))-1))
	 END as Flow 
	--, SUBSTRING(wipcontrol.name ,(SELECT CHARINDEX('@', wipcontrol.name))+1, ((SELECT CHARINDEX('[', wipcontrol.name))-(SELECT CHARINDEX('@', wipcontrol.name))-1)) AS Flow 
	, wipcontrol.is_alarmed 
	, cast(round(alarm_value,2)as numeric(8,2)) as limit_value
	, cast(round(current_value,2)as numeric(8,2)) as current_value
	, control_unit_type as unitType
	, occurred_at as LockStartTime
	,case when (SELECT CHARINDEX('[', wipcontrol.name)) < ((SELECT CHARINDEX('@', wipcontrol.name))-1) 
	 THEN SUBSTRING(wipcontrol.name ,(SELECT CHARINDEX('[', wipcontrol.name))+1, ((SELECT CHARINDEX(']', wipcontrol.name))-(SELECT CHARINDEX('[', wipcontrol.name)))) 
	 ELSE SUBSTRING(wipcontrol.name ,(SELECT CHARINDEX('[', wipcontrol.name))+1, ((SELECT CHARINDEX(']', wipcontrol.name))-(SELECT CHARINDEX('[', wipcontrol.name))-1)) 
	 END as FlowControl 
	, case when (cast(round(alarm_value,2)as numeric(8,2)) != cast(round(warn_value,2 )as numeric(8,2)) 
	OR cast(round(alarm_value,2)as numeric(8,2)) != cast(round(target_value,2 )as numeric(8,2))) THEN 1
	else 0 end as Is_SameValue
	FROM [APCSProDWH].[wip_control].[monitoring_items] as wipcontrol
	inner join [APCSProDB].method.packages as pkg on pkg.id = wipcontrol.package_id
	where wipcontrol.name not like '%-nonGDIC%' and wipcontrol.name not like '%test%' 
	--and wipcontrol.name not like '%QFP%'
END
