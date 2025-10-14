-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_update_version_incoming_label]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Status char(50) = ''
    -- Insert statements for procedure here
	SET @Status = N'UPDATE VERSION INCOMING LBAEL SUCCESS'

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
			,'EXEC [dbo].[sp_update_version_incoming_label] @lot_no = ''' + @lotno + ''',@device_loths = ''' + @Status + ''''

	IF @lotno != ''
	BEGIN
		update APCSProDB.trans.incoming_labels 
		set version = 1
		where SUBSTRING(arrival_packing_no,1,10 ) = @lotno
	END
	

END
