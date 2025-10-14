
------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Procedure Name 	 		: [material].[sp_get_categories]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_set_edit_material]
(
		  @barcode						NVARCHAR(100)	= NULL 
		, @id							INT			 
		, @production_id				INT				= NULL 
		, @in_quantity					INT				= NULL 
		, @quantity						INT				= NULL 
		, @material_state				INT				= NULL 
		, @process_state				INT				= NULL 
		, @limit_date					DateTime		= NULL 
		, @extended_limit_date			DateTime		= NULL 
		, @location_id					INT				= NULL 
		, @lot_no						NVARCHAR(100)	= NULL 
		, @wafer_no						INT	= NULL 
		, @chip_model_name				NVARCHAR(100)	= '' 
		, @order_no						NVARCHAR(100)	= NULL
		, @op_no						NVARCHAR(10)    = 1
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @op_id  INT 

	SET @op_id  = (SELECT id  FROM APCSProDB.man.users WHERE emp_num =  @op_no)
	BEGIN TRY  

			UPDATE [APCSProDB].[trans].[materials]
			SET   [barcode]					= @barcode 
				, [material_production_id]	= @production_id 
				, [in_quantity]				= ISNULL(@in_quantity , [materials].[in_quantity])
				, [quantity]				= @quantity
				, [material_state]			= @material_state 
				, [process_state]			= @process_state
				, [limit_date]				= @limit_date
				, [extended_limit_date]		= @extended_limit_date 
				, [location_id]				= @location_id 
				, [lot_no]					= @lot_no 
				, [updated_at]				= GETDATE()
				, [updated_by]				= @op_id
			FROM   [APCSProDB].[trans].[materials]
			WHERE [id] = @id


			IF EXISTS (SELECT * FROM  [APCSProDB].trans.wf_datas WHERE  material_id =  @id) 
			BEGIN 

				UPDATE [APCSProDB].trans.wf_datas
				SET idx				=  @wafer_no
					, qty			=  @quantity
					, [updated_at]	= GETDATE()
					, [updated_by]	= @op_id
				WHERE  material_id  =  @id


				UPDATE [APCSProDB].trans.wf_details
				SET   chip_model_name 	=  @chip_model_name
					, order_no			=  @order_no
					, [updated_at]		= GETDATE()
					, [updated_by]		= @op_id
				WHERE  material_id		=  @id

			END 
			 
			SELECT    'TRUE' AS Is_Pass
					, N'('+(@barcode)+') Successfully edit !!' AS Error_Message_ENG
					, N'('+(@barcode)+') Successfully edit !!' AS Error_Message_THA
					, '' AS Handling
					, '' AS Warning
	
	END TRY  
	BEGIN CATCH  
			SELECT    'FALSE'					AS Is_Pass 
					, ERROR_MESSAGE()	AS Error_Message_ENG
					, ERROR_MESSAGE()	AS Error_Message_THA 
					, ''						AS Handling

	END CATCH  

END
