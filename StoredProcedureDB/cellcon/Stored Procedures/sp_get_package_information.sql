-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_package_information] 
	-- Add the parameters for the stored procedure here
	@package varchar(20)
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
		,'EXEC [cellcon].[sp_get_package_information] @package = '''+ @package + ''''
		if (@package = 'OPM')
			BEGIN
				SELECT '1' AS [pcs_per_work]
 			END
		ELSE 
			BEGIN
				SELECT [id]
			  ,[name]
			  ,[short_name]
			  ,[product_family_id]
			  ,[form_code]
			  ,[pin_num_code]
			  ,[item_code]
			  ,[is_enabled]
			  ,[package_group_id]
			  ,[cps_license_no]
			  ,[use_auto_labeler]
			  ,[pcs_per_work]
			  ,[pcs_per_tube_or_tray]
			  ,[input_plan_per_day_lot]
			  ,[input_plan_per_month_lot]
			  ,[input_plan_per_day_pcs]
			  ,[input_plan_per_month_pcs]
			  ,[is_stripmap_controlled]
			  ,[is_input_stopped]
			  ,[is_carrier_controlled]
			  ,[is_hidden_for_display]
			  ,[created_at]
			  ,[created_by]
			  ,[updated_at]
			  ,[updated_by]
			  from APCSProDB.method.packages
			  where [name] = @package OR short_name = @package
			END

END
