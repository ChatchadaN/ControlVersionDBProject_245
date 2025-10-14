-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_material_onmachine] 
	-- Add the parameters for the stored procedure here
	@MCNo AS VARCHAR(50) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   	SELECT        APCSProDB.mc.machines.name AS MCNo, 
				  APCSProDB.trans.machine_materials.material_id, 
				  APCSProDB.trans.materials.barcode, 
				  APCSProDB.trans.materials.process_state, 
				  APCSProDB.trans.materials.material_state, 
				  APCSProDB.material.productions.name AS SubType,
				  categories.name AS Type,
				  categories.short_name,
				  APCSProDB.mc.machines.id AS MC_ID,
				  productions.expiration_value AS STD_LifeTime,
				  materials.quantity 
				  , ISNULL(extended_limit_date , materials.limit_date )    AS   limit_date
				  --, MixAGPaste.StartTimeMix + Material.STDLifeTimeUser		AS PreformExp
				  ,'' AS PreformExp
	FROM  APCSProDB.mc.machines
    INNER JOIN APCSProDB.trans.machine_materials 
	ON APCSProDB.mc.machines.id = APCSProDB.trans.machine_materials.machine_id 
    INNER JOIN APCSProDB.trans.materials 
	ON APCSProDB.trans.machine_materials.material_id = APCSProDB.trans.materials.id 
    INNER JOIN APCSProDB.material.productions 
	ON  materials.material_production_id = APCSProDB.material.productions.id 
    INNER JOIN APCSProDB.material.categories 
	ON productions.category_id = APCSProDB.material.categories.id 
	--LEFT JOIN  DBx.MAT.MixAGPaste  
	--ON MixAGPaste.QRCode = materials.barcode
	--LEFT JOIN DBx.MAT.Material 
	--ON  MixAGPaste.AGPasteType  = DBx.MAT.Material.Material_Production
	WHERE APCSProDB.mc.machines.name = @MCNo
 
END