

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_edit_special_flow]
	-- Add the parameters for the stored procedure here
	 @LotSpecialFlowsID	 INT
	, @step_no			 INT
	, @next_step_no		 INT
	, @recipe            VARCHAR(50)
	, @is_skipped        tinyint
	, @material_set_id	 INT
	, @jig_set_id		 INT
	, @yield_lcl         AS decimal(9,2)
	, @is_sblsyl	     tinyint
	, @emp_num			 VARCHAR(10)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
		BEGIN TRY


---# (1) LOG EXEC
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

		, 'EXEC [atom].[sp_set_edit_special_flow] @LotSpecialFlowsID = ''' + ISNULL(CAST(@LotSpecialFlowsID AS VARCHAR), '') 
			+ ''', @step_no = ''' + ISNULL(CAST(@step_no AS VARCHAR), '') 
			+ ''', @next_step_no = ''' + ISNULL(CAST(@next_step_no AS VARCHAR), '') 
			+ ''', @recipe = ''' + ISNULL(@recipe, '') 
			+ ''', @is_skipped = ''' + ISNULL(CAST(@is_skipped AS VARCHAR), '') 
			+ ''', @material_set_id = ''' + ISNULL(CAST(@material_set_id AS VARCHAR), '') 
			+ ''', @jig_set_id = ''' + ISNULL(CAST(@jig_set_id AS VARCHAR), '') 
			+ ''', @yield_lcl = ''' + ISNULL(CAST(@yield_lcl AS VARCHAR), '') 
			+ ''', @is_sblsyl = ''' + ISNULL(CAST(@is_sblsyl AS VARCHAR), '') + ''''
			+ ''', @emp_num = ''' + ISNULL(@emp_num, '') + ''''
		, NULL

			
		IF NOT EXISTS (SELECT  'xx' FROM [APCSProDB].[trans].[lot_special_flows] WHERE [id] = @LotSpecialFlowsID )
		BEGIN  

					SELECT	  'FALSE'			AS Is_Pass
					, 'Data Not found'			AS Error_Message_ENG
					, N'ไม่พบข้อมูลการลงทะเบียน'		AS Error_Message_THA	
					, ''						AS Handling
					COMMIT;
					RETURN

		END 
		ELSE
		BEGIN 

				UPDATE [APCSProDB].[trans].[lot_special_flows]

				SET   step_no            = @step_no 
                     , next_step_no      = @next_step_no 
                     , recipe            = @recipe 
                     , is_skipped        = @is_skipped 
                     , material_set_id   = @material_set_id 
                     , jig_set_id        = @jig_set_id 
                     , yield_lcl         = CAST(@yield_lcl AS decimal(9,2)) 
                     , is_sblsyl         = @is_sblsyl 
                 WHERE lot_special_flows.id   = @LotSpecialFlowsID
				
				 

				SELECT	  'TRUE'				AS Is_Pass
						, 'Succeeded !!'		AS Error_Message_ENG
						, N'บันทึกข้อมูลเรียบร้อย.'	AS Error_Message_THA	
						, ''					AS Handling

				COMMIT; 

				RETURN
		END 
		END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT	  'FALSE'				AS Is_Pass
				, 'Update Failed !!'		AS Error_Message_ENG
				, N'บันทึกข้อมูลผิดพลาด !!'	AS Error_Message_THA
				, ''					AS Handling
	END CATCH
END