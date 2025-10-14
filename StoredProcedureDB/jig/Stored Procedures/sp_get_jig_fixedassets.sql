-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_jig_fixedassets]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	SELECT	  jigs.id	
			, processes.[name]		AS process_name
			, categories.id			AS categories_id
			, categories.[name]		AS category_name
			, productions.[name]	AS production_name
			, productions.id		AS productions_id
			, ISNULL(barcode, '') AS barcode
			, ISNULL(smallcode, '') AS smallcode
			, ISNULL(qrcodebyuser, '') AS  qrcodebyuser
			, ISNULL([status] , '') AS  [status]
			, ISNULL(fixed_asset_num,'') AS  fixed_asset_num
			, ISNULL(jigs.root_jig_id,'') AS  root_jig_id
	FROM APCSProDB.trans.jigs
	INNER JOIN APCSProDB.jig.productions
	ON jigs.jig_production_id = productions.id 
	INNER JOIN APCSProDB.jig.categories
	ON categories.id  = productions.category_id
	INNER JOIN APCSProDB.method.processes
	ON processes.id  =  categories.lsi_process_id
	LEFT JOIN APCSProDB.jig.fixed_assets
	ON jigs.id =  fixed_assets.jig_id
	WHERE barcode LIKE 'EQP%'  
	AND  root_jig_id  = jigs.id
 

END
