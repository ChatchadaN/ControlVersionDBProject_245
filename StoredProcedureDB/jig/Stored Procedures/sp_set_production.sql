------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Procedure Name 	 		: [jig].[sp_set_storage]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.locations
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [jig].[sp_set_production]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @subtype					NVARCHAR(50)	= NULL 
		, @spec						NVARCHAR(100)	= NULL 
		, @created_by				INT				= 1
		, @stdlifetime				INT				= 0
		, @period					DECIMAL(9,2)  	= 0.0 
		, @warn_value				INT 			= 0 
		, @safetypointkpieces		INT 			= 0 
		, @safety					INT 			= 0 
		, @unit_code				INT 			= 0 
		, @pack_std_qty				INT 			= 0 
		, @arrival_std_qty			INT  			= 0 
		, @min_order_qty			INT 			= 0 
		, @lead_time				INT 			= 0 
		, @lead_time_unit			INT 			= 0 
		, @label_issue_qty			INT 			= 0 
		, @expiration_base			INT 			= 0 
		, @expiration_unit			INT 			= 0 
		, @category_id				INT				= 0
		, @disable					INT				= 0

)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE	   @status		NVARCHAR(50)
			,  @productions_id	INT				 
   
 BEGIN 
			 
			BEGIN  TRY
		 
			BEGIN

			INSERT INTO APCSProDB.jig.productions 
			(
					  [name]
					, spec
					, category_id
				    , created_at		
				    , created_by		
				    , pack_std_qty	
				    , unit_code		
				    , arrival_std_qty	
				    , min_order_qty	
				    , lead_time		
				    , lead_time_unit	
				    , label_issue_qty	
				    , expiration_base
				    , expiration_unit	
					, expiration_value
			)
			VALUES 
			(
					  @subtype
					, @spec
					, @category_id
					, GETDATE()
					, @created_by
					, @pack_std_qty	
					, @unit_code
					, @arrival_std_qty
					, @min_order_qty	
					, @lead_time		
					, @lead_time_unit	
					, @label_issue_qty	
					, @expiration_base	
					, @expiration_unit	
					, @stdlifetime
				)
 
	
	SET @productions_id = 	(SELECT MAX(id) FROM APCSProDB.jig.productions WHERE name = @subtype and category_id = @category_id )
	 

				INSERT INTO APCSProDB.jig.production_counters 
				(		production_id
					  , counter_name
					  , period_value	
					  , warn_value	
					  , created_at	
					  , created_by
					  , is_disabled
					  , alarm_value
					  , counter_no
				 )
				 VALUES 
				 (
						  @productions_id
						, ''
						, @period
						, @warn_value
						, GETDATE()
						, @created_by
						, @disable
						, @stdlifetime
						, 1
				)
				 



				SELECT   'TRUE' AS Is_Pass
						,N'('+(@SubType)+') Successfully registered !!' AS Error_Message_ENG
						,N'('+(@SubType)+N') ลงทะเบียนเรียบร้อย !!' AS Error_Message_THA
						,'' AS Handling
						,'' AS Warning

			END


			END	TRY
	
		BEGIN CATCH
			SELECT    'FALSE' AS Is_Pass 
					, ERROR_MESSAGE() AS Error_Message_ENG
					, N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA 
					, '' AS Handling
		END CATCH	 

   END

   END
