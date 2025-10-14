
-- =============================================
-- Author:		<Author,Sadanan B.>
-- Create date: <Create Date, 2025/07/31>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_process_receiving_001]
	-- Add the parameters for the stored procedure here

		  @material_receiving_process_id	INT 
		, @po_number						VARCHAR(20) 
		, @category_id						INT  
		, @production_id					INT 
		, @invoice_number					VARCHAR(50)
		, @lot_number						VARCHAR(50) 
		, @package_qty						DECIMAL(18,4)
		, @order_qty						DECIMAL(18,4) 
		, @receiving_qty					DECIMAL(18,4)
		, @receive_unit						VARCHAR(10) 
		, @expiry_date						DATETIME
		, @emp_id							INT			= NULL
  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION
	BEGIN TRY

		DECLARE @mat_id_list TABLE (mat_id INT);

		SET @receiving_qty = CASE WHEN UPPER(LEFT(@receive_unit, 2)) = 'KP' OR UPPER(@receive_unit) = 'KM' 
							 	  THEN @receiving_qty * 1000 
							 ELSE @receiving_qty END

		IF @receiving_qty <= 0
		BEGIN
			ROLLBACK;
					SELECT    'FALSE'											AS Is_Pass 
							, 'Receiving quantity must be greater than 0.'		AS Error_Message_ENG
							, N'จำนวนรับเข้าต้องมากกว่า 0'							AS Error_Message_THA 
							, ''												AS Handling    
							, ''												AS material_id
			RETURN
		END

		--- Function : Insert Data ---
		WHILE @receiving_qty > 0
		BEGIN

			DECLARE  @in_quantity				DECIMAL(18,4)
					, @location_id				INT	
					, @po_id					INT
					, @currency					VARCHAR(50)
					, @po_date					DATETIME
					, @OrgOrderUnitPrice		DECIMAL(18,4)
					, @is_update_package_size	BIT

			SET @in_quantity = CASE WHEN (@receiving_qty >= @package_qty) 
									THEN @package_qty
									ELSE @receiving_qty 
									END

			SELECT    @location_id				= location_id
					, @po_id					= po_id
					, @currency					= currency 
					, @po_date					= podate
					, @OrgOrderUnitPrice		= orgorderunitprice
					, @is_update_package_size	= is_update_package_size
			FROM APCSProDB.trans.material_receiving_process
			INNER JOIN APCSProDWH.oneworld.podata
			ON  podata.id = material_receiving_process.po_id
			WHERE material_receiving_process.id = @material_receiving_process_id

			--- GET id ---
			DECLARE   @mat_id				INT
					, @mat_record_id		INT
					, @material_arrival_id	INT


			EXEC [StoredProcedureDB].[trans].[sp_get_number_id]
				  @TABLENAME		= 'materials.id'	
				, @NEWID			= @mat_id OUTPUT

			EXEC [StoredProcedureDB].[trans].[sp_get_number_id]
				  @TABLENAME		= 'material_records.id'	
				, @NEWID			= @mat_record_id OUTPUT
	
			EXEC [StoredProcedureDB].[trans].[sp_get_number_id]
				  @TABLENAME		= 'material_arrival_records.id'	
				, @NEWID			= @material_arrival_id OUTPUT

			--- GET Barcode Materials ---
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

			-------------------------------------------------------------------------------------------------
			--- INSERT [materials] ---
			 

					INSERT INTO [APCSProDB].[trans].[materials]
					(
						  [id]
						, [barcode]
						, [material_production_id]
						, [product_slip_id]
						, [step_no]
						, [in_quantity]
						, [quantity]
						, [fail_quantity]
						, [pack_count]
						, [is_production_usage]
						, [material_state]
						, [process_state]
						, [qc_state]
						, [label_issue_state]
						, [limit_state]
						, [limit_date]
						, [location_id]
						, [lot_no]
						, [arrival_material_id]
						, [created_at]
						, [created_by]
					)
					VALUES 
					(
						  @mat_id
						, @material_barcode
						, @production_id
						, 0
						, 100 
						, @in_quantity
						, @in_quantity
						, 0
						, 0 
						, 0
						, 1
						, 0
						, 0
						, 2 
						, 0
						, @expiry_date
						, @location_id
						, @lot_number
						, @material_arrival_id
						, GETDATE()
						, @emp_id
					)

			----- เก็บ mat_id

			INSERT INTO @mat_id_list VALUES (@mat_id); 

			-------------------------------------------------------------------------------------------------
			--- INSERT [material_records] ---
			 

			INSERT INTO [APCSProDB].[trans].[material_records]
			SELECT  @mat_record_id
					, (SELECT id FROM APCSProDB.trans.days WHERE date_value = CAST(GETDATE()AS date)) AS [day_id]
					, GETDATE() AS [recorded_at]
					, @emp_id AS [operated_by]
					, 0 AS [record_class] --REGISTER
					, [materials].id AS [material_id]
					, [barcode]
					, [material_production_id]
					, [step_no]
					, [in_quantity]
					, [quantity]
					, [fail_quantity]
					, [pack_count]
					, [limit_base_date]
					, NULL AS [contents_list_id]
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
					, [updated_at]
					, [updated_by]
					, NULL AS [to_location_id]
			FROM [APCSProDB].[trans].[materials]
			WHERE id = @mat_id
			
			-------------------------------------------------------------------------------------------------
			--- INSERT [material_arrival_records] ---

			DECLARE @quantity DECIMAL(18,4)

			SELECT	@quantity = quantity
			FROM	[APCSProDB].[trans].[materials]
			WHERE id = @mat_id

			DECLARE	  @opedate			DATETIME
					, @ratefromexchange DECIMAL(18,4)

			SELECT TOP 1 @opedate			= opedate
						,@ratefromexchange	= ratefromexchange
			FROM APCSProDWH.oneworld.rate
			WHERE currencytoexchange = @currency
			AND CAST(effectivefrom AS DATE) <  CAST(@po_date AS DATE)
			ORDER BY effectivefrom DESC
 
					INSERT INTO [APCSProDB].[trans].[material_arrival_records]
					(
							  [id]
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
					)
					VALUES
					( 
							  @material_arrival_id
							, (SELECT id FROM APCSProDB.trans.days WHERE date_value = CAST(GETDATE()AS date))
							, GETDATE()
							, @emp_id
							, 1 -- STOCK_IN
							, @mat_id 
							, @location_id
							, @po_number 
							, @po_id 
							, @invoice_number 
							, @quantity 
							, @currency
							, @opedate 
							, @ratefromexchange
							, CASE  WHEN @ratefromexchange IS NOT NULL 
								THEN @quantity * (@ratefromexchange * @OrgOrderUnitPrice)
								ELSE @quantity * @OrgOrderUnitPrice
								END 
							,  CASE  WHEN @ratefromexchange IS NOT NULL 
								THEN @OrgOrderUnitPrice * @ratefromexchange
								ELSE @OrgOrderUnitPrice
								END 
							, GETDATE() 
							, @emp_id 
					)
 
			SET @receiving_qty = @receiving_qty - @package_qty

		END

		------------------------------------------------------------------------------------------------------
		--- UPDATE arrival_std_qty ของ productions ถ้า @is_update_package_size มีการเปลี่ยนปลง
 
		IF @is_update_package_size IS NOT NULL
		BEGIN
					 
					UPDATE APCSProDB.material.productions
					SET arrival_std_qty = CAST(@package_qty AS INT)
						, updated_at	= GETDATE()
					WHERE id = @production_id
		END

		------------------------------------------------------------------------------------------------------
		-- UPDATE Status material_receiving_process

		UPDATE APCSProDB.trans.material_receiving_process
		SET [status] = 'C'
		WHERE id = @material_receiving_process_id

		------------------------------------------------------------------------------------------------------
		COMMIT;

			SELECT    'TRUE' AS Is_Pass
					, 'Register Successfully !!' AS Error_Message_ENG
					, N'การลงทะเบียนสำเร็จ !!' AS Error_Message_THA
					, '' AS Handling
					, STUFF((
						SELECT ',' + CAST(mat_id AS VARCHAR)
						FROM @mat_id_list
						FOR XML PATH(''), TYPE
					  ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS material_id


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
