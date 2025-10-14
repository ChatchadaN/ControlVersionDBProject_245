-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_allflow_for_add_special]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [Flow].[step_no]
		, CAST([Flow].[step_no] AS VARCHAR(10)) + ' ' + [Flow].[job_name] AS [job_name]
	FROM [APCSProDB].[trans].[lots]
	CROSS APPLY (
		SELECT [step_no]
			, [jobs].[name] AS [job_name]
		FROM [APCSProDB].[method].[device_flows]
		INNER JOIN [APCSProDB].[method].[jobs] ON [device_flows].[job_id] = [jobs].[id]
		WHERE [device_flows].[device_slip_id] = [lots].[device_slip_id]
			AND [device_flows].[is_skipped] = 0
		UNION
		SELECT [lot_special_flows].[step_no]
			, [jobs].[name] AS [job_name]
		FROM [APCSProDB].[trans].[special_flows] 
		INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
				INNER JOIN [APCSProDB].[method].[jobs] ON [lot_special_flows].[job_id] = [jobs].[id]
		WHERE [special_flows].[lot_id] = [lots].[id]
	) AS [Flow]
	WHERE [lots].[lot_no] = @lot_no;
END