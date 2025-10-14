-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_per_frame]
	-- Add the parameters for the stored procedure here
	@Package varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	declare @package_name varchar(50),@per_frame as int
	-- interfering with SELECT statements.
	--SET NOCOUNT ON;
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
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[sp_get_per_frame] @Package =''' + @Package + ''''
    -- Insert statements for procedure here
	SELECT @per_frame = pcs_per_work ,@package_name = [name]  from APCSProDB.method.packages where [short_name] = @Package
	IF (@@ROWCOUNT <= 0 )
	begin
		select @per_frame = pcs_per_frame,@package_name = package_code  from DBx.dbo.package_outside where DBx.dbo.package_outside.package_code = @Package
	end
	if (@per_frame is not null)
	begin
	  select @per_frame as per_frame,@package_name as package
	end
  
 
   
	
END
