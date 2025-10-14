-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_lot_materials_ver_001]
	 @lot_no VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT [materials].[barcode]
		, [productions].[name] AS [production_name]
		, [categories].[name] AS [category_name]
		, [materials].[lot_no] AS [material_lot_no]
		, [jobs].[name] AS [job_name]
	FROM [APCSProDB].[trans].[materials]
	INNER JOIN [APCSProDB].[material].[productions]
		ON [materials].[material_production_id] = [productions].[id] 
	INNER JOIN [APCSProDB].[trans].[lot_materials] 
		ON [materials].[id] = [lot_materials].[material_id]
	INNER JOIN APCSProDB.trans.lot_process_records 
		ON [lot_process_records].[id] = [lot_materials].[process_record_id]
	INNER JOIN [APCSProDB].[trans].[lots] 
		ON [lot_process_records].[lot_id] = [lots].[id]
	INNER JOIN [APCSProDB].[method].[processes]
		ON [lot_process_records].[process_id] = [processes].[id] 
	INNER JOIN [APCSProDB].[method].[jobs] 
		ON [lot_process_records].[job_id] = [jobs].[id] 
	INNER JOIN [APCSProDB].[material].[categories] 
		ON [categories].[id] = [productions].[category_id]
	WHERE [lots].[lot_no] = @lot_no
	UNION ALL
	SELECT jigs.barcode
		, productions.name AS production_name
		, categories.name AS category_name
		, jigs.lot_no AS material_lot_no
		, jobs.name AS job_name
	FROM [APCSProDB].[trans].[jigs] 
	INNER JOIN [APCSProDB].[jig].[productions] 
		ON [jigs].[jig_production_id] = [productions].[id]
	INNER JOIN [APCSProDB].[trans].[lot_jigs] 
		ON [jigs].[id] = [lot_jigs].[jig_id] 
	INNER JOIN [APCSProDB].[trans].[lot_process_records]
		ON [lot_process_records].[id] = [lot_jigs].[process_record_id] 
	INNER JOIN [APCSProDB].[trans].[lots] 
		ON [lot_process_records].[lot_id] = [lots].[id]
	INNER JOIN [APCSProDB].[method].[processes] 
		ON [lot_process_records].[process_id] = [processes].[id] 
	INNER JOIN [APCSProDB].[method].[jobs] 
		ON [lot_process_records].[job_id] = [jobs].[id] 
	INNER JOIN [APCSProDB].[jig].[categories] 
		ON [categories].[id] = [productions].[category_id]
	WHERE lots.lot_no = @lot_no;
	 
END
