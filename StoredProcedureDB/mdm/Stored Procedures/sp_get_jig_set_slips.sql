-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_jig_set_slips]
	-- Add the parameters for the stored procedure here
	  @jig_set_id   INT = NULL
	 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 
	--SELECT jig_sets.id , jig_sets.name,jig_sets.code, jig_sets.comment, processes.name  FROM  APCSProDB.method.jig_sets 
	--INNER JOIN  APCSProDB.method.processes 
	--ON jig_sets.process_id   = processes.id 
	--WHERE jig_sets.name = @package_name AND jig_sets.process_id  =  @process_id 
	-- AND  ISNULL(is_disable, 0) = 0 



	SELECT    jig_set_list.id
			, jig_set_list.idx
			, jig_set_list.jig_set_id
			, jig_set_list.jig_group_id
			, processes.name		AS Processes
			, jig_sets.name			AS JigName
			, productions.name		AS Productions 
			, categories.name		AS Categories
			, jig_set_list.use_qty	AS use_qty
			, ISNULL(item_labels.label_eng,'') AS use_qty_unit 
	FROM APCSProDB.method.jig_set_list 
    INNER JOIN APCSProDB.method.jig_sets 
	ON jig_sets.id			= jig_set_list.jig_set_id  
    INNER JOIN APCSProDB.jig.productions  
	ON productions.id		=  jig_set_list.jig_group_id 
    INNER JOIN APCSProDB.jig.categories 
	ON categories.id		= productions.category_id 
    INNER JOIN APCSProDB.method.processes 
	ON categories.lsi_process_id  = processes.id 
   LEFT JOIN [APCSProDB].jig.item_labels
	ON item_labels.val		= jig_set_list.use_qty_unit  
	WHERE jig_sets.id = @jig_set_id
	AND  ISNULL(is_disable, 0) = 0 
	ORDER BY jig_sets.name
 

END
