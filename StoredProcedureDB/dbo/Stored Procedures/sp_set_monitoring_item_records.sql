-- =============================================
-- Author:		<null>
-- Create date: <02/08/2022>
-- Description:	<update monitoring items and insert monitoring items records>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_monitoring_item_records]   
    @monitoring_id INT,
	@user_id VARCHAR(6),
	@target_value DECIMAL(9,1),
	@warn_value DECIMAL(9,1),
    @alarm_value DECIMAL(9,1)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
	---------------------------------------------------------------------------
	-- Log exec StoredProcedureDB
    ---------------------------------------------------------------------------	
	DECLARE @users_id INT = (SELECT id FROM [APCSProDB].[man].[users] WHERE emp_num = @user_id);

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		([record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no])
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [StoredProcedureDB].[dbo].[sp_set_monitoring_item_records] @monitoring_id = ' + ISNULL(CAST(@monitoring_id AS VARCHAR),'NULL') 
			+ ', @user_id = ' + ISNULL(CAST(@users_id AS VARCHAR),'NULL') + ''
			+ ', @target_value = ' + ISNULL(CAST(@target_value AS VARCHAR),'NULL') + ''
			+ ', @warn_value = ' + ISNULL(CAST(@warn_value AS VARCHAR),'NULL') + ''
			+ ', @alarm_value = ' + ISNULL(CAST(@alarm_value AS varchar),'NULL') + ''
		, 'Monitoring';
	---------------------------------------------------------------
	--- (1) DECLARE
	---------------------------------------------------------------
	DECLARE @monitoring_item_record_id INT;
	---------------------------------------------------------------
	--- (2) UPDATE APCSProDWH.wip_control.monitoring_items
	---------------------------------------------------------------
	UPDATE [APCSProDWH].[wip_control].[monitoring_items]
	SET [target_value] = @alarm_value
		, [warn_value] = @alarm_value 
		, [alarm_value] = @alarm_value		
		, [updated_at] = GETDATE()
		, [updated_by] = @users_id 
	WHERE [id] = @monitoring_id;
	---------------------------------------------------------------
	--- (3) UPDATE APCSProDWH.wip_control.numbers
	---------------------------------------------------------------
	SELECT @monitoring_item_record_id = [id] + 1
	FROM [APCSProDWH].[wip_control].[numbers]
	WHERE [name] = 'monitoring_item_records.id';

	UPDATE [APCSProDWH].[wip_control].[numbers]
	SET [id] = @monitoring_item_record_id
	WHERE [name] = 'monitoring_item_records.id';
	---------------------------------------------------------------
	--- (4) INSERT APCSProDWH.wip_control.monitoring_item_records
	---------------------------------------------------------------
	INSERT INTO [APCSProDWH].[wip_control].[monitoring_item_records]
		( [id]
		, [monitoring_item_id]
		, [recorded_at]
		, [target_value]
		, [warn_value]
		, [alarm_value]
		, [is_alarmed]
		, [current_value]
		, [occurred_at]
		, [cleared_at]
		, [updated_at]
		, [updated_by] )
	SELECT @monitoring_item_record_id AS [id]
		, @monitoring_id AS [monitoring_item_id]
		, GETDATE() AS [recorded_at]
		, @alarm_value AS [target_value]
		, @alarm_value AS [warn_value]
		, @alarm_value AS [alarm_value]
		, [is_alarmed]
		, [current_value]
		, [occurred_at]
		, [cleared_at]
		, GETDATE() AS [updated_at]
		, @users_id AS [updated_by]
	FROM [APCSProDWH].[wip_control].[monitoring_items]
	WHERE [id] = @monitoring_id;
END
