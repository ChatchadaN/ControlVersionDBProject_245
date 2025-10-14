---- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_material_info_001]
	-- Add the parameters for the stored procedure here
		  @barcode			NVARCHAR(20)	= NULL 
		, @material_id		INT				= 0 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here


		SELECT	  categories.[name]			AS categories_name  
				, productions.id		AS productions_id
				, productions.name		AS productions_name
				, productions.pack_std_qty
				, materials.id			AS materials_id 
				, materials.barcode 
				, in_quantity 
				, materials.quantity 
				, material_codes.descriptions as unit 
				, ISNULL(code3.descriptions,'')		AS process_statename 
				, ISNULL(code2.descriptions,'')		AS material_statename
				, ISNULL(FORMAT(materials.extended_limit_date,'yyyy-MM-dd'),FORMAT(materials.limit_date,'yyyy-MM-dd'))  AS limit_date
				, ISNULL(locations.name,'')			AS  [material_locations] 
				, materials.lot_no
				,ISNULL(FORMAT(materials.open_limit_date1,'yyyy-MM-dd'),'') AS open_limit_date
				,ISNULL(FORMAT(materials.wait_limit_date,'yyyy-MM-dd'),'')	AS wait_limit_date
				, [rack_controls].[id]						AS location_id
				, ISNULL(rack_controls.[name]+' '+	 rack_addresses.[address] , '')				AS location_name 
				, ISNULL(employees.emp_code, '')			AS updated_by
				, ISNULL(employees.display_name,'')			AS display_name
				, ISNULL(CONVERT(VARCHAR, materials.updated_at,120),'')		AS updated_at
				, ISNULL(FORMAT(material_arrival_records.recorded_at,'yyyy-MM-dd'),'')				AS receive_date
				, ISNULL(wf_details.chip_model_name,'')		AS 	chip_model_name 
		FROM APCSProDB.trans.materials 
		INNER JOIN APCSProDB.material.productions
		ON materials.material_production_id =  productions.id  
		INNER JOIN APCSProDB.material.categories
		ON productions.category_id = categories.id 
		LEFT JOIN APCSProDB.material.locations
		ON locations.id  = materials.location_id
		LEFT JOIN APCSProDB.material.material_codes   code3
		ON materials.process_state		= code3.code
		AND   code3.[group]		=  'process_state'
		LEFT JOIN APCSProDB.material.material_codes  code2
		ON materials.material_state = code2.code
		AND   code2.[group]		=  'matl_state'
		LEFT JOIN APCSProDB.material.material_codes   
		ON unit_code = material_codes.code 
		AND material_codes.[group] = 'package_unit'
		LEFT JOIN [10.29.1.230].DWH.man.employees 
		on materials.updated_by = employees.id
		LEFT JOIN APCSProDB.rcs.rack_addresses
		ON  rack_addresses.item =   materials.barcode
		LEFT JOIN APCSProDB.rcs.rack_controls 
		ON [rack_controls].[id] = [rack_addresses].[rack_control_id]
		LEFT JOIN APCSProDB.trans.material_arrival_records
		ON material_arrival_records.[id] = materials.arrival_material_id
		LEFT JOIN APCSProDB.trans.wf_details
		ON IIF(materials.parent_material_id IS NOT NULL,materials.parent_material_id,materials.id)  =  wf_details.material_id 
		WHERE   (barcode = @barcode  OR materials.id = @material_id)


		
--RESIN 042501281146
--WAFER 122506090281
--RCS 032412170200
--parent 122503250001
END
