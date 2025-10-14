------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Author Name              : Sadanun.B
-- Written Date             : 2023/06/27
-- Procedure Name 	 		: [material].[sp_get_categories]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_get_categories]
 (
		 @id INT = NULL
 )
AS
BEGIN
	SET NOCOUNT ON;

		 SELECT     categories.id  AS id
				 , categories.name AS name
				 , categories.short_name 
		FROM  APCSProDB.material.categories 
		WHERE (id =  @id OR @id IS NULL)
		GROUP BY    categories.id 
		, categories.name
		, categories.short_name 

END
