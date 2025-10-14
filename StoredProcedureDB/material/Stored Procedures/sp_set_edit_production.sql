------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Author Name              : Sadanun.B
-- Written Date             : 2023/06/27
-- Procedure Name 	 		: [material].[sp_get_categories]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_set_edit_production]
(
		  @supplier_cd				NVARCHAR(100)  = NULL 
		, @code						NVARCHAR(100)   = NULL 
		, @id						INT	
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
		, @is_disabled				INT				= NULL 
		, @is_released				INT				= NULL 
)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY  

			UPDATE APCSProDB.[material].[productions]
			SET   [supplier_cd]			= @supplier_cd
				, [code]				= ISNULL(@code,'')
				, [name]				= @productions_name
				, [spec]				= @spec
				, [details]				= @details
				, [category_id]			= @category_id
				, [pack_std_qty]		= @pack_std_qty
				, [unit_code]			= @unit_code
				, [arrival_std_qty]		= @arrival_std_qty
				, [min_order_qty]		= @min_order_qty
				, [lead_time]			= @lead_time
				, [lead_time_unit]		= @lead_time_unit
				, [expiration_base]		= @expiration_base
				, [expiration_unit]		= @expiration_unit
				, [expiration_value]	= @expiration_value
				, [is_disabled]			= @is_disabled
				, [is_released]			= @is_released
				, [updated_at]			= GETDATE()
				, [updated_by]			= 1
			WHERE id  = @id


			SELECT   'TRUE' AS Is_Pass
						,N'('+(@productions_name)+') Successfully edited  !!' AS Error_Message_ENG
						,N'('+(@productions_name)+') Successfully edited  !!' AS Error_Message_THA
						,'' AS Handling
						,'' AS Warning
	
	END TRY  
	BEGIN CATCH  
			SELECT    'FALSE'					AS Is_Pass 
					, N'Failed to edited  !!'	AS Error_Message_ENG
					, N'Failed to edited  !!'	AS Error_Message_THA 
					, ''						AS Handling

	END CATCH  

END
