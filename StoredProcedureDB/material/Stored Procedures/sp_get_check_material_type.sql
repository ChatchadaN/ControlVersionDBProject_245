------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Procedure Name 	 		: trans.materials  
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_get_check_material_type]
 (
	  @barcode				AS VARCHAR(100)
	, @package				AS VARCHAR(250)
	, @mc_no				AS VARCHAR(250) =  NULL 
	, @opno					AS VARCHAR(6)
 )
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @material_name AS NVARCHAR(100) , @material_type_id INT 


	SELECT  @material_type_id =  productions.id  
	FROM APCSProDB.trans.materials  
	INNER JOIN APCSProDB.material.productions   
	ON materials.material_production_id = productions.id
	INNER JOIN APCSProDB.material.categories  
	ON categories.id = productions.category_id
	WHERE  materials.barcode = @barcode


	SET  @material_name = ( SELECT TOP 1  material_name 
	FROM [APCSProDB].[material].[material_commons] 
	WHERE material_production_id = @material_type_id )
	 


	IF EXISTS ( SELECT  1 FROM  APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT
		WHERE  [FORM_NAME_1] =  @package
		AND FRAME_NAME =  @material_name )
	 BEGIN 
				SELECT	  'TRUE'	AS Is_Pass
						, 'Pass'	AS Error_Message_ENG
						, N'ผ่าน'		AS Error_Message_THA
						, N''		AS Handling
						, m.id		AS Material_id
						, ( SELECT FRAME_NAME  = STUFF( (SELECT ',' + FRAME_NAME 
				 										FROM  APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT  T1
				 										WHERE (T1.[FORM_NAME_1] =  T2.[FORM_NAME_1] ) 
														AND T1.FRAME_NAME <>  ' '
				 										GROUP BY   FRAME_NAME  
				 										FOR XML PATH ('')),1,1,'') 
				 		FROM  APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT   T2
				 		WHERE ([FORM_NAME_1] = @package)
				 		GROUP BY    [FORM_NAME_1] ) AS Material_type_name
						, m.lot_no			AS mat_lot_no
						, convert(varchar,ISNULL(m.extended_limit_date,m.limit_date),121) as limit
						, m.quantity		AS quantity
						, p.pack_std_qty	AS pack_std_qty
			FROM APCSProDB.trans.materials m 
			INNER JOIN APCSProDB.material.productions p 
			ON m.material_production_id = p.id
			INNER JOIN APCSProDB.material.categories c 
			ON c.id = p.category_id
			WHERE  m.barcode = @barcode

	 END 
	 ELSE
	 BEGIN
		
			SELECT 'FALSE' as Is_Pass
			,'Material Type is not match. !!' AS Error_Message_ENG
			,N'Type Material ไม่ตรงกัน !!' AS Error_Message_THA
			,N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
			,( SELECT FRAME_NAME  = STUFF( (SELECT ',' + FRAME_NAME 
														FROM  APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT  T1
														WHERE (T1.[FORM_NAME_1] =  T2.[FORM_NAME_1] ) 
														AND T1.FRAME_NAME <>  ' '
														GROUP BY   FRAME_NAME  
														FOR XML PATH ('')),1,1,'') 
			FROM  APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT   T2
			WHERE ([FORM_NAME_1] = @package)
			GROUP BY    [FORM_NAME_1] ) as Material_type_name
			RETURN 

	 END
 
 						

		
 



	 
END
