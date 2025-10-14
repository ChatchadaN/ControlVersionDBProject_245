-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_lot_inventory_v1]
	  @lot_no			VARCHAR(20)
	, @stock_class		INT
	, @emp_no			VARCHAR(6)
	, @qty				INT
	, @rack_no			VARCHAR(50) = NULL
	, @class_no			VARCHAR(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET @lot_no = (SELECT REPLACE(@lot_no, ' ', ''));

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no] )
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [atom].[sp_set_lot_inventory] @lot_no = ' + ISNULL('''' + CAST(@lot_no AS varchar) + ''',','NULL,')
			+ '@stock_class = ' + ISNULL(CAST(@stock_class AS varchar) + ',','NULL,') 
			+ '@emp_no = ' + ISNULL('''' + CAST(@emp_no AS varchar) + ''',','NULL,') 
			+ '@qty = ' + ISNULL(CAST(@qty AS varchar) + ',','NULL,')
			+ '@rack_no = ' + ISNULL('''' + CAST(@rack_no AS varchar) + '''','NULL')
		, @lot_no

	IF NOT EXISTS(SELECT [lot_no] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no)
	BEGIN
		SELECT	  'FALSE' AS Is_Pass 
				, 'Data not found in trans.lots !!!' AS Error_Message_ENG
				, N'ไม่พบข้อมูลใน trans.lots !!!' AS Error_Message_THA 
				, N'ติดต่อ System' AS Handling
		RETURN;
	END

	IF (SELECT [stock_class] FROM [APCSProDB].[inv].[Inventory_classfications] WHERE [class_no] = @class_no) <> @stock_class -- add by AUN 24/09/27
	BEGIN
		SELECT	  'FALSE' AS Is_Pass 
				, 'Stock Class not match !!!' AS Error_Message_ENG
				, N'Lot นี้ไม่สามารถใช้กับ Class นี้ได้ !!! Class ใช้กับงาน ' + [name_of_process] AS Error_Message_THA 
				, N'ติดต่อ System' AS Handling
		FROM [APCSProDB].[inv].[Inventory_classfications] WHERE [class_no] = @class_no
		RETURN;
	END

	IF NOT EXISTS( SELECT 1 FROM APCSProDB.trans.lots INNER JOIN APCSProDB.method.device_names ON lots.act_device_name_id = device_names.id
	WHERE lot_no = @lot_no and device_names.is_assy_only  in (0,1))
	BEGIN
		SELECT	  'FALSE'								AS Is_Pass 
				, 'Cannot register child lot !!'		AS Error_Message_ENG
				, N'ไม่สามารถลงทะเบียน Lot ลูกได้  !!'		AS Error_Message_THA 
				, N'ติดต่อ System'						AS Handling
		RETURN;
	END

	DECLARE	  @lot_id			INT
			, @package_id		INT
			, @device_id		INT
			, @job_id			INT
			, @qty_out			INT
			, @qty_combined		INT
			, @user_id			INT
			, @process_state    INT = 0
			, @Address			NVARCHAR(100) =  ''


	SELECT	  @lot_id			= [lots].[id] 
			, @package_id		= [lots].[act_package_id] 
			, @device_id		= [lots].[act_device_name_id] 
			, @job_id			= ISNULL([lot_special_flows].[job_id],[lots].[act_job_id]) 
			, @qty_out			= [lots].[qty_out]
			, @qty_combined		= [lots].[qty_combined]
			, @rack_no			= @rack_no
			, @Address			= IIF(@stock_class = 1 
									,IIF(@rack_no = 'ON MACHINE'
									, CASE WHEN lots.is_special_flow =  1 THEN   mc_special_flows.name 
										ELSE machines.name   END  ,location_lot.address )
									,  loca_sur.address  )
	FROM [APCSProDB].[trans].[lots] 
	LEFT JOIN [APCSProDB].[trans].[special_flows] 
	ON  [lots].[special_flow_id]	= [special_flows].[id]
	AND [lots].[is_special_flow]	= 1
	LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
	ON  [special_flows].[id]		= [lot_special_flows].[special_flow_id]
	AND [special_flows].[step_no]	= [lot_special_flows].[step_no]
	LEFT JOIN [APCSProDB].[trans].[surpluses] 
	ON  [lots].[lot_no] = [surpluses].[serial_no]
	LEFT JOIN APCSProDB.trans.locations location_lot 
	ON location_lot.id = lots.location_id
	LEFT JOIN APCSProDB.mc.machines
	ON lots.machine_id = machines.id
	LEFT JOIN APCSProDB.mc.machines  mc_special_flows
	ON special_flows.machine_id = mc_special_flows.id
	LEFT JOIN APCSProDB.trans.locations AS loca_sur
	ON [surpluses].location_id = loca_sur.id
	WHERE [lots].[lot_no] = @lot_no;

	SET @user_id = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @emp_no);
	 
 
	IF EXISTS(SELECT 1 FROM APCSProDB.trans.lot_inventory WHERE lot_no = @lot_no AND stock_class = FORMAT(@stock_class,'00'))
	BEGIN
		SELECT	  'FALSE'							AS Is_Pass 
				, 'Data Lot Duplicate  !!'			AS Error_Message_ENG
				, N'ไม่สามารถลงทะเบียน Lot เดิมได้  !!'	AS Error_Message_THA 
				, N'ติดต่อ System'					AS Handling
		RETURN;
	END
 
	--IF EXISTS(SELECT 1 FROM APCSProDB.trans.lot_inventory WHERE lot_no = @lot_no AND stock_class in ('02','03'))
	--BEGIN
	--	SELECT	  'FALSE'							AS Is_Pass 
	--			, 'Data Lot Duplicate  !!'			AS Error_Message_ENG
	--			, N'ไม่สามารถลงทะเบียน Lot เดิมได้  !!'	AS Error_Message_THA 
	--			, N'ติดต่อ System'					AS Handling
	--	RETURN;
	--END
	 
	ELSE 
		BEGIN 
			BEGIN TRY
					INSERT INTO [APCSProDB].[trans].[lot_inventory]
					(
						  [lot_id]
						, [lot_no]
						, [package_id]
						, [device_id]
						, [job_id]
						, [qty_pass]
						, [qty_hasuu]
						, [qty_out]
						, [qty_combined]
						, [location_id]
						, [address]
						, [fcoino]
						, [sheet_no]
						, [stock_class]
						, [classification_no]
						, [year_month]
						, [created_at]
						, [created_by]
						, [updated_at]
						, [updated_by]
					)
					SELECT @lot_id								AS [lot_id]
						, UPPER(@lot_no)						AS [lot_no]
						, @package_id							AS [package_id]
						, @device_id							AS [device_id]
						, @job_id								AS [job_id]
						, IIF(@stock_class = 1 , @qty,0)		AS [qty_pass]
						, IIF(@stock_class in (2,3),@qty,0)		AS [qty_hasuu]
						, IIF(@stock_class in (2,3),0,@qty_out) AS [qty_out]
						, @qty_combined							AS [qty_combined]
						, UPPER(@rack_no)						AS [location_id]
						, @Address								AS [address]
						, NULL									AS [fcoino]
						, NULL									AS [sheet_no]
						, FORMAT(@stock_class,'00')				AS [stock_class]
						, @class_no								AS [classification_no]
						, FORMAT(GETDATE(),'yyyyMM')			AS [year_month]
						, GETDATE()								AS [created_at]
						, @user_id								AS [created_by]
						, NULL									AS [updated_at]
						, NULL									AS [updated_by]
	
					IF (@stock_class IN (2,3))
					BEGIN 

						UPDATE APCSProDB.trans.surpluses
						SET   in_stock	 = 4
							, updated_at = GETDATE()
							, updated_by = @user_id
						WHERE lot_id = @lot_id

						EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lot_no
							,@sataus_record_class = 2
							,@emp_no_int = 1

					END

					SELECT	  'TRUE'					AS Is_Pass 
							, 'Insert data success.'	AS Error_Message_ENG
							, N'เพิ่มข้อมูลสำเร็จ'				AS Error_Message_THA 
							, ''						AS Handling
			
			END TRY
			BEGIN CATCH
			ROLLBACK;

			SELECT	  'FALSE' AS Is_Pass
					, 'Update Faild !!' AS Error_Message_ENG
					, N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA
					, '' AS Handling

			END CATCH

		END
END
