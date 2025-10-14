------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Author Name              : Sadanun.B
-- Written Date             : 2023/06/27
-- Procedure Name 	 		: [material].[sp_get_productions]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_set_production]
 (
		  @supplier_cd				NVARCHAR(100)   = NULL 
		, @code						NVARCHAR(100)   = NULL 
		, @productions_name			NVARCHAR(100)   = NULL 
		, @spec						NVARCHAR(100)   = NULL 
		, @details					NVARCHAR(100)   = NULL 
		, @category_id				INT			   	= NULL 
		, @pack_std_qty				INT				= NULL 
		, @unit_code				INT				= NULL 
		, @arrival_std_qty			INT 			= NULL 
		, @min_order_qty			INT 			= NULL 
		, @lead_time				INT				= NULL 
		, @lead_time_unit			INT 			= NULL 
		, @expiration_base			INT 			= NULL 
		, @expiration_value			INT 			= NULL 
		, @expiration_unit			INT 			= NULL 
		, @is_disabled				INT				= 0 
		, @is_released				INT				= 0 
 )
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY  

		INSERT INTO [APCSProDB].[material].[productions]
        (
		   [id]
           ,[product_family_id]
           ,[supplier_cd]
           ,[code]
           ,[name]
           ,[spec]
           ,[details]
           ,[category_id]
           ,[pack_std_qty]
           ,[unit_code]
           ,[arrival_std_qty]
           ,[min_order_qty]
           ,[lead_time]
           ,[lead_time_unit]
           ,[label_issue_qty]
           ,[expiration_base]
           ,[expiration_unit]
           ,[expiration_value]
           ,[is_disabled]
           ,[is_released]
           ,[created_at]
           ,[created_by]
     )
     VALUES
     (
		   (SELECT ISNULL(id,0) + 1 FROM APCSProDB.material.numbers WHERE  name ='productions.id')
           ,1 
           ,@supplier_cd 
           ,@code 
           ,@productions_name
           ,@spec 
           ,@details 
           ,@category_id 
           ,@pack_std_qty 
           ,@unit_code 
           ,@arrival_std_qty 
           ,@min_order_qty 
           ,@lead_time 
           ,@lead_time_unit 
           ,0
           ,@expiration_base 
           ,@expiration_unit 
           ,@expiration_value 
           ,@is_disabled 
           ,@is_released 
           ,GETDATE()
           ,1
		   )

		UPDATE APCSProDB.material.numbers
			SET id = id + 1
		WHERE name = 'productions.id'

		SELECT    'TRUE' AS Is_Pass
				, N'('+(@productions_name)+') Successfully registered !!' AS Error_Message_ENG
				, N'('+(@productions_name)+') Successfully registered !!' AS Error_Message_THA
				, '' AS Handling
				, '' AS Warning


	END TRY  
	BEGIN CATCH  
				SELECT    'FALSE'					AS Is_Pass 
						, N'Failed to register !!'	AS Error_Message_ENG
						, N'Failed to register !!'	AS Error_Message_THA 
						, ''						AS Handling

	END CATCH  

END
