-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_regist_esl_002] 
	-- Add the parameters for the stored procedure here
	@lot_no AS VARCHAR(10),
	@e_slip_id AS VARCHAR(20),
	@op_no AS VARCHAR(6),
	@mc_no AS VARCHAR(50)	 =  NULL,
	@app_name AS VARCHAR(255)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO [APIStoredProDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no] 
		)
	SELECT GETDATE()
		, 4 --# 1:Insert, 2:Update, 3:Delete, 4:StoredProcedure
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		,'EXEC [trans].[sp_set_regist_esl_002] @lot_no = ''' + ISNULL(@lot_no, '') + '''' 
			+ ', @e_slip_id = ''' + ISNULL(@e_slip_id, '') + ''''  
			+ ', @op_no = ''' + ISNULL(@op_no, '') + '''' 
			+ ', @mcno = ''' + ISNULL(@mc_no, '') + '''' 
			+ ', @app_name = ''' + ISNULL(@app_name, '') + ''''
		, @lot_no 

   --  Insert statements for procedure here
	BEGIN TRANSACTION;

	IF  EXISTS (SELECT e_slip_id FROM APCSProDB.trans.lots WHERE lot_no = @lot_no AND e_slip_id IS NOT NULL	) 
	BEGIN

			SELECT	  'FALSE'															AS Is_Pass
					, 'This lot has been used at card ('+ TRIM(lots.e_slip_id) +')'		AS Error_Message_ENG
					, N'Lot นี้ถูกใช้งานอยู่ที่ card ('+ TRIM(lots.e_slip_id) +')'				AS Error_Message_THA
					, N'กรุณา Clear Card ก่อน'											AS Handling 
			FROM APCSProDB.trans.lots 
			WHERE lot_no = @lot_no

			COMMIT TRANSACTION;

		RETURN 
	END
	
	BEGIN

			BEGIN TRY 
			 
				UPDATE [APCSProDB].[trans].[lots]
				SET [e_slip_id] = UPPER(@e_slip_id)
				WHERE [lot_no] = @lot_no;

				COMMIT TRANSACTION;

				SELECT   'TRUE'						AS [Is_Pass]
						, 'Register success.'		AS [Error_Message_ENG]
						, N'อัพเดทข้อมูลเรียบร้อย'			AS [Error_Message_THA]
						, N''						AS [Handling]
				RETURN

			END TRY
			BEGIN CATCH

				ROLLBACK TRANSACTION;

				SELECT   'FALSE'					AS [Is_Pass]
						, 'Register error. ' 		AS [Error_Message_ENG]
						, N'อัพเดทข้อมูลไม่สำเร็จ '	    AS [Error_Message_THA]
						, N'อัพเดทข้อมูลไม่สำเร็จ '	    AS [Handling]
				RETURN

			END CATCH	 
	
	END 
END 
