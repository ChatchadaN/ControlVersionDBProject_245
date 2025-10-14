-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_lot_materials_ver_002]
	 @lot_no VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT DISTINCT [material_jig].[barcode]
		, [material_jig].[production_name]
		, [material_jig].[category_name]
		, [material_jig].[material_lot_no]
		, [jobs].[name] AS [job_name]
		, [jobs].[seq_no]
	FROM (
		SELECT [jigs].[barcode]
			, [jigs].[lot_no] AS [material_lot_no]
			, [lot_jigs].[process_record_id]
			, [productions].[category_id]
			, [productions].[name] AS [production_name]
			, [categories].[name] AS [category_name]
		FROM [APCSProDB].[trans].[jigs]
		INNER JOIN [APCSProDB].[jig].[productions] ON [jigs].[jig_production_id] = [productions].[id]
		INNER JOIN [APCSProDB].[trans].[lot_jigs] ON [jigs].[id] = [lot_jigs].[jig_id] 
		INNER JOIN [APCSProDB].[jig].[categories] ON [productions].[category_id] = [categories].[id]
		UNION ALL
		SELECT [materials].[barcode]
			, [materials].[lot_no] AS [material_lot_no]
			, [lot_materials].[process_record_id]
			, [productions].[category_id]
			, [productions].[name] AS [production_name]
			, [categories].[name] AS [category_name]
		FROM [APCSProDB].[trans].[materials]
		INNER JOIN [APCSProDB].[material].[productions] ON [materials].[material_production_id] = [productions].[id] 
		INNER JOIN [APCSProDB].[trans].[lot_materials] ON [materials].[id] = [lot_materials].[material_id]
		INNER JOIN [APCSProDB].[material].[categories] ON [productions].[category_id] = [categories].[id]
	) AS [material_jig]
	INNER JOIN [APCSProDB].[trans].[lot_process_records] ON [lot_process_records].[id] = [material_jig].[process_record_id] 
	INNER JOIN [APCSProDB].[trans].[lots] ON [lot_process_records].[lot_id] = [lots].[id]
	INNER JOIN [APCSProDB].[method].[processes] ON [lot_process_records].[process_id] = [processes].[id]
	INNER JOIN [APCSProDB].[method].[jobs] ON [lot_process_records].[job_id] = [jobs].[id] 
	WHERE [lots].[lot_no] = @lot_no
	ORDER BY [jobs].[seq_no] ASC;
END
