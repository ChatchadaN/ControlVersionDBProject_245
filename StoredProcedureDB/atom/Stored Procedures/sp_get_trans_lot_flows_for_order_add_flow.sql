
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_trans_lot_flows_for_order_add_flow]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10)	= ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
	DECLARE @step_no_now INT
		, @device_slip_id INT
		, @lot_id INT

	SELECT @lot_id = [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no;

	---- # set parameter
	SELECT @step_no_now = ( CASE WHEN ISNULL([lots].[is_special_flow], 0) = 1 THEN [lot_special_flows].[step_no] ELSE [lots].[step_no] END ) 
		, @device_slip_id = [lots].[device_slip_id]
	FROM [APCSProDB].[trans].[lots]
	LEFT JOIN [APCSProDB].[trans].[special_flows] ON [lots].[is_special_flow] = 1
		AND [lots].[special_flow_id] = [special_flows].[id]
	LEFT JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
		AND [special_flows].[step_no] = [lot_special_flows].[step_no]
	WHERE [lots].[id] = @lot_id;

	---- # select result
	SELECT [StepNo].[step_no]
		, [StepNo].[is_skipped]
		, [jobs].[name] AS [job_name]
		, [StepNo].[color_text]
		, CASE
			WHEN [StepNo].[is_skipped] = 1 THEN '#C7C7C7'
			WHEN [StepNo].[is_skipped] = 0 AND [StepNo].[step_no] = @step_no_now THEN '#FFFD07'
			ELSE NULL 
		END AS [color_label]
		, CASE
			WHEN [StepNo].[step_no] = @step_no_now THEN 1
			ELSE 0 
		END AS [is_occurred]
	FROM ( ----# from data step no all (master,special)
		---- # master_flows
		SELECT [device_flows].[step_no]
			, [device_flows].[is_skipped]
			, [device_flows].[job_id]
			, 0 as [special_flow_id]
			, 0 as [lot_special_flow_id]
			, '#000000' AS [color_text]
		FROM [APCSProDB].[method].[device_flows] 
		WHERE [device_flows].[device_slip_id] = @device_slip_id
		UNION ALL
		---- # special_flows
		SELECT [lot_special_flows].[step_no]
			, [lot_special_flows].[is_skipped]
			, [lot_special_flows].[job_id]
			, [special_flows].[id] as [special_flow_id]
			, [lot_special_flows].[id] as [lot_special_flow_id]
			, '#CC00B7' AS [color_text]
		FROM [APCSProDB].[trans].[special_flows] 
		INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [lot_special_flows].[special_flow_id] = [special_flows].[id]
		WHERE [special_flows].[lot_id] = @lot_id
	) AS [StepNo]
	INNER JOIN [APCSProDB].[method].[jobs] ON [StepNo].[job_id] = [jobs].[id]
	WHERE [StepNo].[step_no] >= @step_no_now
	ORDER BY [StepNo].[step_no];
END