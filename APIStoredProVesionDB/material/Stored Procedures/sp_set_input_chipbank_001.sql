-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_input_chipbank_001] 
	-- Add the parameters for the stored procedure here
	@OPNo				NVARCHAR(10)			
	, @App_Name			NVARCHAR(50)
	, @CHIPMODELNAME	NVARCHAR(50)
	, @INVOICENO		NVARCHAR(50)
	, @WFLOTNO			NVARCHAR(50)
	, @SEQNO			NVARCHAR(50)
	, @RFSEQNO			VARCHAR(50)		= NULL
	, @WFCOUNT			DECIMAL			
	, @CHIPCOUNT		DECIMAL			
	, @WFCOUNT_FAIL		DECIMAL			
	, @OUTDIV			NVARCHAR(20)	
	, @RECDIV			NVARCHAR(20)	
	, @ORDERNO			NVARCHAR(50)	
	, @SLIPNO			VARCHAR(50)		= NULL	
	, @SLIPNOEDA		VARCHAR(50)		= NULL	
	, @CASENO			VARCHAR(50)		= NULL	
	, @HOLDFLAG			TINYINT			
	, @PLASMA			VARCHAR(10)		= NULL	
	, @STOCKDATE		NVARCHAR(20)			
	, @WFDATA1			NVARCHAR(180)	= ''
	, @WFDATA2			NVARCHAR(180)	= ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	----------------------------------------------------------------------
    -- Insert statements for procedure here
	DECLARE @STOCKDATETIME		DATETIME;
	SET @STOCKDATETIME = CONVERT(datetime, @STOCKDATE, 12)
	
	DECLARE @emp_id INT

	SELECT @emp_id = id FROM [APCSProDB_lsi_110].man.users
	WHERE emp_num = @OPNo 

	DECLARE @WFData TABLE (IDx INT, Qty INT)
	INSERT INTO @WFData
	SELECT IDx, Qty FROM StoredProcedureDB.material.fnc_set_wf_data_table(@WFDATA1)
	INSERT INTO @WFData
	SELECT IDx, Qty FROM StoredProcedureDB.material.fnc_set_wf_data_table(@WFDATA2)
	
	BEGIN TRANSACTION
	BEGIN TRY
		DECLARE @barcode			VARCHAR(20)
		, @material_id				INT
		, @material_production_id	INT
		, @material_arrival_id		INT

		SET @material_production_id = (SELECT id FROM [APCSProDB_lsi_110].[material].[productions] WHERE [name] = 'WAFER')

		--Check Invoice_no Already Exists **RIST Only		
		IF @RFSEQNO IS NULL
		BEGIN
			IF EXISTS(
			SELECT lot_no, invoice_no 
			FROM [APCSProDB_lsi_110].trans.materials
			INNER JOIN [APCSProDB_lsi_110].trans.material_arrival_records ar ON materials.id = ar.material_id 
			INNER JOIN [APCSProDB_lsi_110].trans.wf_details ON materials.id = wf_details.material_id
			WHERE material_production_id = 1085
			AND lot_no <> @WFLOTNO
			AND invoice_no = @INVOICENO)
			BEGIN
				SELECT 'FALSE' AS Is_Pass 
					 , 'This invoice_no already exists with a different lot_no!!' AS Error_Message_ENG
					 , N'invoice_no นี้มีอยู่แล้วใน lot_no อื่น !!' AS Error_Message_THA
					 , '' AS Handling
				RETURN;
			END
		END
		
		--SET PLASMA
		--IF EXISTS(SELECT 1 FROM APCSProDWH.dbo.CHIPMASTER WHERE PLASMA = 1 AND CHIPMODELNAME = @CHIPMODELNAME)
		--BEGIN
		--	SET @PLASMA = 1
		--END 

		--Check WFLotNo and WFData Already Exists
		--Check if the number of rows in @WFData match with the rows in wf_datas
		IF NOT EXISTS(
			SELECT 1
			FROM (
				SELECT COUNT(wf.material_id) AS MatchCount	
				FROM [APCSProDB_lsi_110].trans.wf_datas wf
				INNER JOIN @WFData wfdata ON wf.idx = wfdata.IDx AND wf.qty = wfdata.Qty
				INNER JOIN [APCSProDB_lsi_110].trans.materials materials 
					ON wf.material_id = materials.id
				INNER JOIN [APCSProDB_lsi_110].trans.wf_details 
					ON wf_details.material_id = materials.id

				WHERE materials.material_production_id = @material_production_id
				  AND materials.lot_no = @WFLOTNO
				  AND wf_details.seq_no = @SEQNO
				GROUP BY wf.material_id
				HAVING COUNT(wf.material_id) = (SELECT COUNT(IDx) FROM @WFData)
			) AS Matches
		)
		BEGIN
			print 'wlot_new'

			EXEC [StoredProcedureDB].[trans].[sp_get_wf_id_and_barcode]
				@material_id = @material_id OUTPUT,
				@material_barcode = @barcode OUTPUT,
				@material_arrival_id = @material_arrival_id OUTPUT

			DECLARE @day_id INT
			SET @day_id = (SELECT [id] FROM [APCSProDB_lsi_110].[trans].[days] WHERE [date_value] = CONVERT(date, GETDATE()))

			--IF EXISTS(SELECT [id] FROM [APCSProDB].[trans].[numbers] WHERE [name] = 'materials.id' AND [id] = @material_id)
			--BEGIN
			--	SELECT @material_id = [id] + 1 
			--	FROM [APCSProDB].[trans].[numbers] 
			--	WHERE [name] = 'materials.id';

			--	UPDATE [APCSProDB].[trans].[numbers] 
			--	SET [id] = @material_id 
			--	WHERE [name] = 'materials.id';
			--END

			--Insert intp Table : Materials
			INSERT INTO [APCSProDB_lsi_110].trans.materials
			(
				[id]
				  ,[barcode]
				  ,[material_production_id]
				  ,[product_slip_id]
				  ,[step_no]
				  ,[in_quantity]
				  ,[quantity]
				  ,[fail_quantity]
				  ,[pack_count]
				  ,[limit_base_date]
				  ,[contents_record_id]
				  ,[is_production_usage]
				  ,[material_state]
				  ,[process_state]
				  ,[qc_state]
				  ,[first_ins_state]
				  ,[final_ins_state]
				  ,[label_issue_state]
				  ,[limit_state]
				  ,[limit_date]
				  ,[extended_limit_date]
				  ,[open_limit_date1]
				  ,[open_limit_date2]
				  ,[wait_limit_date]
				  ,[location_id]
				  ,[acc_location_id]
				  ,[lot_no]
				  ,[qc_comment_id]
				  ,[qc_memo_id]
				  ,[arrival_material_id]
				  ,[parent_material_id]
				  ,[dest_lot_id]
				  ,[created_at]
				  ,[created_by]
				  ,[updated_at]
				  ,[updated_by]
			)
			VALUES
			(
				@material_id
				, @barcode
				, @material_production_id
				, 0
				, 0
				, @WFCOUNT
				, @WFCOUNT
				, @WFCOUNT_FAIL
				, 0
				, NULL
				, NULL
				, 0
				, 1
				, 0
				, @HOLDFLAG
				, NULL
				, NULL
				, NULL
				, 0
				, DATEADD(YEAR, 3,GETDATE())
				, NULL
				, NULL
				, NULL
				, NULL
				, 16
				, NULL
				, @WFLOTNO
				, NULL
				, NULL
				, @material_arrival_id
				, NULL
				, NULL
				, @STOCKDATETIME
				, @emp_id
				, NULL
				, NULL

			)

			--SELECT * FROM [APCSProDB].trans.materials

			--Insert into Table : material_arrival_records
			INSERT INTO [APCSProDB_lsi_110].trans.material_arrival_records
			(
				[id]
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
			(
				@material_arrival_id
				,@day_id
				,GETDATE()
				,@emp_id
				,1
				,@material_id
				,16
				,NULL
				,NULL
				,@INVOICENO
				,1
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,GETDATE()
				,@emp_id
				,NULL
				,NULL
			)

			--SELECT * FROM [APCSProDB].trans.material_arrival_records

			--Insert into Table : wf_details
			INSERT INTO [APCSProDB_lsi_110].trans.wf_details
			(
				[material_id] 
				  ,[chip_model_name] 
				  ,[seq_no] 
				  ,[rf_seq_no] 
				  ,[out_div] 
				  ,[rec_div] 
				  ,[chip_in] 
				  ,[chip_remain] 
				  ,[order_no] 
				  ,[slip_no] 
				  ,[slip_no_eda]
				  ,[case_no] 
				  ,[fuk1_flag] 
				  ,[fuk2_flag] 
				  ,[plasma] 
				  ,[created_at] 
				  ,[created_by] 
				  ,[updated_at]
				  ,[updated_by] 
			)
			VALUES
			(
				@material_id
				, @CHIPMODELNAME
				, @SEQNO
				, @RFSEQNO
				, @OUTDIV
				, @RECDIV
				, @CHIPCOUNT
				, @CHIPCOUNT
				, @ORDERNO
				, @SLIPNO
				, @SLIPNOEDA
				, @CASENO
				, 0
				, 0
				, @PLASMA
				, GETDATE()
				, @emp_id
				, NULL
				, NULL

			) 

			--SELECT * FROM [APCSProDB].material.wf_details

			--Insert into Table : wf_datas
			INSERT INTO [APCSProDB_lsi_110].trans.wf_datas
			(
				[material_id]
				, [idx]
				, [qty]
				, [is_enable]
				, [created_at] 
				, [created_by]
				, [updated_at]
				, [updated_by]
			)
			SELECT 
				@material_id
				, IDx
				, Qty
				, 1 AS [is_enable]
				, GETDATE()
				, @emp_id
				, NULL
				, NULL 
			FROM 
				@WFData

			--SELECT * FROM [APCSProDB].material.wf_datas

		END
		ELSE
		BEGIN
			print 'wlot_old'
			-- If all rows match, return an error
			SELECT 'FALSE' AS Is_Pass
				   , 'This WFLOTNO and WFDATA already exists  !!' AS Error_Message_ENG
				   , N'ข้อมูล WFLOTNO และ WFDATA นี้มีอยู่แล้ว !!' AS Error_Message_THA
				   , '' AS Handling;
			RETURN;

			----UPDATE WFCOUNT && WFCOUNT_FAIL
			--DECLARE @in_quantity_old	INT
			--, @quantity_old				INT
			--, @fail_quantity_old		INT
			--, @in_quantity_new			INT
			--, @quantity_new				INT
			--, @fail_quantity_new		INT
			--, @material_id_old			INT

			--SELECT
			--  @material_id_old = id
			--, @in_quantity_old = in_quantity
			--, @quantity_old	= [quantity]
			--, @fail_quantity_old = [fail_quantity]
			--FROM [APCSProDB].trans.materials
			--WHERE lot_no = @WFLOTNO

			--SET @in_quantity_new = @in_quantity_old + @WFCOUNT
			--SET @quantity_new = @quantity_old + @WFCOUNT
			--SET @fail_quantity_new = @fail_quantity_old + @WFCOUNT_FAIL

			--UPDATE [APCSProDB].trans.materials
			--SET [in_quantity] = @in_quantity_new
			--, quantity = @quantity_new
			--, fail_quantity = @fail_quantity_new
			--WHERE lot_no = @WFLOTNO

			----SELECT * FROM [APCSProDB].trans.materials

			----SELECT * FROM [APCSProDB].trans.material_arrival_records

			----Insert into Table : wf_details
			--INSERT INTO [APCSProDB].material.wf_details
			--(
			--	[material_id] 
			--	  ,[chip_model_name] 
			--	  ,[seq_no] 
			--	  ,[rf_seq_no] 
			--	  ,[out_div] 
			--	  ,[rec_div] 
			--	  ,[chip_in] 
			--	  ,[chip_remain] 
			--	  ,[order_no] 
			--	  ,[slip_no] 
			--	  ,[slip_no_eda]
			--	  ,[case_no] 
			--	  ,[fuk1_flag] 
			--	  ,[fuk2_flag] 
			--	  ,[plasma] 
			--	  ,[created_at] 
			--	  ,[created_by] 
			--	  ,[updated_at]
			--	  ,[updated_by] 
			--)
			--VALUES
			--(
			--	@material_id_old
			--	, @CHIPMODELNAME
			--	, @SEQNO
			--	, @RFSEQNO
			--	, @OUTDIV
			--	, @RECDIV
			--	, @CHIPCOUNT
			--	, @CHIPCOUNT
			--	, @ORDERNO
			--	, @SLIPNO
			--	, @SLIPNOEDA
			--	, @CASENO
			--	, 0
			--	, 0
			--	, @PLASMA
			--	, GETDATE()
			--	, @emp_id
			--	, NULL
			--	, NULL

			--) 

			----SELECT * FROM [APCSProDB].material.wf_details

			----INSERT wf_datas	
			--INSERT INTO [APCSProDB].material.wf_datas
			--(
			--	[material_id]
			--	, [idx]
			--	, [qty]
			--	, [is_enable]
			--	, [created_at] 
			--	, [created_by]
			--	, [updated_at]
			--	, [updated_by]
			--)
			--SELECT 
			--	@material_id_old
			--	, IDx
			--	, Qty
			--	, 1 AS [is_enable]
			--	, GETDATE()
			--	, @emp_id
			--	, NULL
			--	, NULL 
			--FROM 
			--	@WFData

			--SELECT * FROM [APCSProDB].material.wf_datas
		END

		SELECT 'TRUE' AS Is_Pass ,'Register Successfully !!' AS Error_Message_ENG,N'การลงทะเบียนสำเร็จ !!' AS Error_Message_THA	,'' AS Handling	
		COMMIT;

	END TRY
	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass 
		,ERROR_MESSAGE() AS Error_Message_ENG
		,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA ,'' AS Handling	
	END CATCH
END
