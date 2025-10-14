------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Written Date             : 2022/12/07
-- Procedure Name 	 		: [jig].[sp_set_storage]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.locations
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_set_jig_stock_out]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @process_id			INT				= 0	 
		, @Code					NVARCHAR(100)	= 0 
		, @update_by			INT				= 0
		, @comment				INT				= 0
)
AS
BEGIN
	SET NOCOUNT ON;
 
	DECLARE   @production_id		INT				= 0 
			, @status				NVARCHAR(20)	= 0 
			, @short_name			NVARCHAR(30)	= 0 
			, @expiration_value		INT				= 0
			, @warn_value			INT				= 0
			, @liftime				INT				= 0
			, @jig_id				INT				= 0 
			, @jig_state			INT				= 0 
			, @user_no				NVARCHAR(10)	= 0			, @root_jig_id			INT				= 0
			, @location_id			INT				= 0
			, @quantity			INT				= 0
 
--PRINT ' START'+ FORMAT (getdate(), 'dd/MM/yyyy, hh:mm:ss ')

		 

	IF NOT EXISTS ( SELECT 'xxx'
					FROM APCSProDB.trans.jigs 
					WHERE ( barcode		= @Code
					OR  smallcode		LIKE @Code
					OR  qrcodebyuser	= @Code	 ))
	BEGIN 
	
			SELECT	 'FALSE' AS Is_Pass
					, N' Data not found !!' AS Error_Message_ENG 
					, N'ยังไม่ถูกลงทะเบียน !! ' AS Error_Message_THA
					, '' AS Handling
					, N'กรุณาตรวจสอบข้อมูลที่ Web Jig' AS Warning
	END 
	ELSE
	BEGIN
	
