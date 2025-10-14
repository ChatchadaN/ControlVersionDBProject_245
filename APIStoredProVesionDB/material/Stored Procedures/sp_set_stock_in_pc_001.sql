---- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_stock_in_pc_001]
	-- Add the parameters for the stored procedure here
		  @material_outgoings_id	INT
		, @emp_id					INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	DECLARE @mat_record_id INT 



	BEGIN TRANSACTION
	BEGIN TRY  
			 
			 
			DECLARE @TargetIDs TABLE 
			(	RowNum			INT IDENTITY(1,1)
				, material_receiving_process_id	INT
				, receiving_qty		DECIMAL(18,6)
				, po_id				INT
				, poUnit			NVARCHAR(100)
				, production_id  INT 
			)
			INSERT INTO @TargetIDs (material_receiving_process_id , receiving_qty , po_id ,poUnit , production_id)
			SELECT	  material_receiving_process.id  
					, IIF(SUBSTRING(trim(unit_convert.ropros_unitname) ,1,2) IN ('KP' , 'KM')  ,receiving_qty *1000, receiving_qty) AS receiving_qty
					, podata.pono
					, trim(unit_convert.ropros_unitname)
					, productions.id  
			FROM APCSProDB.trans.material_receiving_process
			INNER JOIN APCSProDB.material.productions
			ON productions.id  =  material_receiving_process.product_id
			INNER JOIN APCSProDB.material.suppliers
			ON suppliers.supplier_cd = productions.supplier_cd
			INNER JOIN APCSProDB.material.categories
			ON categories.id  =  productions.category_id
			INNER JOIN APCSProDWH.oneworld.podata
			ON  podata.id = material_receiving_process.po_id
			INNER JOIN APCSProDWH.oneworld.unit_convert
			ON podata.unitcode = unit_convert.ropros_unit
			WHERE [status] =  'W' 
			 

			DECLARE @Counter	INT = 1;
			DECLARE @Max		INT = (SELECT COUNT(*) FROM @TargetIDs)
			DECLARE @CurrentID	INT;

			WHILE @Counter <= @Max
			BEGIN

				SELECT @CurrentID = material_receiving_process_id FROM @TargetIDs WHERE RowNum = @Counter;

  
						UPDATE APCSProDB.trans.materials
						SET	  materials.location_id = to_location_id  
							, updated_at =  GETDATE() 
							, updated_by =  @emp_id 
						FROM  APCSProDB.trans.material_outgoings
						INNER JOIN APCSProDB.trans.material_outgoing_items
						ON  material_outgoing_items.material_outgoings_id = material_outgoings.id 
						INNER JOIN APCSProDB.trans.materials
						ON  materials.id  = material_outgoing_items.material_id
						WHERE materials.id  = @CurrentID


						EXEC [StoredProcedureDB].[trans].[sp_get_number_id]
							  @TABLENAME		= 'material_records.id'	
							, @NEWID			= @mat_record_id OUTPUT
				   
						INSERT INTO [APCSProDB].[trans].[material_records]
							([id]
							, [day_id]
							, [recorded_at]
							, [operated_by]
							, [record_class]
							, [material_id]
							, [barcode]
							, [material_production_id]
							, [step_no]
							, [in_quantity]
							, [quantity]
							, [fail_quantity]
							, [pack_count]
							, [limit_base_date]
							, [contents_list_id]
							, [is_production_usage]
							, [material_state]
							, [process_state]
							, [qc_state]
							, [first_ins_state]
							, [final_ins_state]
							, [limit_state]
							, [limit_date]
							, [extended_limit_date]
							, [open_limit_date1]
							, [open_limit_date2]
							, [wait_limit_date]
							, [location_id]
							, [acc_location_id]
							, [lot_no]
							, [qc_comment_id]
							, [qc_memo_id]
							, [arrival_material_id]
							, [parent_material_id]
							, [dest_lot_id]
							, [created_at]
							, [created_by]
							, [to_location_id])

						SELECT @mat_record_id AS [id]
							, (SELECT id FROM APCSProDB.trans.days WHERE date_value = CAST(GETDATE()AS date)) AS [day_id]
							, GETDATE() AS [recorded_at]
							, @emp_id
							, 1 AS [recored_class]
							, materials.[id] AS [material_id]
							, [barcode] 
							, [material_production_id]
							, [step_no]
							, [in_quantity]
							, [quantity]
							, [fail_quantity]
							, [pack_count]
							, [limit_base_date] AS [limit_base_date]
							, NULL AS [contents_list_id]
							, [is_production_usage]
							, [material_state] AS [material_state]
							, [process_state] AS [process_state]
							, [qc_state]
							, [first_ins_state]
							, [final_ins_state]
							, [limit_state]
							, [limit_date]
							, [extended_limit_date]
							, [open_limit_date1]
							, [open_limit_date2]
							, [wait_limit_date]
							, [location_id] 
							, [acc_location_id]
							, [lot_no]
							, [qc_comment_id]
							, [qc_memo_id]
							, [arrival_material_id]
							, [parent_material_id]
							, [dest_lot_id]
							, materials.[created_at]
							, materials.[created_by]
							, material_outgoings.to_location_id AS [to_location_id]
						FROM  APCSProDB.trans.material_outgoings
						INNER JOIN APCSProDB.trans.material_outgoing_items
						ON  material_outgoing_items.material_outgoings_id = material_outgoings.id 
						INNER JOIN APCSProDB.trans.materials
						ON  materials.id  = material_outgoing_items.material_id
						WHERE materials.id  = @CurrentID
  
			SET @Counter = @Counter + 1;

		END 

				SELECT    'TRUE'						AS Is_Pass 
						, 'Data saved successfully.'	AS Error_Message_ENG
						, N'บันทึกข้อมูลสำเร็จ'				AS Error_Message_THA	
						, ''							AS Handling	
			COMMIT;
	 
	END TRY
	BEGIN CATCH
		ROLLBACK;

			SELECT   'FALSE'							AS Is_Pass 
					, ERROR_MESSAGE()					AS Error_Message_ENG
					, N'การบันทึกข้อมูลผิดพลาด !!'			AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ material'	AS Handling

	END CATCH


END
