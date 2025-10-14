
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_device_claim_by_bass_ver_002]	-- Add the parameters for the stored procedure here	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		--select [lots].[lot_no] AS [LotNo]
		--	--, [lots].[wip_state] 
		--	--, [day_indate].[date_value]
		--from [APCSProDB].[trans].[lots] with (nolock) 
		---------------------- date -------------------- 
		--inner join [APCSProDB].[trans].[days] as [day_indate] with (nolock) on [day_indate].[id] = [lots].[in_plan_date_id]
		--inner join [APCSProDB].[trans].[days] as [day_outdate] with (nolock) on [day_outdate].[id] = [lots].[modify_out_plan_date_id]
		---------------------- date -------------------- 
		--inner join [APCSProDB].[method].[device_names] with (nolock) on [device_names].[id] = [lots].[act_device_name_id]
		--inner join [APCSProDB].[method].[packages] with (nolock) on [packages].[id] = [device_names].[package_id]
		--inner join [APCSProDB].[method].[package_groups] with (nolock) on [package_groups].[id] = [packages].[package_group_id]
		--where [day_indate].[date_value] >= convert(date, '2023-12-14')
		--	AND [lots].[wip_state] in (0,10,20,70,100,101)
		--	AND [lots].[lot_no] LIKE '____A____V'
		--	AND [packages].[name] = 'SSOP-B28W'
		--	AND year([day_indate].[date_value]) <= year(convert(date, getdate()))    
		--	AND [device_names].[name] in ('BM60061FV-CDE2','BM60061AFV-CDE2')

		select [lots].[lot_no] AS [LotNo]
			--, [lots].[wip_state] 
			--, [day_indate].[date_value]
		from [APCSProDB].[trans].[lots] with (nolock) 
		-------------------- date -------------------- 
		inner join [APCSProDB].[trans].[days] as [day_indate] with (nolock) on [day_indate].[id] = [lots].[in_plan_date_id]
		inner join [APCSProDB].[trans].[days] as [day_outdate] with (nolock) on [day_outdate].[id] = [lots].[modify_out_plan_date_id]
		-------------------- date -------------------- 
		inner join [APCSProDB].[method].[device_names] with (nolock) on [device_names].[id] = [lots].[act_device_name_id]
		inner join [APCSProDB].[method].[packages] with (nolock) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (nolock) on [package_groups].[id] = [packages].[package_group_id]
		where [device_names].[name] = 'BM60014F7FV-FX      '
END