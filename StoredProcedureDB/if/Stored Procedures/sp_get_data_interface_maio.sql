-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_get_data_interface_maio]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [STOCKDATE]
		, [OUTDIV]
		, [RECDIV]
		, [CHIPMODELNAME]
		, SUM([WFCOUNT]) AS[SUMWFCOUNT]
		, SUM([CHIPCOUNT]) AS[SUMCHIPCOUNT]
		, [INVOICENO]
		, [SLIPNO]
		, [SLIPNOEDA]
		, [ORDERNO]
		, [WFCOUNT_FAIL]
	FROM (
		SELECT CONVERT(DATE, [materials].[created_at]) AS [STOCKDATE]
			, [wf_details].[out_div] AS [OUTDIV]
			, [wf_details].[rec_div] AS [RECDIV]
			, [wf_details].[chip_model_name] AS [CHIPMODELNAME]
			, CAST([materials].[in_quantity] AS INT) AS [WFCOUNT]
			, [wf_details].[chip_in] AS [CHIPCOUNT]
			, [material_arrival_records].[invoice_no] AS [INVOICENO]
			, [wf_details].[slip_no] AS [SLIPNO]
			, [wf_details].[slip_no_eda] AS [SLIPNOEDA]
			, [wf_details].[order_no] AS [ORDERNO]
			, CAST([materials].[fail_quantity] AS INT) AS [WFCOUNT_FAIL]
		FROM [APCSProDB].[trans].[materials]
		INNER JOIN [APCSProDB].[trans].[material_arrival_records] ON [materials].[arrival_material_id] = [material_arrival_records].[id]
		INNER JOIN [APCSProDB].[trans].[wf_details] ON [materials].[id] = [wf_details].[material_id]
		WHERE [wf_details].[fuk2_flag] = 0
	) AS [CHIPNYUKO]
	GROUP BY[STOCKDATE]
		, [OUTDIV]
		, [RECDIV]
		, [CHIPMODELNAME]
		, [INVOICENO]
		, [SLIPNO]
		, [SLIPNOEDA]
		, [ORDERNO]
		, [WFCOUNT_FAIL];
END
