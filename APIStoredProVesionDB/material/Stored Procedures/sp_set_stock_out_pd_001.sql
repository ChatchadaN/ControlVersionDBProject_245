---- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_stock_out_pd_001]
	-- Add the parameters for the stored procedure here
		  @from_location_id			INT
		, @to_location_id			INT 
		, @material_id				NVARCHAR(255) 
		, @emp_id					INT	

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	DECLARE @mat_record_id_in		INT 
	, @mat_record_id_out			INT 
	, @outgoings_id					INT  
	, @outgoing_items_id			INT 
	, @day_id						INT
	, @get_date						DATETIME  = GETDATE()

	BEGIN TRANSACTION
	BEGIN TRY 
	 
	  
				
		EXEC [StoredProcedureDB].[trans].[sp_get_number_id]
			  @TABLENAME		= 'material_outgoings.id'	
			, @NEWID			= @outgoings_id OUTPUT

		EXEC [StoredProcedureDB].[trans].[sp_get_day_id]
			  @DATE_VALUE		= @get_date
			, @ID				= @day_id OUTPUT


		INSERT INTO [APCSProDB].[trans].[material_outgoings]
		(		 
				 [id]
				,[day_id]
				,[from_location_id]
				,[to_location_id]
				,[status_code]
				,[picking_by]
				,[created_at]
				,[created_by]
		)
		VALUES
		(
				  @outgoings_id
				, @day_id
				, @from_location_id
				, @to_location_id
				, '1'
				, @emp_id
				, GETDATE()
				, @emp_id
		)
			 
 

		DECLARE @TargetIDs	TABLE 
		(	RowNum			INT IDENTITY(1,1)
			, material_id	INT
			, barcode		NVARCHAR(255)
		)

		INSERT INTO @TargetIDs (material_id, barcode )
		SELECT id , barcode  
		FROM  APCSProDB.trans.materials  
		WHERE  id  IN  (SELECT  [value] FROM STRING_SPLIT(@material_id,','))
		
		
		INSERT INTO @TargetIDs (material_id , barcode)
		SELECT id , barcode  FROM  APCSProDB.trans.materials  
		WHERE  parent_material_id  IN (SELECT material_id FROM @TargetIDs)
		AND quantity = 0

		IF EXISTS(SELECT 1 FROM APCSProDB.rcs.rack_addresses WHERE item IN (SELECT barcode FROM @TargetIDs) )
		BEGIN 
					DECLARE @Address_TB TABLE (
						address_id INT,
						item VARCHAR(50)
					)

					INSERT INTO @Address_TB
					SELECT id,item
					FROM APCSProDB.rcs.rack_addresses
					WHERE  item  IN (SELECT barcode FROM @TargetIDs)
					 
					UPDATE APCSProDB.rcs.rack_addresses
					SET [item]	= NULL,
						[status] =  0,
						[updated_at] = GETDATE(),
						[updated_by] = @emp_id
					WHERE id IN (SELECT address_id FROM @Address_TB) 
					 
					INSERT INTO [APCSProDB].[rcs].[rack_address_records]
					SELECT 
						GETDATE()
						,'2'
						,a.[id]
						,a.[rack_control_id]
						,tb.[item]  -- ดึง item จาก @Address_TB
						,a.[status]
						,a.[address]
						,a.[x]
						,a.[y]
						,a.[z]
						,a.[is_enable]
						,a.[created_at]
						,a.[created_by]
						,a.[updated_at]
						,a.[updated_by]
					FROM [APCSProDB].rcs.rack_addresses a
					JOIN @Address_TB tb ON a.id = tb.address_id
					 
		END

		DECLARE @Counter	INT = 1;
		DECLARE @Max		INT = (SELECT COUNT(*) FROM @TargetIDs);
		DECLARE @CurrentID	INT;
		 
		WHILE @Counter <= @Max
		BEGIN

			SELECT @CurrentID = material_id FROM @TargetIDs WHERE RowNum = @Counter;
			
			UPDATE APCSProDB.trans.materials
			SET	  materials.location_id = @to_location_id
				, updated_at =  GETDATE() 
				, updated_by =  @emp_id 
			WHERE  id  =  @CurrentID

			
			EXEC [StoredProcedureDB].[trans].[sp_get_number_id]
					  @TABLENAME		= 'material_records.id'	
					, @NEWID			= @mat_record_id_out OUTPUT			
			
			EXEC [StoredProcedureDB].[trans].[sp_get_day_id]
					  @DATE_VALUE		= @get_date
					, @ID				= @day_id OUTPUT
			
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

			SELECT @mat_record_id_out AS [id]
				, @day_id
				, GETDATE() AS [recorded_at]
				, @emp_id
				, 2 AS [recored_class]
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
				, @from_location_id 
				, [acc_location_id]
				, [lot_no]
				, [qc_comment_id]
				, [qc_memo_id]
				, [arrival_material_id]
				, [parent_material_id]
				, [dest_lot_id]
				, materials.[created_at]
				, materials.[created_by]
				, @to_location_id AS [to_location_id]
			FROM  APCSProDB.trans.materials  
			WHERE materials.id  = @CurrentID

  
			EXEC [StoredProcedureDB].[trans].[sp_get_number_id]
				  @TABLENAME		= 'material_outgoing_items.id'	
				, @NEWID			= @outgoing_items_id OUTPUT			
			
			
			INSERT INTO [APCSProDB].[trans].[material_outgoing_items]
			(
				  [id]
				, [material_outgoings_id]
				, [material_id]
				, [record_id]
			)
			VALUES
			(
				  @outgoing_items_id
				, @outgoings_id
				, @CurrentID
				, @mat_record_id_out
			)


			DELETE   APCSProDB.[TRANS].[MATERIAL_PICKUP_FILE]  
			WHERE material_id = @CurrentID



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
