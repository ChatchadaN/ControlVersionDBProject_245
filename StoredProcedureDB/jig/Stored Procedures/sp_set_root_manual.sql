------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Author Name              : Sadanun.B
-- Written Date             : 2022/12/07
-- Procedure Name 	 		: [jig].[sp_set_storage]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.locations
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [jig].[sp_set_root_manual]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @process_id			INT				= 0	 
		, @production_id		INT				= 0 
		, @qrcodebyuser			NVARCHAR(50)	= NULL 
		, @category_name		NVARCHAR(50)	= NULL 
		, @created_by			INT				= 0
		, @category_id			INT				= 0
		, @value				INT				= 0
)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE	   @status		NVARCHAR(50)
			,  @jig_state	INT				 
			,  @user_no		NVARCHAR(6)

	   IF EXISTS (  SELECT TOP(1) jigs.id ,jigs.Status  
					FROM APCSProDB.trans.jigs 
					INNER JOIN APCSProDB.jig.productions 
					ON  jigs.jig_production_id		=  productions.id 
					INNER JOIN APCSProDB.jig.categories 
					ON  productions.category_id		= categories.id 
					WHERE qrcodebyuser				= @qrcodebyuser
					AND categories.lsi_process_id	= @process_id
					AND categories.id				= @category_id
					AND productions.id				= @production_id
					ORDER BY id DESC
					)
		BEGIN 
		
			SELECT    'FALSE' AS Is_Pass
					, N'('+(@qrcodebyuser)+') Duplicate information !!' AS Error_Message_ENG
					, N'('+(@qrcodebyuser)+N')  ถูกลงทะเบียนแล้ว ไม่สามารถลงทะเบียนซ้ำได้ !!' AS Error_Message_THA
					, '' AS Handling
					, N'กรุณาตรวจสอบข้อมูลที่ Web Jig' AS Warning
		
		END
		ELSE
		BEGIN  TRY
		BEGIN

					INSERT INTO APCSProDB.trans.jigs 
					(
							  qrcodebyuser
							, jig_production_id
							, status
							, jig_state
							, created_at
							, created_by
							, quantity
							, location_id
					) 
					values 
					(		  @qrcodebyuser
							, @production_id
							, 'Stock'
							, 2
							, GETDATE()
							, @created_by
							, @value
							, 1194
					)
					INSERT INTO APCSProDB.trans.jig_conditions 
					(
							  reseted_at
							, reseted_by
					) 
					VALUES 
					(
							  GETDATE()
							, @created_by
					)

			  
				SELECT   'TRUE' AS Is_Pass
						,N' Successfully registered !!' AS Error_Message_ENG
						,N' ลงทะเบียนเรียบร้อย !!' AS Error_Message_THA
						,'' AS Handling
						,'' AS Warning
		END
		END	TRY
		BEGIN CATCH

				SELECT    'FALSE' AS Is_Pass 
						, N'Failed to register !!' AS Error_Message_ENG
						, N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA 
						, '' AS Handling
		END CATCH	 

END
