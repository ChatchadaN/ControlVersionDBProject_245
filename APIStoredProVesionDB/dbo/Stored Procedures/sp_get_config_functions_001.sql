-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_config_functions_001]
	-- Add the parameters for the stored procedure here
	  @app_name			AS VARCHAR(50)
	, @process			AS VARCHAR(50)	=  NULL
	, @function_name	AS VARCHAR(50)
	, @mc_no			AS VARCHAR(20)  = NULL
	, @factory_code		AS VARCHAR(20)	= NULL
	, @emp_num			AS VARCHAR(10)	= NULL
	--@factory = 1 RIST ,2 REPI

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	
	IF (@factory_code = 'All')
		BEGIN	

			SELECT	  [id]
					, [app_name]
					, ISNULL([comment],'')		 AS process 
					, ISNULL([function_name],'') AS [function_name]
					, [is_use]					 
					, ISNULL([factory_code],'')  AS [factory_code]
					, ISNULL([value],'')		 AS [value]
					, ISNULL([created_at],'')	 AS [created_at]
					, ISNULL([created_by],'')	 AS [created_by]
					, ISNULL([updated_at],'')	 AS [updated_at]
					, ISNULL([updated_by],'')	 AS [updated_by]
			FROM AppDB_app_244.[dbo].[config_functions]
			WHERE [app_name]	= @app_name 
			AND is_use			= 1 

		END 
	ELSE IF (@factory_code = 'default')
		BEGIN

			SELECT @factory_code = factories.factory_code 
			FROM  [172.16.0.110].APCSProDB.mc.machines
			LEFT JOIN [DWH].man.headquarters 
			ON machines.headquarter_id =  headquarters.id 
			LEFT JOIN [DWH].man.groups  
			ON groups.id = headquarters.group_id
			LEFT JOIN [DWH].man.factories 
			ON factories.id  = groups.factory_id
			WHERE machines.name =  @mc_no

			SELECT	  [id]
				, [app_name]
				, ISNULL([comment],'')		 AS process 
				, ISNULL([function_name],'') AS [function_name]
				, [is_use]					 
				, ISNULL([factory_code],'')  AS [factory_code]
				, ISNULL([value],'')		 AS [value]
				, ISNULL([created_at],'')	 AS [created_at]
				, ISNULL([created_by],'')	 AS [created_by]
				, ISNULL([updated_at],'')	 AS [updated_at]
				, ISNULL([updated_by],'')	 AS [updated_by]
			FROM AppDB_app_244.[dbo].[config_functions]
			WHERE [app_name]	= @app_name 
			and factory_code	= @factory_code 
			AND is_use			= 1

		END
	ELSE 
		BEGIN

		IF (@mc_no  IS NOT NULL )
		BEGIN 
				SELECT @factory_code = factories.factory_code 
				FROM  [172.16.0.110].APCSProDB.mc.machines
				LEFT JOIN [DWH].man.headquarters 
				ON machines.headquarter_id =  headquarters.id 
				LEFT JOIN [DWH].man.groups  
				ON groups.id = headquarters.group_id
				LEFT JOIN [DWH].man.factories 
				ON factories.id  = groups.factory_id
				WHERE machines.name =  @mc_no
		END 
		ELSE
		BEGIN 
		 
				SELECT  @factory_code = factories.factory_code
				FROM [DWH].[man].[employees]
				LEFT JOIN [DWH].man.employee_organizations 
				ON [employees].id = employee_organizations.emp_id
				LEFT JOIN [DWH].man.organizations
				ON employee_organizations.organization_id = organizations.id
				LEFT JOIN [DWH].man.groups   
				ON groups.[name] = organizations.[group]
				LEFT JOIN  [DWH].man.factories  
				ON factories.id = groups.factory_id
				WHERE emp_code = @emp_num
		END

		 
			SELECT	  [id]
					, [app_name]
					, ISNULL([comment],'')		 AS process 
					, ISNULL([function_name],'') AS [function_name]
					, [is_use]					 
					, ISNULL([factory_code],'')  AS [factory_code]
					, ISNULL([value],'')		 AS [value]
					, ISNULL([created_at],'')	 AS [created_at]
					, ISNULL([created_by],'')	 AS [created_by]
					, ISNULL([updated_at],'')	 AS [updated_at]
					, ISNULL([updated_by],'')	 AS [updated_by]
			FROM AppDB_app_244.[dbo].[config_functions]
			WHERE [app_name]	= @app_name 
			AND function_name	= @function_name 
		--	AND factory_code	= @factory_code 
			AND is_use = 1
		
		END
END
