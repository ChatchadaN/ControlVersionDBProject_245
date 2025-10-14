-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_carrier_data]
	-- Add the parameters for the stored procedure here
	@lotno nvarchar(20) ,
	@carrierno varchar(50),
	@type varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	if(@type = 'Load')
	begin
		if(@carrierno = '')
			begin
				UPDATE APCSProDB.trans.lots
				SET carrier_no = null 
				WHERE lot_no = @lotno
			end
		else
		begin
			UPDATE APCSProDB.trans.lots
			SET carrier_no = @carrierno
			WHERE lot_no = @lotno
		end
	end
	else if(@type = 'Unload')
	begin
	if(@carrierno = '')
		begin
			UPDATE APCSProDB.trans.lots
			SET next_carrier_no = null
			WHERE lot_no = @lotno
		end
	Else
		begin
			UPDATE APCSProDB.trans.lots
			SET next_carrier_no = @carrierno
			WHERE lot_no = @lotno
		end
	end

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text]
	  ,lot_no )
	  
		SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[sp_set_carrier_data] @lotno = '''+ @lotno +''', @carrierno = ''' + @carrierno +''', @type = ''' + @type + ''''
		, @lotno
END
