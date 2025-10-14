CREATE PROCEDURE [mc].[sp_get_machine]
@id AS INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET @id = CASE WHEN @id = 0 THEN null ELSE @id END
SELECT [machines].[id]
	  ,[APCSProDB].[mc].[machines].headquarter_id
	  ,[APCSProDB].[man].[headquarters].name		AS headquarter_name
      ,[machines].[name]
      ,[APCSProDB].[mc].[models].id					AS machine_model_id
	  ,[APCSProDB].[mc].[models].name				AS machine_model_name
	  ,[APCSProDB].[mc].[models].process_type		AS process_type
      ,ISNULL([cell_ip],'Not Set')					AS [cell_ip]
      ,ISNULL([machine_ip1],'Not Set')				AS [machine_ip1]
      ,CASE WHEN [is_automotive] = 1 THEN 'YES' ELSE 'NO' END			AS [is_automotive]
      ,CASE WHEN [is_disabled] = 0 THEN 'Power ON' ELSE 'Power OFF' END AS [is_disabled]
      ,[machines].[created_at]
      ,UserCreate.emp_num							AS created_by
	  ,[machines].[updated_at]
      ,UserUpdate.emp_num							AS updated_by
	  ,Fac.id										AS factory_id
	  ,Fac.name										AS factory_name
	  FROM [APCSProDB].[mc].[machines]
	  INNER JOIN [APCSProDB].man.users				AS UserCreate	ON machines.created_by = UserCreate.id
	  INNER JOIN [APCSProDB].man.users				AS UserUpdate	ON machines.updated_by = UserUpdate.id
	  INNER JOIN [APCSProDB].[man].[headquarters]					ON machines.headquarter_id = [APCSProDB].[man].[headquarters].id
	  INNER JOIN [APCSProDB].[mc].[models]							ON machines.machine_model_id = [APCSProDB].[mc].[models].id
	  INNER JOIN [APCSProDB].[man].[factories]		AS Fac			ON headquarters.factory_id = Fac.id
	  WHERE machines.id = @id or @id is null
	  ORDER BY [machines].[id]
END