--PRINT ' IF NOT EXISTS '+ FORMAT (getdate(), 'dd/MM/yyyy, hh:mm:ss ')

				SET @jig_id =  (SELECT TOP 1 jigs.id	
								FROM APCSProDB.trans.jigs 
								WHERE ( barcode	 = @Code OR  smallcode  LIKE @Code	OR  qrcodebyuser = @Code ))

				SELECT		  @status			=  jigs.status
							, @jig_state		=  jigs.jig_state
							, @production_id	=  jigs.jig_production_id
							, @liftime			=  jig_conditions.value 
							, @expiration_value	=  production_counters.alarm_value
							, @warn_value		=  production_counters.warn_value
							, @short_name		=  categories.short_name
							, @root_jig_id		=  jigs.root_jig_id
							, @location_id		=  jigs.location_id
							, @quantity			=  jigs.quantity
				FROM APCSProDB.trans.jigs 
				LEFT JOIN APCSProDB.trans.jig_conditions 
				ON jigs.id = jig_conditions.id  
				INNER JOIN APCSProDB.jig.productions 
				ON  productions.id	=  jigs.jig_production_id 
				INNER JOIN  APCSProDB.jig.production_counters 
				ON  productions.id	=  production_counters.production_id 
				INNER JOIN  APCSProDB.jig.categories
				ON categories.id	=  productions.category_id
				WHERE  jigs.id		= @jig_id
	PRINT @jig_id
	
	PRINT @jig_state 

				IF @jig_state = 13   --13 (Scrap), 2 (Stock) , 12 (On Machine)
				BEGIN 
					SELECT	 'FALSE' AS Is_Pass
							, N'jig status is '+@status+'. !!' AS Error_Message_ENG 
							, N'สถานะเป็น '+@status+' ' AS Error_Message_THA
							, '' AS Handling
							, N'กรุณาตรวจสอบข้อมูลที่ Web Jig' AS Warning

							RETURN

				END
				ELSE IF @jig_state <>  2   --13 (Scrap), 2 (Stock) , 12 (On Machine)
				BEGIN 
					SELECT	 'FALSE' AS Is_Pass
							, N'This jig is not in stock !!' AS Error_Message_ENG 
							, N'jig นี้ไม่ได้อยู่ใน Stock !!' AS Error_Message_THA
							, '' AS Handling
							, N'กรุณาตรวจสอบข้อมูลที่ Web Jig' AS Warning
							RETURN
				END
				ELSE IF @liftime > @expiration_value
				BEGIN 
				SELECT	 'FALSE' AS Is_Pass
							, N'Life Time Over'+@status+'. !!' AS Error_Message_ENG 
							, N'การใช้งานเกินอายุการใช้งาน' AS Error_Message_THA
							, '' AS Handling
							, N'กรุณาตรวจสอบข้อมูลที่ Web Jig' AS Warning
					RETURN
				END
				ELSE IF @liftime > @warn_value
				BEGIN 
				SELECT	 'FALSE' AS Is_Pass
							, N'Safety Point Over '+@status+'. !!' AS Error_Message_ENG 
							, N'การใช้งานใกล้หมดอายุ' AS Error_Message_THA
							, '' AS Handling
							, N'กรุณาตรวจสอบข้อมูลที่ Web Jig' AS Warning
							RETURN
				END
				ELSE
				BEGIN 
						SET @user_no = (SELECT emp_num FROM APCSProDB.man.users WHERE id = @update_by)
							
							IF (@short_name = 'Kanagata')
							BEGIN 

								BEGIN  TRY
								BEGIN 

							 
								UPDATE	 APCSProDB.trans.jigs 
								SET		  location_id		= NULL
										, status			= 'To Machine'
										, jigs.jig_state	= 11
										, updated_at		= GETDATE()
										, updated_by		= @update_by
								WHERE	id = @jig_id or root_jig_id = @root_jig_id


									 INSERT INTO  APCSProDB.trans.jig_records 
									 (
											  [day_id]
											, [record_at]
											, [jig_id]
											, [jig_production_id]
											, [location_id]
											, [created_at]
											, [created_by]
											, [operated_by]
											, root_jig_id
											, transaction_type
											, [record_class]
											, jig_state
									 )
									 values 
									 (
											  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
											, GETDATE()
											, @jig_id
											, @production_id
											, NULL
											, GETDATE()
											, @update_by
											, @user_no
											, @root_jig_id
											, 'To Machine'
											, 11
											, 11
									 )

									SELECT    'TRUE' AS Is_Pass
											, N' Has been out of stock. !!'	AS Error_Message_ENG
											, N' ถูกเบิกออกจาก Stock เรียบร้อย !!'	    AS Error_Message_THA
											, '' AS Handling
											, '' AS Warning

								END	 
								END	TRY
								BEGIN CATCH

									SELECT    'FALSE' AS Is_Pass 
											, N'Failed to register !!' AS Error_Message_ENG
											, N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA 
											, '' AS Handling
											RETURN
								END CATCH	

							END 
							ELSE IF (@location_id = 1194) --Sparepart
							BEGIN 
								
								BEGIN  TRY
								BEGIN 
							 
									 UPDATE	 APCSProDB.trans.jigs 
									 SET	  location_id		= NULL
									 		, status			= 'To Stock'
									 		, jigs.jig_state	= 3
									 		, updated_at		= GETDATE()
									 		, updated_by		= @update_by
									 WHERE	id = @jig_id  


									 INSERT INTO  APCSProDB.trans.jig_records 
									 (
											  [day_id]
											, [record_at]
											, [jig_id]
											, [jig_production_id]
											, [location_id]
											, [created_at]
											, [created_by]
											, [operated_by]
											, root_jig_id
											, transaction_type
											, [record_class]
											, jig_state
											, comment
									 )
									 values 
									 (
											  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
											, GETDATE()
											, @jig_id
											, @production_id
											, NULL
											, GETDATE()
											, @update_by
											, @user_no
											, @root_jig_id
											, 'To Stock'
											, 3
											, 3
											, @comment
									 )

									SELECT    'TRUE' AS Is_Pass
											, N' Has been out of stock. !!'	AS Error_Message_ENG
											, N' ถูกเบิกออกจาก Stock เรียบร้อย !!'	    AS Error_Message_THA
											, '' AS Handling
											, '' AS Warning

								END	 
								END	TRY
								BEGIN CATCH

									SELECT    'FALSE' AS Is_Pass 
											, N'Failed to register !!' AS Error_Message_ENG
											, N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA 
											, '' AS Handling
											RETURN
								END CATCH	

							END 
							ELSE
							BEGIN

								BEGIN  TRY
								BEGIN 

								UPDATE	 APCSProDB.trans.jigs 
								SET		  location_id		= NULL
										, status			= 'To Machine'
										, jigs.jig_state	= 11
										, updated_at		= GETDATE()
										, updated_by		= @update_by
								WHERE	id = @jig_id

									 INSERT INTO  APCSProDB.trans.jig_records 
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
											, [record_class]
											, jig_state
									 )
									 values 
									 (
											  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
											, GETDATE()
											, @jig_id
											, @production_id
											, NULL
											, GETDATE()
											, @update_by
											, @user_no
											, 'To Machine'
											, 11
											, 11
									 )

								

									SELECT    'TRUE' AS Is_Pass
											, N' Has been out of stock. !!'	AS Error_Message_ENG
											, N' ถูกเบิกออกจาก Stock เรียบร้อย !!'	    AS Error_Message_THA
											, '' AS Handling
											, '' AS Warning

							END	 
							END	TRY
								BEGIN CATCH

									SELECT    'FALSE' AS Is_Pass 
											, N'Failed to register !!' AS Error_Message_ENG
											, N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA 
											, '' AS Handling
											RETURN
							END CATCH	 
							END
				END
	END 
END
