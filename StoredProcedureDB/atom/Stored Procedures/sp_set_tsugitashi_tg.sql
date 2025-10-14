-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_tsugitashi_tg]
	-- Add the parameters for the stored procedure here
	 @master_lot_no VARCHAR(10)
	,@hasuu_lot_no VARCHAR(10) = ''
	,@masterqty int = 0
	,@hasuuqty int = 0
	,@OP_No int = 0

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--DECLARE @hasuu_qty INT = 0;
	DECLARE @master_lot_no_id INT
	DECLARE @emp_no_int INT = 0
	DECLARE @LOTNO_ID_chk INT = 0
   
	 --search data id lot standard
	SELECT @master_lot_no_id = lot_id			
	FROM [APCSProDB].[trans].[surpluses]
	where serial_no = @master_lot_no

	SELECT @LOTNO_ID_chk = lot_id FROM APCSProDB.trans.lot_combine WHERE lot_id = @master_lot_no_id -- Edit 2021/05/24

	------------------------------------ Get EmpnoId #Modify : 2024/12/26 ------------------------------------
	DECLARE @GetEmpno varchar(6) = ''
	DECLARE @EmpnoId int = null

	SELECT @GetEmpno = FORMAT(CAST(@OP_No AS INT), '000000')
	SELECT @EmpnoId = id FROM [APCSProDB].[man].[users] WHERE [emp_num] = @GetEmpno
	------------------------------------ End EmpnoId #Modify : 2024/12/26 ------------------------------------

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [atom].[sp_set_tsugitashi_tg] @lot_standard = ''' + @master_lot_no + ''',@lot_hasuu = ''' + @hasuu_lot_no + ''',@Qty_LotStandard = ''' + CONVERT (varchar (10), @masterqty) + ''',@hasuuqty = ''' + CONVERT (varchar (10), @hasuuqty) + ''',@op_no = ''' + CONVERT (varchar (10), @OP_No) + ''''

	IF(@hasuuqty > 0)
	BEGIN
		IF @LOTNO_ID_chk = 0
		BEGIN
			-- INSERT DATA TO TABEL LOT_COMBINE
			INSERT INTO APCSProDB.trans.lot_combine 
			(
			 lot_id
			,idx
			,member_lot_id
			,created_at
			,created_by
			,updated_at
			,updated_by
			)
			SELECT 
				 @master_lot_no_id
				,(select COUNT(@master_lot_no_id) -1 from [APCSProDB].[trans].[surpluses] where serial_no = @master_lot_no) - 1 + (ROW_NUMBER() over (order by serial_no)) as idx
				--,'1' as idx
				,lot_id
				,GETDATE()
				--,@OP_No
				,@EmpnoId  --new
				,GETDATE()
				--,@OP_No
				,@EmpnoId  --new
			FROM [APCSProDB].[trans].[surpluses]
			where serial_no = @hasuu_lot_no
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
				 ,@master_lot_no_id
				,(select COUNT(@master_lot_no_id) -1 from [APCSProDB].[trans].[surpluses] where serial_no = @master_lot_no) - 1 + (ROW_NUMBER() over (order by serial_no)) as idx
				,lot_id 
				,GETDATE()
				--,@OP_No
				,@EmpnoId  --new
				,GETDATE()
				--,@OP_No
				,@EmpnoId  --new
			FROM [APCSProDB].[trans].[surpluses]
			where serial_no = @hasuu_lot_no
			order by idx asc
		END
		ELSE 
		BEGIN
			UPDATE APCSProDB.trans.lot_combine_records
			SET record_class = 2
			,updated_at = GETDATE()
			--,updated_by = @OP_No
			,updated_by = @EmpnoId  --new
			WHERE lot_id = @master_lot_no_id
		END
	END
	ELSE IF(@hasuu_lot_no = '')  --Update Condition 2021/03/30 is check frist lot
	BEGIN
		IF @LOTNO_ID_chk = 0
		BEGIN
			-- INSERT DATA TO TABEL LOT_COMBINE
			INSERT INTO APCSProDB.trans.lot_combine 
			(
			 lot_id
			,idx
			,member_lot_id
			,created_at
			,created_by
			,updated_at
			,updated_by
			)
			SELECT 
				 @master_lot_no_id
				,(select COUNT(@master_lot_no_id) -1 from [APCSProDB].[trans].[surpluses] where serial_no = @master_lot_no) - 1 + (ROW_NUMBER() over (order by serial_no)) as idx
				--,'1' as idx
				,lot_id
				,GETDATE()
				--,@OP_No
				,@EmpnoId  --new
				,GETDATE()
				--,@OP_No
				,@EmpnoId  --new
			FROM [APCSProDB].[trans].[surpluses]
			where serial_no = @master_lot_no
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
				 ,@master_lot_no_id
				,(select COUNT(@master_lot_no_id) -1 from [APCSProDB].[trans].[surpluses] where serial_no = @master_lot_no) - 1 + (ROW_NUMBER() over (order by serial_no)) as idx
				,lot_id 
				,GETDATE()
				--,@OP_No
				,@EmpnoId  --new
				,GETDATE()
				--,@OP_No
				,@EmpnoId  --new
			FROM [APCSProDB].[trans].[surpluses]
			where serial_no = @master_lot_no
			order by idx asc
		END
		ELSE 
		BEGIN
			UPDATE APCSProDB.trans.lot_combine_records
			SET record_class = 2
			,updated_at = GETDATE()
			--,updated_by = @OP_No
			,updated_by = @EmpnoId  --new
			WHERE lot_id = @master_lot_no_id
		END
	END

END
