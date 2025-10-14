-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_mixing_tg]
	-- Add the parameters for the stored procedure here
	  
	  @lotno0 VARCHAR(10) = ' '
	, @lotno1 VARCHAR(10) = ' '
	, @lotno2 VARCHAR(10) = ' '
	, @lotno3 VARCHAR(10) = ' '
	, @lotno4 VARCHAR(10) = ' '
	, @lotno5 VARCHAR(10) = ' '
	, @lotno6 VARCHAR(10) = ' '
	, @lotno7 VARCHAR(10) = ' '
	, @lotno8 VARCHAR(10) = ' '
	, @lotno9 VARCHAR(10) = ' '
	, @master_lot_no VARCHAR(10) = ' '
	, @emp_no_value char(6) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @hasuu_qty_1 INT = 0;
	DECLARE @hasuu_qty_2 INT = 0;
	DECLARE @hasuu_qty_3 INT = 0;
	DECLARE @hasuu_qty_4 INT = 0;
	DECLARE @hasuu_qty_5 INT = 0;
	DECLARE @hasuu_qty_6 INT = 0;
	DECLARE @hasuu_qty_7 INT = 0;
	DECLARE @hasuu_qty_8 INT = 0;
	DECLARE @hasuu_qty_9 INT = 0;
	DECLARE @hasuu_qty_10 INT = 0;
	DECLARE @master_lot_no_id INT = 0;
	DECLARE @emp_no_int INT = 0;

	--CONVERT VARCHAR TO INT VALUE OP_NO
	select @emp_no_int = CONVERT(INT, @emp_no_value) --Create 2021/03/15

    -- Insert statements for procedure here
	SELECT @hasuu_qty_1 = [surpluses].[pcs]
	FROM [APCSProDB].[trans].[surpluses]
	INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [surpluses].[lot_id]
	WHERE [lots].[lot_no] = @lotno0

	SELECT @hasuu_qty_2 = [surpluses].[pcs]
	FROM [APCSProDB].[trans].[surpluses]
	INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [surpluses].[lot_id]
	WHERE [lots].[lot_no] = @lotno1
	
	SELECT @hasuu_qty_3 = [surpluses].[pcs]
	FROM [APCSProDB].[trans].[surpluses]
	INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [surpluses].[lot_id]
	WHERE [lots].[lot_no] = @lotno2
	
	SELECT @hasuu_qty_4 = [surpluses].[pcs]
	FROM [APCSProDB].[trans].[surpluses]
	INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [surpluses].[lot_id]
	WHERE [lots].[lot_no] = @lotno3
	
	SELECT @hasuu_qty_5 = [surpluses].[pcs]
	FROM [APCSProDB].[trans].[surpluses]
	INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [surpluses].[lot_id]
	WHERE [lots].[lot_no] = @lotno4
	
	SELECT @hasuu_qty_6 = [surpluses].[pcs]
	FROM [APCSProDB].[trans].[surpluses]
	INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [surpluses].[lot_id]
	WHERE [lots].[lot_no] = @lotno5

	SELECT @hasuu_qty_7 = [surpluses].[pcs]
	FROM [APCSProDB].[trans].[surpluses]
	INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [surpluses].[lot_id]
	WHERE [lots].[lot_no] = @lotno6
	
	SELECT @hasuu_qty_8 = [surpluses].[pcs]
	FROM [APCSProDB].[trans].[surpluses]
	INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [surpluses].[lot_id]
	WHERE [lots].[lot_no] = @lotno7
	
	SELECT @hasuu_qty_9 = [surpluses].[pcs]
	FROM [APCSProDB].[trans].[surpluses]
	INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [surpluses].[lot_id]
	WHERE [lots].[lot_no] = @lotno8
	
	SELECT @hasuu_qty_10 = [surpluses].[pcs]
	FROM [APCSProDB].[trans].[surpluses]
	INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [surpluses].[lot_id]
	WHERE [lots].[lot_no] = @lotno9
	
	 --search data id lot standard
	SELECT @master_lot_no_id = lot_id			
	FROM [APCSProDB].[trans].[surpluses]
	where serial_no = @master_lot_no

	--SELECT [lots].[qty_pass]
	--, [lots].[qty_pass] + @hasuu_qty_1
	--+ @hasuu_qty_2
	--+ @hasuu_qty_3
	--+ @hasuu_qty_4
	--+ @hasuu_qty_5
	--+ @hasuu_qty_6
	--+ @hasuu_qty_7
	--+ @hasuu_qty_8
	--+ @hasuu_qty_9
	--+ @hasuu_qty_10
	--FROM [APCSProDB].[trans].[lots]
	--WHERE [lot_no] = @master_lot_no

	--UPDATE [APCSProDB].[trans].[lots] 
	--SET [lots].[qty_pass] = @hasuu_qty_1
	--	+ @hasuu_qty_2
	--	+ @hasuu_qty_3
	--	+ @hasuu_qty_4
	--	+ @hasuu_qty_5
	--	+ @hasuu_qty_6
	--	+ @hasuu_qty_7
	--	+ @hasuu_qty_8
	--	+ @hasuu_qty_9
	--	+ @hasuu_qty_10
	--WHERE [lot_no] = @master_lot_no

	--select @emp_no_int = CONVERT(int,@emp_no);

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
			,@emp_no_int
			,GETDATE()
			,@emp_no_int
		FROM [APCSProDB].[trans].[surpluses]
		where serial_no in (@lotno0,@lotno1,@lotno2,@lotno3,@lotno4,@lotno5,@lotno6,@lotno7,@lotno8,@lotno9)
			and (lot_id != 0)
		order by idx asc

		--add data ro tabel lot_combine_records
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
			,@emp_no_int
			,GETDATE()
			,@emp_no_int
		FROM [APCSProDB].[trans].[surpluses]
		where serial_no in (@lotno0,@lotno1,@lotno2,@lotno3,@lotno4,@lotno5,@lotno6,@lotno7,@lotno8,@lotno9)
			and (lot_id != 0)
		order by idx asc

		--Create Log 2021/09/05 time: 09:12
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		(
				[record_at]
			  , [record_class]
			  , [login_name]
			  , [hostname]
			  , [appname]
			  , [command_text]
			  , [lot_no] 
		)
		SELECT GETDATE()
			,'4'
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			,'EXEC [dbo].[atom.sp_set_mixing_tg] @empno = ''' + @emp_no_value + ''',@lotno_standard = ''' + @master_lot_no 
				+ ''',@hasuu_lotno0 = ''' + @lotno0 
				+ ''',@hasuu_lotno1 = ''' + @lotno1 
				+ ''',@hasuu_lotno2 = ''' + @lotno2
				+ ''',@hasuu_lotno3 = ''' + @lotno3
				+ ''',@hasuu_lotno4 = ''' + @lotno4
				+ ''',@hasuu_lotno5 = ''' + @lotno5
				+ ''',@hasuu_lotno6 = ''' + @lotno6
				+ ''',@hasuu_lotno7 = ''' + @lotno7
				+ ''',@hasuu_lotno8 = ''' + @lotno8
				+ ''',@hasuu_lotno9 = ''' + @lotno9 + ''''
			,@master_lot_no

END
