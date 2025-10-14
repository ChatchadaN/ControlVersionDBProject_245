-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_lot_combine_records] 
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
   ,@sataus_record_class int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @LOTNO_ID INT
	DECLARE @emp_no_int INT = 0
	DECLARE @LOTNO_ID_chk INT = 0


	SELECT @LOTNO_ID = id FROM APCSProDB.trans.lots WHERE lot_no = @lotno
	SELECT @LOTNO_ID_chk = lot_id FROM APCSProDB.trans.lot_combine_records WHERE lot_id = @LOTNO_ID

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text]
	  , [lot_no])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[tg_sp_set_lot_combine_records] @lotno = ''' + @lotno + ''',@sataus_record_class = ''' + CONVERT (varchar (10), @sataus_record_class) + ''''
		,@lotno

	--Update date : 2021/12/06 Time : 17.24
    -- Insert statements for procedure here
	IF @sataus_record_class = 2 --UPDATE
	BEGIN
			--UPDATE APCSProDB.trans.lot_combine_records
			--SET record_class = 2
			--,updated_at = GETDATE()
			--WHERE lot_id = @LOTNO_ID
			--add data IN tabel lot_combine_records
			INSERT INTO APCSProDB.trans.lot_combine_records
			(
				 recorded_at
				,operated_by
				,record_class
				,lot_id
				,idx
				,member_lot_id
				,created_at
				,created_by
				,updated_at
				,updated_by
			)
			SELECT 
				 GETDATE()
				 ,@emp_no_int
				 ,2
				 ,@LOTNO_ID
				,(select COUNT(@LOTNO_ID) -1 from [APCSProDB].[trans].[surpluses] where serial_no = @lotno) - 1 + (ROW_NUMBER() over (order by serial_no)) as idx
				,lot_id 
				,GETDATE()
				,''
				,GETDATE()
				,''
			FROM [APCSProDB].[trans].[surpluses]
			where serial_no = @lotno
			order by idx asc
	END
	ELSE IF @sataus_record_class = 3 --CANCEL OR DELETE 
	BEGIN
			--UPDATE APCSProDB.trans.lot_combine_records
			--SET record_class = 3
			--,updated_at = GETDATE()
			--WHERE lot_id = @LOTNO_ID
			--add data IN tabel lot_combine_records
			INSERT INTO APCSProDB.trans.lot_combine_records
			(
				 recorded_at
				,operated_by
				,record_class
				,lot_id
				,idx
				,member_lot_id
				,created_at
				,created_by
				,updated_at
				,updated_by
			)
			SELECT 
				 GETDATE()
				 ,@emp_no_int
				 ,3
				 ,@LOTNO_ID
				,(select COUNT(@LOTNO_ID) -1 from [APCSProDB].[trans].[surpluses] where serial_no = @lotno) - 1 + (ROW_NUMBER() over (order by serial_no)) as idx
				,lot_id 
				,GETDATE()
				,''
				,GETDATE()
				,''
			FROM [APCSProDB].[trans].[surpluses]
			where serial_no = @lotno
			order by idx asc
	END
	ELSE IF @sataus_record_class = 1
	BEGIN
		IF @LOTNO_ID_chk = 0
		BEGIN
			INSERT INTO APCSProDB.trans.lot_combine 
			(
			 lot_id
			,idx
			,member_lot_id
			)
			SELECT 
				 @LOTNO_ID
				,(select COUNT(@LOTNO_ID) -1 from [APCSProDB].[trans].[surpluses] where serial_no = @lotno) - 1 + (ROW_NUMBER() over (order by serial_no)) as idx
				--,'1' as idx
				,lot_id 
			FROM [APCSProDB].[trans].[surpluses]
			where serial_no = @lotno
			order by idx asc

			--add data IN tabel lot_combine_records
			INSERT INTO APCSProDB.trans.lot_combine_records
			(
				 recorded_at
				,operated_by
				,record_class
				,lot_id
				,idx
				,member_lot_id
				,created_at
				,created_by
				,updated_at
				,updated_by
			)
			SELECT 
				 GETDATE()
				 ,@emp_no_int
				 ,1
				 ,@LOTNO_ID
				,(select COUNT(@LOTNO_ID) -1 from [APCSProDB].[trans].[surpluses] where serial_no = @lotno) - 1 + (ROW_NUMBER() over (order by serial_no)) as idx
				,lot_id 
				,GETDATE()
				,''
				,GETDATE()
				,''
			FROM [APCSProDB].[trans].[surpluses]
			where serial_no = @lotno
			order by idx asc
		END
		ELSE
		BEGIN
			UPDATE APCSProDB.trans.lot_combine_records
			SET record_class = 2
			,updated_at = GETDATE()
			WHERE lot_id = @LOTNO_ID
		END
		
	END

END
