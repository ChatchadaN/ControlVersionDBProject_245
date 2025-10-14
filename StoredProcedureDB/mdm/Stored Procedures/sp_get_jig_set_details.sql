-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_jig_set_details]
	-- Add the parameters for the stored procedure here
	  @id   INT  = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT    jig_set_list.id
			, jig_set_list.idx
			, jig_set_list.jig_group_id
			, jig_set_list.jig_set_id
			, processes.name		AS Processes
			, jig_sets.name			AS JigName
			, productions.name		AS Productions 
			, categories.name		AS Categories
			, jig_set_list.use_qty	AS use_qty
			, item_labels.label_eng AS use_qty_unit 
			, jig_set_list.use_qty_unit  AS qty_unit_code
	FROM APCSProDB.method.jig_set_list 
    INNER JOIN APCSProDB.method.jig_sets 
	ON jig_sets.id			= jig_set_list.jig_set_id  
    INNER JOIN APCSProDB.jig.productions  
	ON productions.id		=  jig_set_list.jig_group_id 
	AND ISNULL(productions.is_disabled, 0)   <> 1
    INNER JOIN APCSProDB.jig.categories 
	ON categories.id		= productions.category_id 
    INNER JOIN APCSProDB.method.processes 
	ON categories.lsi_process_id  = processes.id 
    LEFT JOIN APCSProDB.jig.item_labels
	ON item_labels.val		= jig_set_list.use_qty_unit  
   -- AND item_labels.name	= 'jig_set_list.use_qty_unit' 
	WHERE jig_set_id		=  @id
	ORDER BY jig_sets.name
 

END
