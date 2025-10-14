-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_capillary_endlot]
	-- Add the parameters for the stored procedure here
		@CAPID AS INT,
		@LOTNo AS VARCHAR(10),
		@OPNo AS VARCHAR(6),
		@MCNo AS VARCHAR(50),
		@LTValue AS INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRY
	DECLARE @LOT_ID as INT
			,@LOT_Process as INT
			,@Record_ID as INT
			,@OPID as INT


	
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history_jig]
		([record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
		, jig_id
		, barcode)
	SELECT GETDATE()
		, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [StoredProcedureDB].[jig].[sp_set_capillary_endlot] @CAPID = ''' + ISNULL(CAST(@CAPID AS varchar),'') 
			+ ''', @LTValue = ''' + ISNULL(CAST(@LTValue AS varchar),'') 
			+ ''', @MCNo = ''' + ISNULL(CAST(@MCNo AS varchar),'') 
			+ ''', @app_name = ''' + ISNULL(CAST('Cellcontroller' AS varchar),'') + ''''
		, @LOTNo
		, @CAPID
		, ''

		SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)


		UPDATE APCSProDB.trans.jig_conditions
			SET [value] =  @LTValue
			, reseted_at = GETDATE()
			, reseted_by = @OPID
		WHERE id = @CAPID

		--/////////////////Lot Jig//////////////
		INSERT INTO  [APCSProDB].[trans].[jig_condition_records]
           (
						  [day_id]
						, [recorded_at]
						, [jig_id]
						, [control_no]
						, [val]
						, [reseted_at]
						, [reseted_by]
						, [periodcheck_value]
						, accumulate_lifetime
		   )
		   	SELECT        (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
						, GETDATE()
						, id
						, control_no
						, [value]
						, GETDATE()
						, @OPID
						, periodcheck_value 
						, accumulate_lifetime
		   FROM  APCSProDB.trans.jig_conditions
		   WHERE id = @CAPID

		SET @LOT_ID = (SELECT id FROM APCSProDB.trans.lots where lot_no = @LOTNO)
		SET @LOT_Process = (SELECT TOP(1) id FROM APCSProDB.trans.lot_process_records WHERE lot_id = @LOT_ID order by id desc)
		--SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)

		INSERT INTO APCSProDB.trans.jig_records 
		(	  [day_id]
			, [record_at]
			, [jig_id]
			, [jig_production_id]
			, [created_at]
			, [created_by]
			, [operated_by]
			, transaction_type
			, mc_no
			, lot_no
			, record_class
		) 
		VALUES
		(
			(SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
			,GETDATE()
			,@CAPID
			,(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @CAPID)
			, GETDATE()
			,@OPID
			,@OPNo
			,'End Lot'
			,@MCNo
			,@LOTNo
			,15
		)

		SET @Record_ID = (SELECT TOP(1) id 
		FROM APCSProDB.trans.jig_records 
		WHERE jig_id = @CAPID ORDER BY id DESC)
		INSERT INTO APCSProDB.trans.lot_jigs 
		VALUES (@LOT_Process,@CAPID,@Record_ID)

		SELECT   'TRUE' AS Is_Pass 
				, 'Success !!' AS Error_Message_ENG
				, N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA
				, '' AS Handling
	END TRY
	BEGIN CATCH
		SELECT   'FALSE' AS Is_Pass 
				,'End Lot Fail !!' AS Error_Message_ENG
				,N'การบันทึกการจบการผลิตผิดพลาด !!' AS Error_Message_THA
				,N' กรุณาติดต่อ System' AS Handling
	END CATCH
END
