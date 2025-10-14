-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_detail_abnormal_by_lot_no]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	

    -- Insert statements for procedure here
	SELECT [lots].[id] AS [lot_id]
		, [lots].[lot_no]
		, CASE WHEN [lot_special_flows].[step_no] IS NULL THEN 'MasterFlow' ELSE 'SpecialFlow' END AS [state_flow]
		, CASE WHEN [lots].[is_special_flow] = 1 THEN [lot_special_flows].[step_no] ELSE [lots].[step_no] END AS [step_no_current]
		, [lots].[wip_state]
		, [lots].[quality_state] AS [quality_state_num_master]
		, [qs_master].[label_eng] AS [quality_state_master]
		, [special_flows].[quality_state] AS [quality_state_num_special]
		, [qs_special].[label_eng] AS [quality_state_special]
		, CASE
			WHEN [stop_lot].[is_held] = 1 THEN 
				CASE 
					WHEN (CASE WHEN [lots].[is_special_flow] = 1 THEN [lot_special_flows].[step_no] ELSE [lots].[step_no] END) = [stop_lot].[stop_step_no] THEN 'Yes'
					ELSE 'No' 
				END
			ELSE 
				CASE 
					WHEN [stop_lot].[is_held] IS NULL THEN   
						CASE 
							WHEN [stop_lot_state].[is_held] = 1 THEN 'Yes'
							ELSE 'No'
						END
					ELSE 'No' 
				END
		END AS [state_stop_lot]
		, CASE
			WHEN [stop_lot].[is_held] = 1 THEN 
				CASE 
					WHEN (CASE WHEN [lots].[is_special_flow] = 1 THEN [lot_special_flows].[step_no] ELSE [lots].[step_no] END) = [stop_lot].[stop_step_no] THEN 'Stopping'
					ELSE 'Waiting to stop' 
				END
			ELSE 
				CASE 
					WHEN [stop_lot].[is_held] IS NULL THEN   
						CASE 
							WHEN [stop_lot_state].[is_held] = 1 THEN 'Crossed'
							ELSE ''
						END
					ELSE '' 
				END
		END AS [comment_stop_lot]
		, [stop_lot].[is_held] 
		, [stop_lot].[stop_step_no] AS [stop_lot_step_no]
	FROM [APCSProDB].[trans].[lots]
	LEFT JOIN [APCSProDB].[trans].[special_flows] ON [lots].[id] = [special_flows].[lot_id]
		AND [lots].[special_flow_id] = [special_flows].[id]
		AND [lots].[is_special_flow] = 1
	LEFT JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
		AND [special_flows].[step_no] = [lot_special_flows].[step_no]
	OUTER APPLY (
		SELECT TOP 1 [lot_hold_controls].[is_held]
			, [lot_stop_instructions].[stop_step_no]
		FROM [APCSProDB].[trans].[lot_hold_controls]
		LEFT JOIN [APCSProDB].[trans].[lot_stop_instructions] ON [lots].[id] = [lot_stop_instructions].[lot_id]
		WHERE [lot_hold_controls].[lot_id] = [lots].[id]
			AND [lot_hold_controls].[system_name] = 'lot stop instruction'
			AND [lot_stop_instructions].[stop_step_no] >= IIF([lots].[is_special_flow] = 1, [lot_special_flows].[step_no], [lots].[step_no]) 
	) AS [stop_lot]
	OUTER APPLY (
		SELECT TOP 1 [lot_hold_controls].[is_held]
		FROM [APCSProDB].[trans].[lot_hold_controls]
		WHERE [lot_hold_controls].[lot_id] = [lots].[id]
			AND [lot_hold_controls].[system_name] = 'lot stop instruction'
	) AS [stop_lot_state]
	LEFT JOIN [APCSProDB].[trans].[item_labels] AS [qs_master] ON [qs_master].[name] = 'lots.quality_state'
		AND [qs_master].[val] = [lots].[quality_state]
	LEFT JOIN [APCSProDB].[trans].[item_labels] AS [qs_special] ON [qs_special].[name] = 'lots.quality_state'
		AND [qs_special].[val] = [special_flows].[quality_state]
	WHERE [lots].[lot_no] =  @lot_no;
END