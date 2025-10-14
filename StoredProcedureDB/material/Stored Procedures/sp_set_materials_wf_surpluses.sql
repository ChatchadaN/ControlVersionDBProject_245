

------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Written Date             : 2024/09/25
-- Procedure Name 	 		: [material].[sp_get_productions]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_set_materials_wf_surpluses]
 (
	  @quantity						INT				= NULL 
	, @limit_date					DateTime		= NULL
	, @lot_no						NVARCHAR(100)	= NULL
	, @wafer_no						INT				= NULL
	, @order_no						NVARCHAR(100)	= NULL
	, @chip_model_name				NVARCHAR(100)	= NULL
	, @op_no						NVARCHAR(100)	= NULL
 )
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY  

	DECLARE	  @material_barcode			VARCHAR(20)
			, @material_id				INT 
			, @material_arrival_id		INT
			, @op_id					INT 

		SET @op_id  = (SELECT id  FROM APCSProDB.man.users WHERE emp_num =  @op_no)
			 
		EXEC [StoredProcedureDB].[trans].[sp_get_wf_id_and_barcode]
				@material_id			= @material_id			OUTPUT,
				@material_barcode		= @material_barcode		OUTPUT,
				@material_arrival_id	= @material_arrival_id	OUTPUT



		IF NOT EXISTS (SELECT 'xx'	FROM APCSProDB.trans.materials
						INNER JOIN APCSProDB.trans.wf_details
						ON materials.id  = wf_details.material_id
						INNER JOIN  APCSProDB.trans.wf_datas
						ON materials.id  = wf_datas.material_id
						INNER JOIN APCSProDB.material.productions
						ON materials.material_production_id =  productions.id 
						WHERE   (materials.material_production_id = 1086 )  
						AND wf_datas.idx = @wafer_no
						AND materials.lot_no  =  @lot_no)
		BEGIN


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
					, updated_at
					, updated_by
			)
			VALUES
			(
					@material_id
					, @material_barcode					 
					, 1086								 
					, 0									 
					, 0									 
					, @quantity							 
					, @quantity							 
					, 0									 
					, 0									 
					, 0									 
					, 1									 
					, 0									 
					, 0									 
					, @limit_date						 
					, @lot_no							 
					, GETDATE()							 
					, 1									 
					, 0									 
					, 17								 
					, GETDATE()							 
					, @op_id							 
				)
			INSERT INTO [APCSProDB].[trans].[material_arrival_records]
			(		  [id]
					, [day_id]
					, [recorded_at]
					, [operated_by]
					, [record_class]
					, [material_id]
					, [location_id]
					, [po_no]
					, [purchase_order_id]
					, [invoice_no]
					, [amount]
					, [currency]
					, [rate_date]
					, [to_thb_rate]
					, [amount_thb]
					, [unit_amount_thb]
					, [created_at]
					, [created_by]
					, [updated_at]
					, [updated_by]
			)
			VALUES
			(		  @material_arrival_id
					, (SELECT id FROM APCSProDB.trans.[days] WHERE date_value = CONVERT(date,(FORMAT(GETDATE(),'yyyy-MM-dd'))))
					, GETDATE()
					, 1
					, 0
					, @material_id
					, 17
					, NULL
					, NULL
					, NULL
					, @quantity
					, NULL
					, NULL
					, NULL
					, NULL
					, NULL
					, GETDATE()
					, @op_id
					, NULL
					, NULL
			 ) 
			INSERT INTO [APCSProDB].trans.wf_details
			(
				   [material_id] 
				  ,[chip_model_name] 
				  ,[seq_no] 
				  ,[out_div] 
				  ,[rec_div] 
				  ,[created_at] 
				  ,[created_by] 
				  , order_no 
				  
			)
			VALUES
			(
				  @material_id
				, @chip_model_name
				, 'SURPLUSES'
				, 'QI300'
				, 'TI970'
				, GETDATE()
				, @op_id
				, @order_no
			)  
			INSERT INTO [APCSProDB].trans.wf_datas
			(
				  [material_id]
				, [idx]
				, [qty]
				, [is_enable]
				, [created_at] 
				, [created_by]
			)
			VALUES
			(
				  @material_id
				, @wafer_no
				, @quantity
				, 1			 
				, GETDATE()
				, @op_id
			)
			 
			SELECT    'TRUE'			AS Is_Pass
					, N'('+(@material_barcode)+') Successfully registered !!' AS Error_Message_ENG
					, N'('+(@material_barcode)+') Successfully registered !!' AS Error_Message_THA
					, ''				AS Handling
					, ''				AS Warning

	END
	ELSE
	BEGIN 
			SELECT    'FALSE'			AS Is_Pass
					, N'('+(@lot_no)+ N') Duplicate Data !!' AS Error_Message_ENG
					, N'('+(@lot_no)+ N') ไม่สามารถลงข้อมูลซ้ำได้ !!' AS Error_Message_THA
					, ''				AS Handling
					, ''				AS Warning
	END
	END TRY  
	BEGIN CATCH  
				SELECT    'FALSE'					AS Is_Pass 
						, N'Failed to register !!'	AS Error_Message_ENG
						, N'Failed to register !!'	AS Error_Message_THA 
						, ''						AS Handling

	END CATCH  

END
