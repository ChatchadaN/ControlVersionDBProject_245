-- =============================================
-- Author:		<Author,,Nutchanat K.>
-- Create date: <Create Date,,08/08/2025>
-- Description:	<Description,,Get mc_groups List>
-- =============================================
CREATE PROCEDURE [mc].[sp_get_mc_groups_ver_001]
@id AS INT = 0

AS
BEGIN
	SET NOCOUNT ON;
	SET @id = CASE WHEN @id = 0 THEN null ELSE @id END
SELECT [groups].[id]
      ,[groups].[name]
      ,[groups].[product_family_id]
	  ,[product_families].[name] AS [product_family]
 	  ,ISNULL([groups].[symbol_machine_id],'')			AS [cell_ip]
	  ,ISNULL(CONVERT(VARCHAR,[groups].[created_at],120),'') AS [created_at]
      ,ISNULL(UserCreate.emp_code	,'')				AS created_by
	  ,ISNULL(CONVERT(VARCHAR,[groups].[updated_at],120), '' ) AS [updated_at]
      ,ISNULL(UserUpdate.emp_code, '' )					AS updated_by
  FROM [DWH].[mc].[groups]

	  LEFT JOIN [DWH].man.employees		AS UserCreate	ON [groups].created_by = UserCreate.id
	  LEFT JOIN [DWH].man.employees		AS UserUpdate	ON [groups].updated_by = UserUpdate.id
	  INNER JOIN  [APCSProDB].[man].[product_families] ON [groups].[product_family_id] = [product_families].id
	  WHERE [groups].[id] = @id or @id is null

END
