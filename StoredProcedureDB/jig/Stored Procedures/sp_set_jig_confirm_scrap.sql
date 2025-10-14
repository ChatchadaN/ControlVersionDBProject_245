------------------------------ Creater Rule ------------------------------
-- Project Name				: jig 
-- Written Date             : 2024/12/17
-- Procedure Name 	 		: [jig].[sp_set_storage]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.locations
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [jig].[sp_set_jig_confirm_scrap]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE

		  @updated_by				INT				= NULL
		, @jig_id					INT
		, @status					INT			
		, @jig_record_id			INT
)
AS
BEGIN
	SET NOCOUNT ON;
	 
 BEGIN 

	DECLARE @user_no NVARCHAR(6)

	BEGIN  TRY 
		BEGIN


			SET @user_no = (SELECT emp_num FROM APCSProDB.man.users WHERE id = @updated_by)
				 

			IF @status  = 1		--confirm 
			BEGIN 
			 
				UPDATE APCSProDB.trans.jig_records 
				SET   comment		= 'Confirmed'
					, updated_at	= GETDATE()
					, updated_by	= @updated_by
				WHERE id			= @jig_record_id


				
				SELECT    'TRUE'										AS Is_Pass
						, N'Successfully edited the information. !!'	AS Error_Message_ENG
						, N'แก้ไขข้อมูลเรียบร้อยแล้ว !!'						AS Error_Message_THA
						, ''											AS Handling
						, ''											AS Warning

				RETURN


			END 
			ELSE IF (@status =  2)		--Scraped
			BEGIN

			 
				UPDATE APCSProDB.trans.jigs 
				SET   [status]			= 'Scraped'
					, jigs.jig_state	= 14
					, updated_at		= GETDATE()
					, updated_by		= @updated_by
				WHERE id = @jig_id

				INSERT INTO APCSProDB.trans.jig_records 
				(		  [day_id]
						, [record_at]
						, [jig_id]
						, [jig_production_id]
						, [location_id]
						, [created_at]
						, [created_by]
						, [operated_by]
						, [transaction_type]
						, record_class
				) 
				values (
						  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
						, GETDATE()
						, @jig_id
						, (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @jig_id) 
						, NULL
						, GETDATE()
						, @updated_by
						, @user_no
						, 'Scraped'
						, 14
				)

				SELECT    'TRUE'										AS Is_Pass
						, N'Successfully edited the information. !!'	AS Error_Message_ENG
						, N'แก้ไขข้อมูลเรียบร้อยแล้ว !!'						AS Error_Message_THA
						, ''											AS Handling
						, ''											AS Warning

						RETURN
			
			END

			END


		END	TRY
	
		BEGIN CATCH

			SELECT    'FALSE'					AS Is_Pass 
					, N'Failed to register !!'	AS Error_Message_ENG
					, N'การบันทึกข้อมูลผิดพลาด !!'	AS Error_Message_THA 
					, ''						AS Handling
		END CATCH	 

   END

   END
