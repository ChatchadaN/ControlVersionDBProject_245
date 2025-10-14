------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Author Name              : Sadanun.B
-- Written Date             : 2023/06/27
-- Procedure Name 	 		: [material].[sp_get_productions]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_get_production]
 (
	@id  INT = NULL 
 )
AS
BEGIN
	SET NOCOUNT ON;

		SELECT    productions.id 
				, supplier_cd
				, productions.code	
				, productions.name productions_name	
				, spec
				, details 
				, categories.id  AS categories_id
				, categories.name  categories_name 
				, pack_std_qty
				, unit_code
				, code2.descriptions AS unit_code_name
				, arrival_std_qty
				, min_order_qty
				, lead_time 
				, lead_time_unit
				, code3.descriptions AS lead_time_unit_name
				, expiration_base
				, expiration_unit		
				, code1.descriptions AS expiration_unit_name
				, expiration_value
				, (CASE WHEN (is_disabled = 0 ) THEN '0'ELSE '1' END ) AS  is_disabled
				, (CASE WHEN (is_released = 0 ) THEN '0'ELSE '1' END ) AS  is_released
				, productions.created_at
				, productions.created_by
				, productions.updated_at	
				, productions.updated_by
		FROM APCSProDB.material.productions
		INNER JOIN APCSProDB.material.categories 
		ON  productions.category_id =  categories.id 
		LEFT JOIN APCSProDB.material.material_codes code1
		ON productions.expiration_unit = code1.code
		AND   code1.[group]		=  'time_unit'
		LEFT JOIN APCSProDB.material.material_codes  code2
		ON productions.unit_code = code2.code
		AND   code2.[group]		=  'package_unit'
		LEFT JOIN APCSProDB.material.material_codes   code3
		ON productions.lead_time_unit		= code3.code
		AND   code3.[group]		=  'time_unit'
		WHERE (productions.id  =  @id OR  @id IS NULL)


END
