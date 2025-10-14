------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Author Name              : Sadanun.B
-- Written Date             : 2023/06/28
-- Procedure Name 	 		: [material].[sp_get_productions]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_get_filter]
 (
	@filter_no  INT = NULL 
 )
AS
BEGIN
	SET NOCOUNT ON;

			IF (@filter_no = 1)	
			BEGIN 
				SELECT code AS id 
						, descriptions  AS [name]
						, ''		dummy1
						, ''		dummy2
				FROM APCSProDB.material.material_codes
				WHERE [group] =  'time_unit'
			END 

			IF (@filter_no = 2)	
			BEGIN 
				SELECT code AS id 
						, descriptions  AS [name]
						, ''		dummy1
						, ''		dummy2
				FROM APCSProDB.material.material_codes
				WHERE [group] =  'package_unit'
			END 

			IF (@filter_no = 3)	
			BEGIN
				SELECT code AS id 
						, descriptions  AS [name]
						, ''		dummy1
						, ''		dummy2
				FROM APCSProDB.material.material_codes
				WHERE [group] =  'matl_state'
			END 

			IF (@filter_no = 4)	
			BEGIN 	
				SELECT code AS id 
						, descriptions  AS [name]
						, ''		dummy1
						, ''		dummy2
				FROM APCSProDB.material.material_codes
				WHERE [group] =  'process_state'
			END 
			IF (@filter_no = 5)	
			BEGIN 	
				SELECT id  , [name]						
						, ''		dummy1
						, ''		dummy2
				FROM APCSProDB.material.locations
			END 
			IF (@filter_no = 6)	
			BEGIN 	
				SELECT DISTINCT [ropros_unit]	AS id 
						, [ropros_unitname]		AS [name]
						, ''		dummy1
						, ''		dummy2
				FROM APCSProDWH.[oneworld].[unit_convert]  
			END 
			IF (@filter_no = 7)	
			BEGIN 	
				SELECT  [id]			AS id 		
				     , [PoNo]			AS [name]
				     , [Specification]	AS dummy1 
				     , [SupplierName]	AS dummy2  
				FROM APCSProDWH.[oneworld].[podata] 
				WHERE ([DeliverySectionCode] LIKE '21%') AND ([OpeDate] > DATEADD(YEAR , -1, GETDATE()))
				ORDER BY  [PoNo] DESC

			END 
END
