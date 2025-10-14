
CREATE PROCEDURE   [man].[sp_get_user_identification_test]
	-- Add the parameters for the stored procedure here
	@emp_num NVARCHAR(10)
, @permission_name varchar(20) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
INSERT INTO [APIStoredProDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text] )
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [man].[sp_get_user_identification] @emp_code = '''+ @emp_num + ''''

	SELECT [employees].[id]
		, [employees].[display_name] as [name]
		, [employees].[emp_code] as [emp_num]
		, [employees].[full_name_eng] 
		, [employees].[full_name_th] as [full_name]
		--,SUBSTRING(emp_num, 3, 4) AS OPNo
		, CASE 
			WHEN PATINDEX('%[A-Z]%', [emp_code]) = 1  THEN 
				CASE 
					WHEN SUBSTRING([emp_code], 1, 2) = 'IN' THEN CAST(CAST(SUBSTRING([emp_code], PATINDEX('%[A-Z]%', [emp_code]) + 2,LEN([emp_code])) AS INT) AS VARCHAR)
					ELSE 
						CASE 
							WHEN SUBSTRING([emp_code], PATINDEX('%[A-Z]%',[emp_code]) + 1,LEN([emp_code])) LIKE '%[A-Z]%' THEN [emp_code]
							ELSE CAST(CAST(SUBSTRING([emp_code], PATINDEX('%[A-Z]%', [emp_code]) + 1,LEN([emp_code])) AS INT) AS VARCHAR)
						END
				END
			WHEN PATINDEX('%-%', [emp_code]) > 0 THEN SUBSTRING([emp_code], PATINDEX('%-%', [emp_code]) + 1,LEN([emp_code]))
			ELSE CAST(CAST([emp_code] AS INT) AS VARCHAR)
		END [OPNo]
		, [picture_data]
		, [employees].[display_name] AS [shortname]
		, SUBSTRING ([employees].[display_name], 0, LEN([employees].[display_name])  - 2 ) AS [namelabel]
		, [roles].[id] AS [rolesid] 
		, [roles].[name] AS [rolesname]
		, [permissions].[id] AS [permissionsid]
		, [permissions].[name] AS [permissionsname]	
	FROM [DWH].[man].[employees]
	LEFT JOIN [DWH].[man].[employee_roles] ON [employees].[id] = [employee_roles].[emp_id]
    LEFT JOIN [DWH].[man].[roles] ON [employee_roles].[role_id] = [roles].[id]
	LEFT JOIN [DWH].[man].[role_permissions] ON [roles].[id] = [role_permissions].[role_id]
	LEFT JOIN [DWH].[man].[permissions] ON [role_permissions].[permission_id] = [permissions].[id]
    WHERE [employees].[emp_code] = @emp_num
		AND [permissions].[name] LIKE '%'+@permission_name+'%'
END
