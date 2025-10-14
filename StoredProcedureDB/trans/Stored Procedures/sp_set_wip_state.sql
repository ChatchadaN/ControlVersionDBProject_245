-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_wip_state]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10),
	@wip_state int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	declare @wip_state_old int = (select wip_state from [APCSProDB].[trans].[lots] where lot_no = @lot_no)
	
	if (@wip_state != 0)
	begin
		update [APCSProDB].[trans].[lots]
			set wip_state = @wip_state
			,carrier_no = null   --update 2022/08/11 time : 14.12
		where lot_no = @lot_no
	end

	declare @wip_state_new int = (select wip_state from [APCSProDB].[trans].[lots] where lot_no = @lot_no)

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
	SELECT 
		GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [trans].[sp_set_wip_state] @lot_no = ''' + @lot_no + ''' wip_state ' + CAST(@wip_state_old as varchar) + ' --> ' + CAST(@wip_state_new as varchar)
		, @lot_no

END
