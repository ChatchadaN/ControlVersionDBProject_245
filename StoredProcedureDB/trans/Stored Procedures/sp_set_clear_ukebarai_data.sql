-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_clear_ukebarai_data]
	-- Add the parameters for the stored procedure here
	@id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	--<<--------------------------------------------------------------------------
	--- ** log exec
	-->>-------------------------------------------------------------------------
	insert into [StoredProcedureDB].[dbo].[exec_sp_history]
	(
		[record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
	)
	select GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'exec [dbo].[sp_set_clear_ukebarai_data] id = ' + ISNULL(CAST(@id as varchar),'')
		, (select cast([lot_no] as varchar) from [APCSProDWH].[dbo].[ukebarais] where [id] = @id);
	--<<--------------------------------------------------------------------------
	--- ** delete
	-->>-------------------------------------------------------------------------
	delete from [APCSProDWH].[dbo].[ukebarais] where [id] = @id;
END
