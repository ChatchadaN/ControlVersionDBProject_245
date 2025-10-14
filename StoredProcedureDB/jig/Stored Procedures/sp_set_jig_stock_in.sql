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

CREATE  PROCEDURE [jig].[sp_set_jig_stock_in]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @process_id			INT				= NULL	 
		, @Code					NVARCHAR(100)	= NULL 
		, @update_by			INT				= NULL
		, @location_id			INT				= NULL
)
AS
BEGIN
	SET NOCOUNT ON;

 
	DECLARE   @production_id		INT				= 0 
			, @status				NVARCHAR(20)	= 0 
			, @expiration_value		INT				= 0
			, @warn_value			INT				= 0
			, @liftime				INT				= 0
			, @jig_id				INT				= 0 
			, @jig_state			INT				= 0 
			, @user_no				NVARCHAR(10)	= 0

 

	IF NOT EXISTS ( SELECT 'xxx' FROM APCSProDB.trans.jigs 
					 LEFT JOIN APCSProDB.trans.jig_conditions 
					 ON  jigs.id =  jig_conditions.id  
					 WHERE ( barcode = @Code OR  smallcode = @Code OR qrcodebyuser	= @Code	 )
				    )
	BEGIN 
		
			SELECT	 'FALSE' AS Is_Pass
					, N' Data not found !!' AS Error_Message_ENG 
					, N'ยังไม่ถูกลงทะเบียน !! ' AS Error_Message_THA
					, '' AS Handling
					, N'กรุณาตรวจสอบข้อมูลที่ Web Jig' AS Warning
		
	END
	ELSE
	BEGIN
	  
	  			SELECT @jig_id = jigs.id	
				FROM APCSProDB.trans.jigs 
				WHERE ( barcode	 = @Code OR  smallcode = @Code OR  qrcodebyuser	= @Code	)

				SELECT	  @status			=  jigs.status
						, @jig_state		=  jigs.jig_state
						, @production_id	=  jigs.jig_production_id
						, @liftime			=  jig_conditions.value 
						, @expiration_value	=  production_counters.alarm_value
						, @warn_value		=  production_counters.warn_value
				FROM APCSProDB.trans.jigs 
				INNER JOIN APCSProDB.trans.jig_conditions 
				ON  jigs.id			=  jig_conditions.id  
				INNER JOIN APCSProDB.jig.productions 
				ON  productions.id	=  jigs.jig_production_id 
				INNER JOIN  APCSProDB.jig.production_counters 
				ON  productions.id	=  production_counters.production_id 
				WHERE jigs.id  = @jig_id
				
				IF @jig_state IN (13,2,12)  --13 (Scrap), 2 (Stock) , 12 (On Machine)
				BEGIN 
				
					SELECT	 'FALSE' AS Is_Pass
							, N'jig status is '+@status+'. !!' AS Error_Message_ENG 
							, N'jig สถานะเป็น '+@status+' ' AS Error_Message_THA
							, '' AS Handling
							, N'กรุณาตรวจสอบข้อมูลที่ Web Jig' AS Warning
						RETURN
				END
				ELSE
				
				IF @liftime > @expiration_value
				BEGIN 
				SELECT	 'FALSE' AS Is_Pass
							, N'Life Time Over'+@status+'. !!' AS Error_Message_ENG 
							, N'การใช้งานเกินอายุการใช้งาน' AS Error_Message_THA
							, '' AS Handling
							, N'กรุณาตรวจสอบข้อมูลที่ Web Jig' AS Warning
							RETURN

				END
				IF @liftime >@warn_value
				BEGIN 
				SELECT	 'FALSE' AS Is_Pass
							, N'Safety Point Over'+ @status+'. !!'	AS Error_Message_ENG 
							, N'การใช้งานใกล้หมดอายุ'					AS Error_Message_THA
							, ''									AS Handling
							, N'กรุณาตรวจสอบข้อมูลที่ Web Jig'			AS Warning
							RETURN
				END
				ELSE
				BEGIN 

							BEGIN  TRY
							BEGIN 

							SET @user_no = (SELECT emp_num FROM APCSProDB.man.users WHERE id = @update_by)

								UPDATE	  APCSProDB.trans.jigs 
								SET		  location_id		= @location_id
										, [status]			= 'Stock'
										, jigs.jig_state	= 2
										, updated_at		= GETDATE()
										, updated_by		= @update_by
								WHERE	id					= @jig_id


								INSERT INTO APCSProDB.trans.jig_records 
								(	 
									  [day_id]
									, [record_at]
									, [jig_id]
									, [jig_production_id]
									, [location_id]
									, [created_at]
									, [created_by]
									, [operated_by]
									, transaction_type
									, record_class
									, jig_state
								) 
								VALUES 
								(
									  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
									, GETDATE()
									, @jig_id
									, @production_id
									, @location_id
									, GETDATE()
									, @update_by
									, @user_no
									, 'Stock'
									, 2
									, 2
								)

								SELECT    'TRUE' AS Is_Pass
										, N' Successfully registered !!'	AS Error_Message_ENG
										, N' ถูกนำเข้า Stock เรียบร้อย !!'	    AS Error_Message_THA
										, '' AS Handling
										, '' AS Warning

							END	 
							END	TRY
							BEGIN CATCH

								SELECT    'FALSE' AS Is_Pass 
										, N'Failed to register !!' AS Error_Message_ENG
										, N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA 
										, '' AS Handling

							END CATCH	 
				END
		END		
END
 