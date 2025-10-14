-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_jig_fixedassets_root]
(	-- Add the parameters for the stored procedure here
		@root_jig_id INT   =  NULL
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	
SELECT CASE WHEN (num > 1  AND id = root_jig_id ) THEN
'MASTER '+ category_name  ELSE '' END  AS [Description]
	, * FROM (
	SELECT	 COUNT(fixed_assets_root.fixed_asset_num) OVER (PARTITION BY jigs.root_jig_id  ) AS num
			, jigs.id	
			, processes.[name]		AS process_name
			, categories.id			AS categories_id
			, categories.[name]		AS category_name
			, productions.[name]	AS production_name
			, productions.id		AS productions_id
			, barcode	
			, smallcode	
			, ISNULL(qrcodebyuser,'')	AS qrcodebyuser
			, [status] 
			, ISNULL(fixed_assets_root.fixed_asset_num ,'') AS fixed_asset_num
			, jigs.root_jig_id
			, ISNULL(fixed_assets.fixed_asset_num ,'') AS fixed_asset
	FROM APCSProDB.trans.jigs
	INNER JOIN APCSProDB.jig.productions
	ON jigs.jig_production_id = productions.id 
	INNER JOIN APCSProDB.jig.categories
	ON categories.id  = productions.category_id
	INNER JOIN APCSProDB.method.processes
	ON processes.id  =  categories.lsi_process_id
	LEFT JOIN APCSProDB.jig.fixed_assets
	ON jigs.id =  fixed_assets.jig_id
	LEFT JOIN APCSProDB.jig.fixed_assets AS fixed_assets_root
	ON jigs.root_jig_id =  fixed_assets_root.jig_id
	WHERE barcode LIKE 'EQP%'   
	AND root_jig_id = IIF(@root_jig_id <> 0 ,@root_jig_id ,root_jig_id ) 
)	AS root_jig
ORDER BY root_jig.root_jig_id  
 

END
