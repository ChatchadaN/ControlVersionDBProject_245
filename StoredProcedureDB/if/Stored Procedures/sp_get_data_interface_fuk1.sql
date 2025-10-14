-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_get_data_interface_fuk1]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [wf_details].[chip_model_name] AS [CHIPMODELNAME]
		, [materials].[lot_no] AS [WFLOTNO]
		, [wf_details].[seq_no] AS [SEQNO]
		, CAST([in_quantity] AS INT) AS [WFCOUNT]
		, [wf_details].[chip_in] AS [CHIPCOUNT]
		, FORMAT([materials].[created_at], 'yyMMdd') AS [STOCKDATE]
		, IIF([materials].[qc_state] = 1, '1', ' ') AS [HOLDFLAG]
		, [material_arrival_records].[invoice_no] AS [INVOICENO]
		, [wf_details].[case_no] AS [CASENO]
		, [wf_datas].[WFDATA]
		, CEILING(LEN([wf_datas].[WFDATA]) / 72.0) AS [COUNTROW_WFDATA]
		, LEN([wf_datas].[WFDATA]) AS [COUNTLEN_WFDATA]
	FROM [APCSProDB].[trans].[materials]
	INNER JOIN [APCSProDB].[trans].[material_arrival_records] ON [materials].[arrival_material_id] = [material_arrival_records].[id]
	INNER JOIN [APCSProDB].[trans].[wf_details] ON [materials].[id] = [wf_details].[material_id]
	CROSS APPLY (
		SELECT STRING_AGG(RIGHT('000' + CAST([wf_datas].[idx] AS VARCHAR(3)), 3) + RIGHT('000000' + CAST([wf_datas].[qty] AS VARCHAR(6)), 6), '') AS [WFDATA]
		FROM [APCSProDB].[trans].[wf_datas] 
		WHERE [wf_datas].[material_id] = [materials].[id]
			AND [wf_datas].[is_enable] = 1
	) AS [wf_datas];
END
