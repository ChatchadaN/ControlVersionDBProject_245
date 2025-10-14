-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_set_clear_data_ukebarai]
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
		, 'exec [if].[sp_set_clear_data_ukebarai] id = ' + ISNULL(CAST(@id AS VARCHAR(50)),'')
		, (SELECT CAST([lot_no] AS VARCHAR(10)) FROM [APCSProDWH].[dbo].[ukebarais] WHERE [id] = @id);
	--<<--------------------------------------------------------------------------
	--- ** delete
	-->>-------------------------------------------------------------------------
	DELETE FROM [APCSProDWH].[dbo].[ukebarais] WHERE [id] = @id;
END
