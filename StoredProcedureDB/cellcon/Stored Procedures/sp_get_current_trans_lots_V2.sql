-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_current_trans_lots_V2]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT TOP 1 [lots].[id]					as LotId
			 , [lots].[lot_no]				as LotNo
			 , [packages].[name]			as Package
			 , [packages].[short_name]		as PackageShortname  
			 , [lots].[act_package_id]		as PackageId 
			 , [device_names].[assy_name]		as AssyDevice
			 , [device_names].[name]		as Device
			 , CASE WHEN [label].user_model_name IS NULL OR [label].user_model_name = ''	THEN [device_names].name
																							ELSE [label].user_model_name	END AS CustomerDevice
			 , [device_names].[ft_name]		AS FT_Name
			 , [device_names].[rank]		AS FTRank
			 , [device_names].[tp_rank]		AS TPRank
			 , CONCAT([device_names].[rank], [device_names].[tp_rank])									    AS FullRank
			 --, CONCAT([device_names].[tp_rank], ' Ver ' , CONVERT(varchar(3),[device_slips].[version_num]))	AS TPRankwVersion
			 , CASE WHEN [lots].[is_special_flow] = 1	THEN [special_flows].step_no 
		 												ELSE [lots].[step_no]	END AS StepNo
			 , CASE WHEN [lots].[is_special_flow] = 1	THEN [job2].[name] 
		 												ELSE [jobs].[name]		END	AS FlowName
			 , CASE WHEN [lots].[is_special_flow] = 1	THEN [job2].[id] 
		 												ELSE [jobs].[id]		END AS FlowId       
			 , [lots].[qty_in]				AS Input
			 , [lots].[qty_pass]			AS Good
			 , [lots].[qty_fail]			AS NG
			 , [lots].[qty_frame_in]		AS FrameInput
			 , [lots].[qty_frame_pass]		AS FramePass
			 , [lots].[qty_frame_fail]		AS FrameFail
			 , [lots].[qty_last_pass]		AS GoodBeforeProcess
			 , [lots].[qty_last_fail]		AS NgBeforeProcess
			 , [lots].[qty_pass_step_sum]	AS GoodStepSum
			 , [lots].[qty_fail_step_sum]	AS NgStepSum
			 , [lots].[qty_p_nashi]			AS PNashi
			 , [lots].[qty_front_ng]		AS FrontNg
			 , [lots].[qty_marker]			AS MarkerNg
			 , [lots].[qty_cut_frame]		AS CutFrame
			 , [packages].[pcs_per_work]	AS PcsPerFrame
			 , [lots].[qty_combined]		AS Combine
			 , [lots].[qty_out]				AS Shipment
			 , [lots].[qty_hasuu]			AS Surplus
			 --, [denpyo].[HASU_LOT]			as CategoryLot
			 , [days1].[date_value]			AS InputDate
			 , [days2].[date_value]			AS ShipDate
			 , [item_labels1].[label_eng]	AS WipState
			 , CASE WHEN [lots].[is_special_flow] = 1	THEN [item_labels6].[label_eng] 
		 												ELSE [item_labels2].[label_eng]	END AS ProcessState
			 , [item_labels3].[label_eng]	AS QualityState
			 , [item_labels4].[label_eng]	AS FirstIns
			 , [item_labels5].[label_eng]	AS FinalIns
			 , [lots].[is_special_flow]		AS IsSpecialFlow
			 , [lots].[priority]			AS [Priority]
			 , [lots].[finished_at]			AS EndLotTime
			 , [machines].[name]			AS MachineName
			 , [lots].[container_no]		AS ContainerNo
			 , [lots].[std_time_sum]		AS STDTimeSum
			 , [lots].[m_no]				AS MarkingNo
			 , [comments].[val]				AS QCComment
			 , CASE WHEN DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0	THEN 'OrderDelay' 
																			ELSE 'Normal'	END AS [Delay]
			 , DATEDIFF(DAY,[days2].[date_value],GETDATE())	AS DelayDay
			 , [lots].[updated_at]			AS [Time]
			 , [users1].[emp_num]			AS Operator
			 , [package_groups].[name]		AS PackageGroup
			 , [processes].[name]			AS ProcessName
			 , [processes].id				AS ProcessID
			 , [lots].[production_category] AS ProductionCategory
			 , CASE WHEN [lots].[special_flow_id] IS NULL	THEN '0' 
		 													ELSE [lots].[special_flow_id]	END AS SpecialFlowId   
			 --, CASE
				--	WHEN [FORM_NAME_1] IS NOT NULL AND [FORM_NAME_1] != '' THEN [denpyo].[FORM_NAME_1]
				--	WHEN [FORM_NAME_2] IS NOT NULL AND [FORM_NAME_2] != '' THEN [denpyo].[FORM_NAME_2]
				--	WHEN [FORM_NAME_3] IS NOT NULL AND [FORM_NAME_3] != '' THEN [denpyo].[FORM_NAME_3]
				--	WHEN [FORM_NAME_4] IS NOT NULL AND [FORM_NAME_4] != '' THEN [denpyo].[FORM_NAME_4]
				--	WHEN [FORM_NAME_6] IS NOT NULL AND [FORM_NAME_6] != '' THEN [denpyo].[FORM_NAME_6]
				--	ELSE NULL
				--	END						AS DenpyoPackageName
			 --, [denpyo].[PACKAGE_FORM_NAME] AS DenpyoDeviceName
			 , [device_names].[is_memory_device]	AS IsMemoryDevice
			 , [device_flows].[ng_retest_permitted]	AS isNGRetestPermitted
			 , [lots].[pc_instruction_code]			AS PCCode
			 , [lots].[qty_fail_details]			AS NGDetails
			 , [lots].[e_slip_id]					AS ESLCardId
			 , CASE WHEN lot_multi_chips.child_lot_id IS NOT NULL	THEN 'True'
																	ELSE 'False'			END AS IsChildLot 

		FROM [APCSProDB].[trans].[lots]										with (NOLOCK)

		INNER JOIN [APCSProDB].[method].[device_flows]						with (NOLOCK) ON [device_flows].device_slip_id	 = [lots].device_slip_id 
																						 AND [device_flows].job_id	= [lots].act_job_id
		INNER JOIN [APCSProDB].[method].[device_slips]						with (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[packages]							with (NOLOCK) ON [packages].[id]		= [lots].[act_package_id]
		INNER JOIN [APCSProDB].[method].[package_groups]					with (NOLOCK) ON [package_groups].[id]	= [packages].[package_group_id]
		INNER JOIN [APCSProDB].[method].[device_names]						with (NOLOCK) ON [device_names].[id]	= [lots].[act_device_name_id]
		LEFT  JOIN [APCSProDB].[method].[multi_labels]	AS [label]			with (NOLOCK) ON [label].device_name	= [device_names].name
		INNER JOIN [APCSProDB].[method].[jobs]								with (NOLOCK) ON [jobs].[id]			= [lots].[act_job_id]
		INNER JOIN [APCSProDB].[method].[processes]							with (NOLOCK) ON [processes].[id]		= [lots].[act_process_id]
		INNER JOIN [APCSProDB].[trans].[days]			AS [days1]			with (NOLOCK) ON [days1].[id]			= [lots].[in_plan_date_id]
		INNER JOIN [APCSProDB].[trans].[days]			AS [days2]			with (NOLOCK) ON [days2].[id]			= [lots].[out_plan_date_id]
		INNER JOIN [APCSProDB].[trans].[item_labels]	AS [item_labels1]	with (NOLOCK) ON [item_labels1].[name]	= 'lots.wip_state'		 
																						 AND [item_labels1].[val]	= [lots].[wip_state]
		INNER JOIN [APCSProDB].[trans].[item_labels]	AS [item_labels2]	with (NOLOCK) ON [item_labels2].[name]	= 'lots.process_state'	 
																					     AND [item_labels2].[val]	= [lots].[process_state]
		INNER JOIN [APCSProDB].[trans].[item_labels]	AS [item_labels3]	with (NOLOCK) ON [item_labels3].[name]	= 'lots.quality_state'	 
																						 AND [item_labels3].[val]	= [lots].[quality_state]
		LEFT  JOIN [APCSProDB].[trans].[item_labels]	AS [item_labels4]	with (NOLOCK) ON [item_labels4].[name]	= 'lots.first_ins_state' 
																						 AND [item_labels4].[val]	= [lots].[first_ins_state]
		LEFT  JOIN [APCSProDB].[trans].[item_labels]	AS [item_labels5]	with (NOLOCK) ON [item_labels5].[name]	= 'lots.final_ins_state' 
																						 AND [item_labels5].[val]	= [lots].[final_ins_state]
		LEFT  JOIN [APCSProDB].[mc].[machines]								with (NOLOCK) ON [machines].[id]		= [lots].[machine_id]
		LEFT  JOIN [APCSProDB].[trans].[comments]							with (NOLOCK) ON [comments].[id]		= [lots].[qc_comment_id]
		LEFT  JOIN [APCSProDB].[man].[users]			AS [users1]			with (NOLOCK) ON [users1].[id]			= [lots].[updated_by]
		LEFT  JOIN [APCSProDB].[trans].[special_flows]						with (NOLOCK) ON [special_flows].[id]		= [lots].[special_flow_id]	
																						 AND [lots].[is_special_flow]	= 1
																						 AND [special_flows].wip_state	= 20
		LEFT  JOIN [APCSProDB].[trans].[lot_special_flows]					with (NOLOCK) ON [lot_special_flows].[special_flow_id]	= [special_flows].[id]
			 																			 AND [lot_special_flows].step_no			= [special_flows].step_no
		LEFT  JOIN [APCSProDB].[method].[jobs]			AS [job2]			with (NOLOCK) ON [job2].[id]			= [lot_special_flows].[job_id]
		LEFT  JOIN [APCSProDB].[trans].[item_labels]	AS [item_labels6]	with (NOLOCK) ON [item_labels6].[name]	= 'lots.process_state'
			 																			 AND [item_labels6].[val]	= [special_flows].[process_state]
		LEFT  JOIN [APCSProDB].[trans].[lot_multi_chips]					with (NOLOCK) ON [APCSProDB].trans.lot_multi_chips.child_lot_id = [APCSProDB].trans.lots.id
		
		WHERE [item_labels1].[val] in ('20') 
		  AND [packages].[is_enabled] = 1 
		  AND [lots].[lot_no] = @lot_no

		ORDER BY [lots].[lot_no]
	END
