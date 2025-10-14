-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE   [man].[sp_get_user_identification_001]
	-- Add the parameters for the stored procedure here
	@emp_num varchar(10)
	,@permission_name varchar(20) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO [APIStoredProDB].[dbo].[exec_sp_history]
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
		,'EXEC [man].[sp_get_user_identification] @emp_num = '''+ @emp_num + ''''

 
			SELECT   [users].[id]
				, [users].[name]
				, [users].[emp_num]
				,[users].[full_name]
				--,SUBSTRING(emp_num, 3, 4) AS OPNo
				, CASE 
						WHEN PATINDEX('%[A-Z]%',emp_num) = 1  THEN 
							CASE 
								WHEN SUBSTRING(emp_num,1,2) = 'IN' THEN CAST(CAST(SUBSTRING(emp_num,PATINDEX('%[A-Z]%',emp_num) + 2,LEN(emp_num)) as int) as varchar)
								ELSE 
									CASE 
										WHEN SUBSTRING(emp_num,PATINDEX('%[A-Z]%',emp_num) + 1,LEN(emp_num)) LIKE '%[A-Z]%' THEN emp_num
										ELSE CAST(CAST(SUBSTRING(emp_num,PATINDEX('%[A-Z]%',emp_num) + 1,LEN(emp_num)) as int) as varchar)
									END
							END
						WHEN PATINDEX('%-%',emp_num) > 0 THEN SUBSTRING(emp_num,PATINDEX('%-%',emp_num) + 1,LEN(emp_num))
						ELSE CAST(CAST(emp_num as int) as varchar)
					END OPNo
				,[picture_data]
				,CASE
			WHEN SUBSTRING([users].name, 1, 3) ='MR.' THEN LEFT(SUBSTRING([users].name, 5,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
			WHEN SUBSTRING([users].name, 1, 4) ='MISS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
			WHEN SUBSTRING([users].name, 1, 3) ='MRS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
			WHEN SUBSTRING([users].name, 1, 16) ='Acting Sub. Lt. ' THEN LEFT(SUBSTRING([users].name, 17,LEN([users].name)),LEN(SUBSTRING([users].name, 17,LEN([users].name)) ) - 3 )
			ELSE SUBSTRING([users].name, 1,LEN([users].name)) 
			END AS shortname
			,CASE
			WHEN SUBSTRING([users].name, 1, 3) ='MR.' THEN LEFT(SUBSTRING([users].name, 5,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
			WHEN SUBSTRING([users].name, 1, 4) ='MISS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
			WHEN SUBSTRING([users].name, 1, 3) ='MRS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
			WHEN SUBSTRING([users].name, 1, 16) ='Acting Sub. Lt. ' THEN LEFT(SUBSTRING([users].name, 17,LEN([users].name)),LEN(SUBSTRING([users].name, 17,LEN([users].name)) ) - 3 )
			ELSE SUBSTRING([users].name, 1,LEN([users].name)) 
			END AS namelabel
			,[roles].id as rolesid 
			,[roles].name as rolesname
			,[permissions].id as [permissionsid]
			,[permissions].name as [permissionsname]	
			FROM APCSProDB_lsi_110.[man].[users]
			left join APCSProDB_lsi_110.[man].[user_roles] on APCSProDB_lsi_110.[man].[users].id = APCSProDB_lsi_110.[man].[user_roles].user_id
			left join APCSProDB_lsi_110.[man].[roles] on APCSProDB_lsi_110.[man].[user_roles].role_id =APCSProDB_lsi_110.[man].[roles].id
			left join APCSProDB_lsi_110.[man].[role_permissions] on APCSProDB_lsi_110.[man].[roles].id = APCSProDB_lsi_110.[man].[role_permissions].role_id
			left join APCSProDB_lsi_110.[man].[permissions] on APCSProDB_lsi_110.[man].[role_permissions].permission_id = APCSProDB_lsi_110.[man].[permissions].id
			WHERE [users].[emp_num] = @emp_num
			and [permissions].[name] like '%'+@permission_name+'%'

	 
END
