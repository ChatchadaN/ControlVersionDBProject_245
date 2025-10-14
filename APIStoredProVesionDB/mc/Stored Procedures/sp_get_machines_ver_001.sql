-- =============================================
-- Author:		<Author,,Nutchanat K.>
-- Create date: <Create Date,,29/07/2025>
-- Description:	<Description,,Get Machines List>
-- =============================================
CREATE PROCEDURE [mc].[sp_get_machines_ver_001]
@id AS INT = 0

AS
BEGIN
	SET NOCOUNT ON;
	SET @id = CASE WHEN @id = 0 THEN null ELSE @id END
SELECT [machines].[id]
	  ,[DWH].[mc].[machines].headquarter_id
	  ,[DWH].[man].[headquarters].name		AS headquarter_name
      ,[machines].[name]					
      ,[DWH].[mc].[models].id					AS machine_model_id
	  ,[DWH].[mc].[models].name				AS machine_model
	  --,[DWH].[mc].[models].process_type		AS process_type
	   --,[DWH].[mc].item_labels.label_eng	    AS process_type
	  ,makers.[name]						AS maker_name
      ,ISNULL([cell_ip],'')			AS [cell_ip]
      ,ISNULL([machine_ip1],'')		AS [machine_ip1]
	  ,ISNULL([location_id],'')     AS [location_id]
	  ,ISNULL(locations.[name],'')	AS location_name
      ,ISNULL(CONVERT(VARCHAR,[machine_arrived],23),'') AS [machine_arrived]
      ,ISNULL([serial_no],'')       AS [serial_no]
	  ,ISNULL([machine_level],'') 	AS [machine_level]					
      --,CASE WHEN [machine_level] = 1 THEN '1: Automotive'  ELSE '0: Not Automotive' END			AS [machine_level_name]
	  ,[DWH].[mc].item_labels.label_eng	    AS machine_level_name
	  ,[is_disabled]  AS [is_disabled]
      --,CASE WHEN [is_disabled] = 0 THEN '0: Enabled' ELSE '1: Disbled' END AS [is_disabled]
	  --,CASE WHEN [is_disabled] = 0 THEN 'Power ON' ELSE 'Power OFF' END AS [is_disabled]
	  ,is_fictional
	  ,'' AS fixed_assets
	  ,'' AS safety_registers
      ,ISNULL(CONVERT(VARCHAR,[machines].[created_at],120),'')   AS [created_at]
      ,ISNULL(UserCreate.emp_code,'')		AS created_by
	  ,ISNULL(CONVERT(VARCHAR,[machines].[updated_at],120),'')   AS [updated_at]
      ,ISNULL(UserUpdate.emp_code,'')		AS updated_by

	  FROM [DWH].[mc].[machines]
	  LEFT JOIN [DWH].man.employees		AS UserCreate	ON machines.created_by = UserCreate.id
	  LEFT JOIN [DWH].man.employees		AS UserUpdate	ON machines.updated_by = UserUpdate.id
	  INNER JOIN [DWH].[man].[headquarters]					ON machines.headquarter_id = [DWH].[man].[headquarters].id
	  LEFT JOIN [DWH].[mc].[models]						ON machines.machine_model_id = [DWH].[mc].[models].id
	  LEFT JOIN [DWH].[trans].[locations]					ON machines.location_id = locations.id
	  LEFT JOIN [DWH].[mc].[makers]							ON models.maker_id = makers.id
	  LEFT JOIN [DWH].[mc].[item_labels]					ON [machines].[machine_level] = [item_labels].val and item_labels.name = 'machine.machine_level'

	  WHERE machines.id = @id or @id is null
	  ORDER BY [machines].[id]
END
