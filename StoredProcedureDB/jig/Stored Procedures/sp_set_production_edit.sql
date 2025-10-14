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

CREATE PROCEDURE [jig].[sp_set_production_edit]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @production_id			INT				= NULL 
		, @subtype					NVARCHAR(50)	= NULL 
		, @updated_by				INT				= NULL
		, @stdlifetime				INT				= NULL
		, @spec						NVARCHAR(200)	= NULL
		, @period					INT				= NULL 
		, @warn_value				INT 			= NULL 
		, @safetypointkpieces		INT 			= NULL 
		, @safety					INT 			= NULL 
		, @unit_code				INT 			= NULL 
		, @pack_std_qty				INT 			= NULL 
		, @arrival_std_qty			INT  			= NULL 
		, @min_order_qty			INT 			= NULL 
		, @lead_time				INT 			= NULL 
		, @lead_time_unit			INT 			= NULL 
		, @label_issue_qty			INT 			= NULL 
		, @expiration_base			INT 			= NULL 
		, @expiration_unit			INT 			= NULL 
)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE	   @status		NVARCHAR(50)
			,  @jig_state	INT				 
   
 BEGIN 
			 
	 
			BEGIN  TRY
		 
			BEGIN

				  UPDATE APCSProDB.jig.productions 
				  SET updated_at		= GETDATE()
				   ,updated_by			= @updated_by
				   ,pack_std_qty		= @pack_std_qty	
				   ,unit_code			= @unit_code
				   ,arrival_std_qty		= @arrival_std_qty
				   ,min_order_qty		= @min_order_qty	
				   ,lead_time			= @lead_time		
				   ,lead_time_unit		= @lead_time_unit	
				   ,label_issue_qty		= @label_issue_qty	
				   ,expiration_base		= @expiration_base	
				   ,expiration_unit		= @expiration_unit	
				   ,[name]				= @subtype
				   ,[spec]				= @spec
				   , expiration_value	= @stdlifetime
				WHERE id = @production_id

				UPDATE  APCSProDB.jig.production_counters 
				SET   production_counters.period_value	 =  @period
					, production_counters.warn_value	 =  @warn_value  
					, production_counters.alarm_value	 =  @stdlifetime
				WHERE production_counters.production_id  =  @production_id



				SELECT    'TRUE'												AS Is_Pass
						, N'Edit ('+(@SubType)+') Successfully  !!'		AS Error_Message_ENG
						, N'แก้ไข ('+(@SubType)+N') เรียบร้อย !!'				AS Error_Message_THA
						, ''													AS Handling
						, ''													AS Warning

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