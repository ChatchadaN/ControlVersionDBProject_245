
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_trans_lots_beforeplan]	
-- Add the parameters for the stored procedure here	
	 @datestart varchar(50)
	,@dateend varchar(50)
	,@lot_no varchar(10) = '%'
	,@process varchar(50) = '%'
	,@package varchar(50) = '%'
	,@package_group varchar(50) = '%'	
	,@device varchar(50) = '%'	
	,@job varchar(50) = '%'

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT	  [lots].[id]					AS LotId
			, [lots].[lot_no]				AS LotNo
			, [packages].[name]				AS Package 
			, [lots].[act_package_id]		AS PackageId 
			, [device_names].[name]			AS Device
			, [lots].[step_no]				AS StepNo
			, case when [lots].[is_special_flow] = 1 then [job2].[name] ELSE [jobs].[name] end AS FlowName
			, [lots].[qty_in]				AS Input
			, [lots].[qty_pass]				AS Good
			, [lots].[qty_fail]				AS NG
			, [days1].[date_value]			AS InputDate
			, [days2].[date_value]			AS ShipDate
			, [item_labels1].[label_eng]	AS WipState
			, CASE WHEN [lots].[is_special_flow] = 1 THEN [item_labels6].[label_eng] ELSE [item_labels2].[label_eng] END AS ProcessState
			, [item_labels3].[label_eng]	AS QualityState
			, [item_labels4].[label_eng]	AS FirstIns
			, [item_labels5].[label_eng]	AS FinalIns
			, [lots].[is_special_flow]		AS IsSpecialFlow
			, [lots].[priority]				AS [Priority]
			, [lots].[finished_at]			AS EndLotTime
			, [machines].[name]				AS MachineName
			, [lots].[container_no]			AS ContainerNo
			, [lots].[std_time_sum]			AS STDTimeSum
			, [lots].[m_no]					AS MarkingNo
			, ''							AS QCComment
			, CASE WHEN [device_names].[tp_rank] = '' OR [device_names].[tp_rank] IS NULL THEN '-' ELSE [device_names].[tp_rank] END  AS TPRank
			, CASE WHEN DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 THEN 'OrderDelay' ELSE 'Normal' END AS [Delay]
			, DATEDIFF(DAY,[days2].[date_value],GETDATE()) AS DelayDay
			, [lots].[updated_at]			AS [Time]
			, [users1].[emp_num]			AS Operator
			, [package_groups].[name]		AS PackageGroup
			, [processes].[name]			AS ProcessName
			, 'http://webserv.thematrix.net/Atom/User/DetailsLotBeforePlan?Id='+convert(varchar(50),[lots].[id])+'&Lotno='+convert(varchar(10),[lots].[lot_no])+'&Package='+trim([packages].[name])+'&Device='+trim([device_names].[name])+'&TPRank='+(case when [device_names].[tp_rank] = '' or [device_names].[tp_rank] is null then '-' else [device_names].[tp_rank] end) AS Link
	FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) 
	INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) on [packages].[id] = [lots].[act_package_id]
	INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
	INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) on [device_names].[id] = [lots].[act_device_name_id]
	INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) on [jobs].[id] = [lots].[act_job_id]
	INNER JOIN [APCSProDB].[method].[processes] WITH (NOLOCK) on [processes].[id] = [lots].[act_process_id]
	INNER JOIN [APCSProDB].[trans].[days] AS [days1] WITH (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
	INNER JOIN [APCSProDB].[trans].[days] AS [days2] WITH (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
	LEFT JOIN  [APCSProDB].[trans].[item_labels] AS [item_labels1] WITH (NOLOCK) on [item_labels1].[name] = 'lots.wip_state' and [item_labels1].[val] = [lots].[wip_state]
	LEFT JOIN  [APCSProDB].[trans].[item_labels] AS [item_labels2] WITH (NOLOCK) on [item_labels2].[name] = 'lots.process_state' and [item_labels2].[val] = [lots].[process_state]
	LEFT JOIN  [APCSProDB].[trans].[item_labels] AS [item_labels3] WITH (NOLOCK) on [item_labels3].[name] = 'lots.quality_state' and [item_labels3].[val] = [lots].[quality_state]
	LEFT JOIN  [APCSProDB].[trans].[item_labels] AS [item_labels4] WITH (NOLOCK) on [item_labels4].[name] = 'lots.first_ins_state' and [item_labels4].[val] = [lots].[first_ins_state]
	LEFT JOIN  [APCSProDB].[trans].[item_labels] AS [item_labels5] WITH (NOLOCK) on [item_labels5].[name] = 'lots.final_ins_state' and [item_labels5].[val] = [lots].[final_ins_state]
	LEFT JOIN  [APCSProDB].[mc].[machines] WITH (NOLOCK) on [machines].[id] = [lots].[machine_id]
	LEFT JOIN  [APCSProDB].[man].[users] AS [users1] WITH (NOLOCK) on [users1].[id] = [lots].[updated_by]
	LEFT JOIN  [APCSProDB].[trans].[special_flows] WITH (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] and [lots].[special_flow_id] = 1
	LEFT JOIN  [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id]
	LEFT JOIN  [APCSProDB].[method].[jobs] AS [job2] WITH (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
	LEFT JOIN  [APCSProDB].[trans].[item_labels] AS [item_labels6] WITH (NOLOCK) on [item_labels2].[name] = 'lots.process_state' and [item_labels2].[val] = [special_flows].[process_state]
	WHERE [lots].[wip_state]		IN (10,20,0)
	AND [packages].[is_enabled]		= 1
	--AND ([days1].[date_value]	>=	 convert(date, getdate()) 
	AND ([days1].[date_value]	>	 convert(date, getdate()) 
	AND YEAR([days1].[date_value]) <= YEAR(convert(date, getdate())))
	AND lot_no					LIKE '%'+@lot_no+'%'
	AND [package_groups].[name] LIKE @package_group
	AND [packages].[name]		LIKE @package
	AND [device_names].[name]	LIKE @device
	AND [processes].[name]		LIKE @process
	AND [jobs].[name]			LIKE @job
	--AND [days1].[date_value]	BETWEEN @datestart AND @dateend
	ORDER BY [lots].[lot_no] 


END
