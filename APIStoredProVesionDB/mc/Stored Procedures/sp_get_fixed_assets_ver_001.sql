-- =============================================
-- Author:		<Author,,Nutchanat K.>
-- Create date: <12/09/2025>
-- Description:	<Get fixed_assets>
-- =============================================
CREATE PROCEDURE [mc].[sp_get_fixed_assets_ver_001]
@fixed_num AS VARCHAR(20) = 0

AS
BEGIN
	SET NOCOUNT ON;
	SET @fixed_num = CASE WHEN @fixed_num = 0 THEN null ELSE @fixed_num END
SELECT  [fixed_asset_num]
      ,[fixed_asset_name]
      ,[machine_id]
      ,[is_disabled]
      ,[last_acc_location_id]
      ,ISNULL(CONVERT(VARCHAR,[fixed_assets].[created_at],120),'')   AS [created_at]
      ,ISNULL(UserCreate.emp_code,'')		AS created_by
	  ,ISNULL(CONVERT(VARCHAR,[fixed_assets].[updated_at],120),'')   AS [updated_at]
      ,ISNULL(UserUpdate.emp_code,'')		AS updated_by
  FROM [DWH].[mc].[fixed_assets]
	  LEFT JOIN [DWH].man.employees		AS UserCreate	ON fixed_assets.created_by = UserCreate.id
	  LEFT JOIN [DWH].man.employees		AS UserUpdate	ON fixed_assets.updated_by = UserUpdate.id
	WHERE fixed_assets.fixed_asset_num = @fixed_num or @fixed_num is null
END
