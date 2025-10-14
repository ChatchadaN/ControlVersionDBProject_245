

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_resurpluses]	-- Add the parameters for the stored procedure here	
	@lot_id varchar(10) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT	 lots.id
			, lots.lot_no
			, CASE WHEN [lots].[carrier_no] IS NULL THEN '-' END AS carrier_no
			, CASE WHEN (surpluses.location_id IS NULL OR surpluses.location_id = 0)
					THEN '-' WHEN  surpluses.location_id IS NOT NULL THEN  locations.name  END AS   location_no
			, lable_category.label_eng  AS production_category  
			, CASE WHEN DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 then 'OrderDelay' ELSE 'Normal' end AS [delay_status]
			, CASE WHEN DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 then 'ORDER DELAY' ELSE 'NORMAL' end AS [status]
			, DATEDIFF(DAY,[days2].[date_value],GETDATE()) AS delay_day 
			, DATEDIFF(DAY,[days2].[date_value],GETDATE()) AS delay_day
			, [device_names].[name] AS device
			, [device_names].[ft_name] AS ft_device
			, [packages].[name] AS package
			, [device_names].[tp_rank] AS tp_rank
			, [jobs].[name] AS operation
			, CASE WHEN [lots].[is_special_flow] = 1 then [item_labels6].[label_eng] ELSE [item_labels2].[label_eng] end AS process_state
			, [item_labels3].[label_eng] AS quality_state
			, [lots].[updated_at] AS update_time
			, [lots].[qty_in] AS total
			, [lots].[qty_pass] AS good
			, [lots].[qty_fail] AS ng
			, [users].[emp_num] AS operator
			,[lots].[updated_by]
FROM		[APCSProDB].trans.lot_combine
INNER JOIN	[APCSProDB].trans.lots 
ON	lots.id					=	lot_combine.lot_id
INNER JOIN [APCSProDB].trans.item_labels	AS lable_category
ON	lable_category.name		=	'lots.production_category'
AND lable_category.val		=	lots.production_category
LEFT JOIN [APCSProDB].trans.surpluses
ON	surpluses.lot_id		=	lots.id
LEFT JOIN [APCSProDB].trans.locations
ON  locations.id			=	surpluses.location_id
INNER JOIN [APCSProDB].trans.item_labels	AS	lable_wip_state
ON	lable_wip_state.name	=	'lots.wip_state'
AND lable_wip_state.val		=	lots.wip_state
INNER JOIN [APCSProDB].[trans].[item_labels] AS [item_labels3]  
ON	[item_labels3].[name]	=	'lots.quality_state' 
AND [item_labels3].[val]	=	[lots].[quality_state]
INNER JOIN [APCSProDB].[trans].[item_labels] AS [item_labels2] 
ON	[item_labels2].[name]	=	'lots.process_state' 
and [item_labels2].[val]	=	[lots].[process_state]
LEFT JOIN [APCSProDB].method.jobs
ON	jobs.id					=	lots.act_job_id
INNER JOIN [APCSProDB].[trans].[days] AS [days1]  
ON	[days1].[id]			=	[lots].[in_plan_date_id]
INNER JOIN [APCSProDB].[trans].[days] AS [days2] 
ON	[days2].[id]			=	[lots].[modify_out_plan_date_id]
INNER JOIN [APCSProDB].[method].[device_slips]  
ON	[device_slips].[device_slip_id] = [lots].[device_slip_id]
INNER JOIN [APCSProDB].[method].[device_versions]  
ON	[device_versions].[device_id] = [device_slips].[device_id]
INNER JOIN [APCSProDB].[method].[device_names]  
ON	[device_names].[id]		=	[device_versions].[device_name_id]
INNER JOIN [APCSProDB].[method].[packages]  
ON	[packages].[id]			=	[device_names].[package_id]
INNER JOIN [APCSProDB].[method].[processes]  
ON	[processes].[id]		=	[jobs].[process_id]
LEFT JOIN [APCSProDB].[trans].[special_flows] 
ON	[special_flows].[id]	=	[lots].[special_flow_id]
LEFT JOIN [APCSProDB].[trans].[item_labels] AS [item_labels6]  
ON	[item_labels6].[name]	=	'lots.process_state' 
AND [item_labels6].[val]	=	[special_flows].[process_state]
LEFT JOIN [APCSProDB].[man].[users] 
ON	[users].[id] = [lots].[updated_by]		
WHERE member_lot_id			=	@lot_id  
AND lots.production_category IN (21,22,23)

END
