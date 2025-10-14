-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_cellcon_config]
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
					, [comment] AS process
					, [function_name]
					, [is_use]
					, [factory_code]
					, [value]
					, [created_at]
					, [created_by]
					, [updated_at]
					, [updated_by]
			FROM [APCSProDB].[cellcon].[config_functions]
			WHERE [app_name]	= @app_name 
			AND is_use			= 1

		END 
	ELSE IF (@factory_code = 'default')
		BEGIN

			SELECT @factory_code = factories.factory_code 
			FROM  APCSProDB.mc.machines
			INNER JOIN APCSProDB.man.headquarters
			ON machines.headquarter_id =  headquarters.id 
			INNER JOIN APCSProDB.man.factories
			ON factories.id  = headquarters.factory_id
			WHERE machines.name =  @mc_no

			SELECT	  [id]
					, [app_name]
					, [comment] AS process
					, [function_name]
					, [is_use]
					, [factory_code]
					, [value]
					, [created_at]
					, [created_by]
					, [updated_at]
					, [updated_by]
			FROM [APCSProDB].[cellcon].[config_functions]
			WHERE [app_name]	= @app_name 
			and factory_code	= @factory_code 
			AND is_use			= 1

		END
	ELSE 
		BEGIN

		IF (@mc_no  IS NOT NULL )
		BEGIN 
				SELECT @factory_code = factories.factory_code 
				FROM  APCSProDB.mc.machines
				INNER JOIN APCSProDB.man.headquarters
				ON machines.headquarter_id =  headquarters.id 
				INNER JOIN APCSProDB.man.factories
				ON factories.id  = headquarters.factory_id
				WHERE machines.name =  @mc_no
		END 
		ELSE
		BEGIN 
		 
				SELECT  @factory_code = factories.factory_code
				FROM APCSProDB.man.users
				INNER JOIN APCSProDB.man.user_organizations 
				ON users.id = user_organizations.user_id
				INNER JOIN APCSProDB.man.organizations 
				ON user_organizations.organization_id = organizations.id
				INNER JOIN APCSProDB.man.headquarters 
				ON organizations.headquarter_id = headquarters.id
				INNER JOIN APCSProDB.man.factories 
				ON headquarters.factory_id = factories.id
				WHERE emp_num = @emp_num
		END

		 
			SELECT	  [id]
					, [app_name]
					, [comment] AS process
					, [function_name]
					, [is_use]
					, [factory_code]
					, [value]
					, [created_at]
					, [created_by]
					, [updated_at]
					, [updated_by]		
			FROM [APCSProDB].[cellcon].[config_functions] 
			WHERE [app_name]	= @app_name 
			AND function_name	= @function_name 
			AND factory_code	= @factory_code 
			AND is_use = 1
		
		END
END
