
-- =============================================
-- Author:		<Author,Sadanan B.>
-- Create date: <Create Date, 2025/09/29>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_repack_material_001]
	-- Add the parameters for the stored procedure here
	  @material_repack_file_id		INT 
	, @emp_id						INT		= 1

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		DECLARE    @quantity				INT  
				 , @location_id				INT  
				 , @repackQty				INT    
				 , @material_id				INT 
				 , @pack_unit_qty			INT  
				 , @category_id				INT  
				 , @material_arrival_id		INT  
				 , @material_id_new			INT  

	BEGIN TRANSACTION
	BEGIN TRY
	 
				SELECT	  @repackQty		= repack_qty
						, @material_id		= material_id   
						, @pack_unit_qty	=  pack_unit_qty
						, @quantity			=  materials.quantity
						, @location_id		=  materials.location_id
						, @category_id		= categories.id  
				FROM APCSProDB.trans.material_repack_file
				INNER JOIN APCSProDB.trans.materials
				ON  materials.id = material_repack_file.material_id
				INNER JOIN APCSProDB.material.productions
				ON  productions.id  = materials.material_production_id 
				INNER JOIN APCSProDB.material.categories
				ON  categories.id  = productions.category_id
				WHERE material_repack_file.id =  @material_repack_file_id 

		IF (@repackQty >   0 AND @quantity > 0)
		BEGIN
				WHILE (@repackQty > 0)
				BEGIN 

  
						EXEC [StoredProcedureDB].[trans].[sp_get_number_id]
								  @TABLENAME		= 'materials.id'	
								, @NEWID			= @material_id_new OUTPUT

						 
						DECLARE  @material_barcode	VARCHAR(255)
								, @day_id			INT
								, @seq_code			INT
								, @seq_id			INT

						SET @day_id = (SELECT [id] FROM [APCSProDB].[trans].[days] WHERE [date_value] = CAST(GETDATE() AS DATE));
						SET @seq_id = (SELECT [id] FROM [APCSProDB].[trans].[sequences] WITH (ROWLOCK) WHERE [day_id] =  @day_id);

						IF (@seq_id IS NULL)
						BEGIN
								SET @seq_id = 1;

								INSERT INTO [APCSProDB].[trans].[sequences] 
								(
										  [day_id]
										, [id]
								) 
								VALUES 
								(
										  @day_id
										, @seq_id
								);
						END
						ELSE
						BEGIN
								SET @seq_id = @seq_id + 1; 
								UPDATE	[APCSProDB].[trans].[sequences] 
								SET		[id]		= @seq_id 
								WHERE	[day_id]	= @day_id;

						END
			 
						SET @material_barcode = FORMAT(@category_id, '00') + FORMAT(GETDATE(), 'yyMMdd') + FORMAT(@seq_id, '0000');
						SET @quantity = IIF((@repackQty <@pack_unit_qty), @repackQty, @pack_unit_qty) 
					 
						INSERT INTO  APCSProDB.trans.materials
						(
								id 
								, arrival_material_id
								, parent_material_id
								, material_production_id
								, barcode
								, lot_no
								, process_state
								, created_at
								, created_by
								, quantity
								, in_quantity
								, product_slip_id
								, step_no
								, fail_quantity
								, pack_count 
								, is_production_usage	
								, material_state	 
								, qc_state
								, label_issue_state	
								, limit_state
						)
						
						SELECT	  @material_id_new
								, arrival_material_id
								, materials.id
								, material_production_id
								, @material_barcode
								, lot_no
								, 0
								, GETDATE()
								, @emp_id
								, @quantity
								, @quantity
								, product_slip_id
								, step_no
								, fail_quantity
								, pack_count
								, is_production_usage	
								, material_state	 
								, qc_state
								, label_issue_state	
								, limit_state
						FROM APCSProDB.trans.materials
						INNER JOIN APCSProDB.material.productions
						ON  productions.id  = materials.material_production_id 
						INNER JOIN APCSProDB.material.categories
						ON  categories.id  = productions.category_id
						WHERE materials.id  = @material_id
		 
						 SET @repackQty  =  @repackQty- @quantity

						UPDATE  APCSProDB.trans.materials
						SET	  quantity			= quantity -  @quantity
							, material_state	= IIF((quantity -  @quantity = 0), 0 ,material_state )
							, updated_at		= GETDATE() 
							, updated_by		=  @emp_id
						WHERE materials.id		=  @material_id
					

						--SELECT   quantity			= quantity -  @quantity
						--	, material_state	= IIF((quantity -  @quantity = 0), 0 ,material_state )
						--	, updated_at		= GETDATE() 
						--	, updated_by		=  @emp_id
						--	FROM   APCSProDB.trans.materials
						--	WHERE materials.id		=  @material_id
					
						EXEC [StoredProcedureDB].[trans].[sp_get_number_id]
								  @TABLENAME		= 'material_arrival_records.id'	
								, @NEWID			= @material_arrival_id OUTPUT

						INSERT INTO  APCSProDB.trans.material_arrival_records
						(		  
								  id  
								, day_id 
								, [recorded_at]
								, [operated_by]
								, material_id
								, location_id
								, created_at
								, created_by
								, record_class
								, po_no	
								, purchase_order_id	
								, invoice_no	
								, amount	
								, currency	
								, rate_date	
								, to_thb_rate	
								, amount_thb	
								, unit_amount_thb
						) 
						SELECT 	  @material_arrival_id 
								, (SELECT id FROM APCSProDB.trans.days WHERE date_value = CAST(GETDATE()AS date))
								, GETDATE()
								, @emp_id
								, @material_id_new
								, @location_id 
								, GETDATE() 
								, @emp_id   
								, 1
								, po_no	
								, purchase_order_id	
								, invoice_no	
								, amount	
								, currency	
								, rate_date	
								, to_thb_rate	
								, amount_thb	
								, unit_amount_thb 
						FROM  APCSProDB.trans.material_arrival_records
						WHERE material_id = @material_id



						PRINT @repackQty
					END 
				END 
				 
				DELETE APCSPRODB.[TRANS].[MATERIAL_REPACK_FILE]
				WHERE id  =   @material_repack_file_id

				SELECT    'TRUE'							AS Is_Pass
							, N'Repack is success'			AS Error_Message_ENG
							, N'Repack is success'			AS Error_Message_THA
							, ''							AS Handling 
							
							
							COMMIT
				RETURN

		 
	END TRY
	BEGIN CATCH
		ROLLBACK;

		SELECT  'FALSE'					AS Is_Pass 
				, ERROR_MESSAGE()		AS Error_Message_ENG
				, N'การลงทะเบียนผิดพลาด !!'	AS Error_Message_THA 
				, ''					AS Handling	
				, ''					AS material_id
	END CATCH

END
