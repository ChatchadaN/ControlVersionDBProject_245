-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_material_set_slips]
	-- Add the parameters for the stored procedure here
	  @mat_set_id   INT				= NULL
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

 
	SELECT  CASE WHEN matlist.id IS NULL THEN 0 ELSE 1 END AS is_checked
			, material_sets.name AS materialname
			, processes.name AS job 
			, material_sets.id	
			, matlist.id   AS material_id
			, matlist.idx
			, matlist.material_group_id AS material_group_id
			, material_sets.process_id  AS Processes
			, productions.name AS productions_name
			, productions.details As  productions_detail
			, material_sets.comment
			, matlist.use_qty 
			, il.label_eng AS use_qty_unit
			, il2.label_eng AS limit_time_unit1
			, time_limit1
			, time_warn1 
			, CASE WHEN matlist.tomson_code IS NULL THEN '' ELSE  CONCAT(ib.reel_count,' reels') END AS tomson_pattern  
	FROM APCSProDB.material.productions  
	INNER JOIN APCSProDB.method.material_set_list AS matlist 
	ON  productions.id = matlist.material_group_id  
	INNER JOIN   APCSProDB.method.material_sets  
	ON material_sets.id =  matlist.id
	INNER JOIN  APCSProDB.method.processes
	ON processes.id =  material_sets.process_id
	LEFT JOIN APCSProDB.method.item_labels il 
	ON il.val = matlist.use_qty_unit AND il.name		= 'material_set_list.use_qty_unit'  
	LEFT JOIN APCSProDB.method.item_labels il2 
	ON il2.val = matlist.limit_time_unit1 AND il2.name	= 'material_set_list.limit_time_unit1'  
	LEFT JOIN APCSProDB.method.incoming_boxs ib 
	ON ib.tomson_code = matlist.tomson_code AND ib.idx	= 1  
	WHERE   material_sets.id		= @mat_set_id
	AND  ISNULL(is_checking,0 )		= 1
	ORDER BY material_sets.name

END
