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

CREATE  PROCEDURE [material].[sp_set_materials]
 (
	  @material_production_id		INT				= NULL 
	, @barcode						NVARCHAR(100)	= NULL
	, @in_quantity					INT				= NULL
	, @quantity						INT				= NULL
	, @material_state				INT				= NULL
	, @process_state				INT				= NULL
	, @limit_date					DateTime		= NULL
	, @lot_no						NVARCHAR(100)	= NULL
 )
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY  

		INSERT INTO APCSProDB.trans.materials
		(
				  id
				, barcode
				, material_production_id
				, product_slip_id
				, step_no
				, in_quantity
				, quantity
				, fail_quantity
				, pack_count
				, is_production_usage
				, material_state
				, process_state
				, qc_state
				, limit_date
				, lot_no
				, created_at
				, created_by
				, limit_state
				, location_id
		)
		SELECT   (SELECT ISNULL(id,0) + 1 FROM APCSProDB.trans.numbers	WHERE [name] = 'materials.id')
				, @barcode							AS barcode 
				, @material_production_id			AS material_production_id 
				, 0									AS product_slip_id  
				, 0									AS step_no
				, ISNULL(@in_quantity,@quantity)	AS in_quantity
				, ISNULL(@quantity,@in_quantity)	AS quantity
				, 0									AS fail_quantity
				, 0									AS pack_count
				, 0									AS is_production_usage
				, @material_state					AS material_state	--1
				, @process_state					AS process_state	--0
				, 0									AS qc_state 
				, @limit_date						AS limit_date
				, @lot_no							AS lot_no
				, GETDATE()							AS created_at
				, 1									AS created_by
				, 0									AS limit_state
				, 9									AS location_id

				UPDATE APCSProDB.trans.numbers	
				SET id = id+1
				WHERE [name] = 'materials.id'


		INSERT INTO [APCSProDB].[trans].[material_arrival_records]
           ([id]
           ,[day_id]
           ,[recorded_at]
           ,[operated_by]
           ,[record_class]
           ,[material_id]
           ,[location_id]
           ,[po_no]
           ,[purchase_order_id]
           ,[invoice_no]
           ,[amount]
           ,[currency]
           ,[rate_date]
           ,[to_thb_rate]
           ,[amount_thb]
           ,[unit_amount_thb]
           ,[created_at]
           ,[created_by]
           ,[updated_at]
           ,[updated_by]
           )
     VALUES
           ((SELECT ISNULL(id,0) + 1 FROM APCSProDB.trans.numbers	WHERE name = 'material_arrival_records.id')
           ,(SELECT id FROM APCSProDB.trans.days WHERE date_value = CONVERT(date,(FORMAT(GETDATE(),'yyyy-MM-dd'))))
           ,GETDATE()
           ,1
           ,0
           ,(SELECT id FROM APCSProDB.trans.numbers	WHERE name = 'materials.id')
           ,9
           ,NULL
           ,NULL
           ,NULL
           ,ISNULL(@in_quantity,@quantity)
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,GETDATE()
           ,1
           ,NULL
           ,NULL
           )

		   		UPDATE APCSProDB.trans.numbers	
					SET id = id+1
				WHERE name = 'material_arrival_records.id'

		SELECT    'TRUE' AS Is_Pass
				, N'('+(@barcode)+') Successfully registered !!' AS Error_Message_ENG
				, N'('+(@barcode)+') Successfully registered !!' AS Error_Message_THA
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
