-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_wb_rack_wip]
	-- Add the parameters for the stored procedure here
	@lotno VARCHAR(10),@mcno VARCHAR(20),@opno VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @machine_no varchar(20),@is_pass INT,@reason NVARCHAR(200),@rack_id INT,@input_rack_time DATETIME;
	SET @is_pass = 1 
	SET @reason = ''
	SET NOCOUNT ON;

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text])
	SELECT GETDATE()
		,'4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
		,ORIGINAL_LOGIN()
		,@mcno
		,APP_NAME()
		,'EXEC [cellcon].[sp_set_wb_rack_wip] @lot_no =''' + @lotno + '''' + ' @mc_no =''' + @mcno + '''' + ' @opno =' + @opno + ''''
	

    -- Insert statements for procedure here
	SELECT @machine_no = MachineRequest,@rack_id = RackID,@input_rack_time = InputRackTime
	 FROM DBx.WIP.WBWIP 
	 WHERE (LotNo = @lotno) AND OutputRackTime IS NULL
	
	--IF (@@ROWCOUNT = 0)
	--BEGIN
	--	SELECT @is_pass = '0',@reason = N'lot not found'
	--END
	--ELSE IF (@machine_no IS NULL)
	--BEGIN
	--	SELECT @is_pass = '0',@reason = 'LotNo:' + @lotno + N' นี้ยังไม่มีการ request'
	--END
	--ELSE IF (@machine_no != @mcno)
	--BEGIN
	--	SELECT @is_pass = '0',@reason = 'machine :' + @machine_no + N' ได้ทำการจองเรียบร้อยแล้ว'
	--END
	IF (@@ROWCOUNT = 0)
	BEGIN
		SELECT @is_pass = 1,@reason = N'lot not found'
	END
    ELSE IF (@is_pass = 1)
	BEGIN
		UPDATE DBx.WIP.WBRackWIP SET UseLot = 0 
		WHERE ID = @rack_id

		UPDATE DBx.[WIP].[WBWIP] SET [OutputRackTime] = GETDATE(),[OPNoOutputRack] = @opno 
		WHERE InputRackTime = @input_rack_time AND LotNo = @lotno

	END

	SELECT @is_pass as is_pass,@reason as reason
END
