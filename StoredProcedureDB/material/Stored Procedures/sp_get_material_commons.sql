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

CREATE  PROCEDURE [material].[sp_get_material_commons]
 (
		@id INT = NULL
 )
AS
BEGIN
	SET NOCOUNT ON;
 

			SELECT	 [material_commons].id
					,productions.name AS productions_name
				    ,[material_production_id]
				    ,[material_name]
			FROM [APCSProDB].[material].[material_commons]
			INNER JOIN APCSProDB.material.productions
			ON productions.id  = [material_commons].material_production_id
			WHERE ([material_commons].id = @id  OR @id IS NULL )
	 

END
