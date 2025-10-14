------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Author Name              : Sadanun.B
-- Written Date             : 2022/12/21
-- Procedure Name 	 		: [jig].[sp_get_production_id]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_get_production_id]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @name  NVARCHAR(MAX)  = NULL
		, @category_id INT		= NULL
	 
)
AS
BEGIN
	SET NOCOUNT ON;

		IF EXISTS (SELECT id, name , category_id  
		FROM APCSProDB.jig.productions
		WHERE productions.name LIKE  '%' + @Name + '%' AND category_id = @category_id  )
		BEGIN 

		SELECT  TOP 1 'TRUE' AS Is_Pass
					 ,'' AS Error_Message_ENG
					 ,'' AS Error_Message_THA
					 ,'' AS Handling
					 ,'' AS Warning
					 , productions.id
					 , productions.name 
					 , productions.category_id 
					 FROM APCSProDB.jig.productions
					 WHERE productions.name LIKE  '%' + @Name + '%'  AND category_id = @category_id
		END 
		ELSE
		BEGIN 

		SELECT  'FALSE' AS Is_Pass
				,'('+(@Name)+') Data not found !!' AS Error_Message_ENG
				,'('+(@Name)+N')ไม่พบข้อมูล !!' AS Error_Message_THA
				,'' AS Handling
				,N'กรุณาตรวจสอบข้อมูลที่ Web Jig' AS Warning

		END



END
