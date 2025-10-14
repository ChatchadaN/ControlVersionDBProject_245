-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_recipe] 
	-- Add the parameters for the stored procedure here
	@recipe varchar(20),@package varchar(20) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
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
		,'EXEC [cellcon].[sp_get_recipe] @recipe = '''+ @recipe + ''''

	if (@recipe = 'PACKAGE')
	begin
		--SELECT [name],[short_name]  from APCSProDB.method.packages where is_enabled = 1 order by [name]
		SELECT [name] as recipe_name , short_name from APCSProDB.method.packages where is_enabled = 1 order by [name]
	end 
	else if (@recipe = 'DEVICE')
	begin
		--SELECT [name] as recipe_name,[assy_name],[device_names].[ft_name],tp_rank  from APCSProDB.method.device_names 
		SELECT distinct [name] as recipe_name from APCSProDB.method.device_names order by [name]
	end
	else if (@recipe = 'TPRANK')
	begin
		--SELECT [name] as recipe_name,[assy_name],[device_names].[ft_name],tp_rank  from APCSProDB.method.device_names 
		SELECT distinct [tp_rank] as recipe_name from APCSProDB.method.device_names where tp_rank is not null and tp_rank != ''  order by [tp_rank]
	end

END
