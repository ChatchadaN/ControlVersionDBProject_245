-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_order_add_special_flow]
	-- Add the parameters for the stored procedure here
	@lotNo VARCHAR(10) = '',
	@is_status INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
	--is_status (0 : Request, 1 : Receive, 2 : Success, 3 : Cancel)
	DECLARE @lot_id int = null
	DECLARE @user_id int = null

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no] )
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [atom].[sp_get_order_add_special_flow] @lotNo = ''' + @lotNo + ''''
		, @lotNo

	--select data
	SELECT [req_spe_flow].[id]
		, [req_spe_flow].[lot_id]
		, TRIM([lot].[lot_no]) AS [Lotno]
		, [req_spe_flow].[step_no]
		, [jobs].[name] AS [Step_no_name]
		, [req_spe_flow].[flow_pattern_id]
		, [flow_pattern].[flow_name] AS [Jobname]
		, [req_spe_flow].[is_occurred]
		, [i_occ].[label_eng] AS [is_occurred_name]
		, [req_spe_flow].[is_status]
		, [i_sta].[label_eng] AS [is_status_name]
		, [req_spe_flow].[comment]
		, [req_spe_flow].[created_at]
		, [req_spe_flow].[created_by]
		, [req_spe_flow].[updated_at]
		, [req_spe_flow].[updated_by]
		, [users].[emp_num]
		, [users].[name]
		, IIF([i_special_mode].[label_eng] is null,'',[i_special_mode].[label_eng]) AS [is_comment_special_mode]
	FROM [APCSProDB].[trans].[request_special_flows] AS [req_spe_flow]
	INNER JOIN [APCSProDB].[trans].[lots] AS [lot] ON [lot].[id] = [req_spe_flow].[lot_id]
	CROSS APPLY (
		SELECT [device_flows].[step_no]
			, [device_flows].[job_id]
		FROM [APCSProDB].[method].[device_flows] 
		WHERE [device_flows].[device_slip_id] = [lot].[device_slip_id]
			AND [device_flows].[step_no] = [req_spe_flow].[step_no]
		UNION ALL
		SELECT [lot_special_flows].[step_no]
			, [lot_special_flows].[job_id]
		FROM [APCSProDB].[trans].[special_flows] AS [sp]
		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] ON [sp].[id] = [lot_special_flows].[special_flow_id]
		WHERE [sp].[lot_id] = [lot].[id]
			AND [lot_special_flows].[step_no] = [req_spe_flow].[step_no]
	) AS [flow]
	CROSS APPLY (
		SELECT [jobs].[name] AS [flow_name] 
		FROM [APCSProDB].[method].[flow_patterns]
		INNER JOIN [APCSProDB].[method].[flow_details] ON [flow_patterns].[id] = [flow_details].[flow_pattern_id]
		LEFT JOIN [APCSProDB].[method].[jobs] ON [flow_details].[job_id] = [jobs].[id]
		WHERE [flow_patterns].[assy_ft_class] = 'S'
			AND [flow_patterns].[id] = [req_spe_flow].[flow_pattern_id]
	) AS [flow_pattern]
	LEFT JOIN [APCSProDB].[method].[jobs] ON [flow].[job_id] = [jobs].[id]
	LEFT JOIN [APCSProDB].[trans].[item_labels] AS [i_occ] ON [i_occ].[name] = 'request_special_flows.is_occurred'
		AND [i_occ].[val] = [req_spe_flow].[is_occurred]
	LEFT JOIN [APCSProDB].[trans].[item_labels] AS [i_sta] ON [i_sta].[name] = 'request_special_flows.is_status'
		AND [i_sta].[val] = [req_spe_flow].[is_status]
	INNER JOIN [APCSProDB].[man].[users] ON [req_spe_flow].[created_by] = [users].[id]
	LEFT JOIN [APCSProDB].[trans].[item_labels] AS [i_special_mode] ON [req_spe_flow].[mode_id] = [i_special_mode].[val] 
		AND [i_special_mode].[name] = 'request_special_flows.mode_id'
	WHERE [req_spe_flow].[is_status] = @is_status
	
END
