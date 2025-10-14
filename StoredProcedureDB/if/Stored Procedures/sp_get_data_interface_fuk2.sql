-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_get_data_interface_fuk2]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [wf_details].[chip_model_name] AS [CHIPMODELNAME]
		, [materials].[lot_no] AS [WFLOTNO]
		, [wf_details].[seq_no] AS [SEQNO]
		, CAST([materials].[in_quantity] AS INT) AS [WFCOUNT]
		, [wf_details].[chip_in] AS [CHIPCOUNT]
		, FORMAT([materials].[created_at], 'yyMMdd') AS [STOCKDATE]
	FROM [APCSProDB].[trans].[materials]
	INNER JOIN [APCSProDB].[trans].[material_arrival_records] [mat_ar] ON [materials].[arrival_material_id] = [mat_ar].[id]
	INNER JOIN [APCSProDB].[trans].[wf_details] ON [materials].[id] = [wf_details].[material_id]
	WHERE [materials].[location_id] = 16
		AND [materials].[material_state] IN (1,2);
END
