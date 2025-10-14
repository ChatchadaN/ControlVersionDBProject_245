-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[get_data_divide_lot] 
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = '%',
	@package_group varchar(10) = '%',
	@package varchar(20) = '%',
	@device varchar(20) = '%',
	@status int = null

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
		,'EXEC [atom].[get_data_divide_lot] @lotno = ''' + @lotno + ''',@package = ''' + @package + ''',@device = ''' + @device + ''''

	IF @status = 0
	BEGIN
		SELECT lots.lot_no
			, packages.name AS PackageName
			, device_names.name AS DeviceName
		FROM APCSProDB.trans.lots
		INNER JOIN APCSProDB.method.packages 
			ON lots.act_package_id = packages.id
		INNER JOIN APCSProDB.method.device_names 
			ON lots.act_device_name_id = device_names.id
		INNER JOIN APCSProDB.method.package_groups
			ON packages.package_group_id = package_groups.id
		LEFT JOIN APCSProDWH.atom.divided_lots
			ON divided_lots.lot_id	= lots.id
		INNER JOIN [APCSProDB].[trans].[days] AS [day_indate]
			ON [day_indate].[id] = [lots].[in_plan_date_id]
		WHERE divided_lots.lot_id IS NULL
			AND SUBSTRING(lots.lot_no,5,1) IN ('A','F','E','V','W','X','5','6','7','8')
			AND [lots].[wip_state] in (10,20,0)
			--AND [day_indate].[date_value] > convert(date, getdate())
			AND [day_indate].[date_value] > CONVERT(DATE, DATEADD(DAY, -3, GETDATE()))
			AND year([day_indate].[date_value]) <= year(convert(date, getdate()))
			AND package_groups.name LIKE @package_group
			AND packages.name LIKE @package 
			AND device_names.name LIKE @device 
			AND TRIM(lots.lot_no) LIKE @lotno + '%';

	END
	ELSE IF @status = 1
	BEGIN
		SELECT lots.lot_no
			,packages.name AS PackageName
			,device_names.name AS DeviceName
			, case when divided_lots.is_create_text = 1 then 'Pass' else 'Wait' end as is_create_text
			, case when divided_lots.is_send_text = 1 then 'Pass' else 'Wait' end as is_send_text
			, users.name AS NameCreate
			, divided_lots.created_at
		FROM APCSProDB.trans.lots
		INNER JOIN APCSProDB.method.packages 
			ON lots.act_package_id = packages.id
		INNER JOIN APCSProDB.method.device_names 
			ON lots.act_device_name_id = device_names.id
		INNER JOIN APCSProDB.method.package_groups
			ON packages.package_group_id = package_groups.id
		INNER JOIN APCSProDWH.atom.divided_lots
			ON divided_lots.lot_id	= lots.id
		LEFT JOIN APCSProDB.man.users
			ON divided_lots.created_by = users.id
		WHERE package_groups.name LIKE @package_group
			AND packages.name LIKE @package 
			AND device_names.name LIKE @device 
			AND TRIM(lots.lot_no) LIKE @lotno + '%'
			AND SUBSTRING(lots.lot_no,5,1) IN ('A','F','E','V','W','X','5','6','7','8')
		ORDER BY divided_lots.created_at ASC;
	END
END
