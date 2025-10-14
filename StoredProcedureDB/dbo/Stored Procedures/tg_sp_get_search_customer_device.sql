-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_search_customer_device] 
	-- Add the parameters for the stored procedure here
	@device_name varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

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
		,'EXEC [dbo].[tg_sp_get_search_customer_device] @device_name = ''' + @device_name + ''''


    -- Insert statements for procedure here
	select 
	case when multi_label.device_name != @device_name then 'No CustomerDevice'
		else multi_label.user_model_name end as Customer_Device
	from [APCSProDB].[method].[multi_labels]  as multi_label
	where device_name =  @device_name

	--select *  from [APCSProDB].[method].[multi_labels] where device_name = 'BM60055FV-CE2'


END
