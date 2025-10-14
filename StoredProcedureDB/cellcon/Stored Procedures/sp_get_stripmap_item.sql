-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_stripmap_item]
	-- Add the parameters for the stored procedure here
	@mc_model_id int,
	@McNo varchar = ''
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
		,'EXEC [cellcon].[sp_get_stripmap_item] @mc_model_id = ' + CAST(@mc_model_id AS varchar) + '|' + ' @mc_model_id = ' + @McNo


	SELECT [id]
      ,[machine_model_id]
      ,[bin_code]
      ,[bin_quality]
      ,[bin_code_description]
      ,[used_command]
  FROM [APCSProDB].[mc].[model_bins]
  where machine_model_id = @mc_model_id
END
