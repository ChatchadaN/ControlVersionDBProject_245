-- =============================================
-- Author:		<Author,,Nutchanat K.>
-- Create date: <Create Date,,08/08/2025>
-- Description:	<Description,,Get mc_groups List>
-- =============================================
CREATE PROCEDURE [mc].[sp_get_mc_models_ver_001]
@id AS INT = 0

AS
BEGIN
	SET NOCOUNT ON;
	SET @id = CASE WHEN @id = 0 THEN null ELSE @id END
SELECT [models].[id] AS model_id
      ,[models].[name] AS model_name
      ,isnull([models].[short_name],'') AS [short_name]
      ,[headquarter_id] AS hq_id
	  ,headquarters.[name] AS hq_name
      ,[maker_id] AS maker_id
	  ,[makers].[name] AS maker_name
      --,[process_type]
	  ,process.label_eng AS [process_type]
      ,[map_using]
      ,[map_type]
      ,ISNULL([bin_type],'')   AS   [bin_type]
	  ,ISNULL([is_linked_with_work],'')   AS   [is_linked_with_work]
	  ,ISNULL([enable_lot_max],'')   AS   [enable_lot_max]
	  ,ISNULL([ppid_type1],'')   AS   [ppid_type1]
	  ,ISNULL([ppid_type2],'')   AS   [ppid_type2]
	  ,ISNULL([is_carrier_register],'')   AS   [is_carrier_register]
	  ,ISNULL([is_carrier_transfer],'')   AS   [is_carrier_transfer]
	  ,ISNULL([is_carrier_verification_setup],'')   AS   [is_carrier_verification_setup]
	  ,ISNULL([is_carrier_verification_end],'')   AS   [is_carrier_verification_end]
	  ,ISNULL([limit_sec_for_carrierinput],'')   AS   [limit_sec_for_carrierinput]
	  ,ISNULL([allowed_control_condition],'')   AS   [allowed_control_condition]
	  ,ISNULL([is_magazine_register],'')   AS   [is_magazine_register]
	  ,ISNULL([is_magazine_transfer],'')   AS   [is_magazine_transfer]
	  ,ISNULL([is_magazine_verification_setup],'')   AS   [is_magazine_verification_setup]
	  ,ISNULL([is_magazine_verification_end],'')   AS   [is_magazine_verification_end]
	  ,ISNULL([limit_sec_for_magazineinput],'')   AS   [limit_sec_for_magazineinput]
	  ,ISNULL([wafer_map_using],'')   AS   [wafer_map_using]
	  ,ISNULL([wafer_map_type],'')   AS   [wafer_map_type]
	  ,ISNULL([wafer_map_bin_type],'')   AS   [wafer_map_bin_type]
	  ,ISNULL(CONVERT(VARCHAR,[models].[created_at],120),'') AS [created_at]
      ,ISNULL(UserCreate.emp_code,'')				AS created_by
	  ,ISNULL(CONVERT(VARCHAR,[models].[updated_at],120), '' ) AS [updated_at]
      ,ISNULL(UserUpdate.emp_code, '' )					AS updated_by

  FROM [DWH].[mc].[models]
	  LEFT JOIN [DWH].[man].[headquarters]						ON [models].headquarter_id = headquarters.id
  	  LEFT JOIN [DWH].man.employees		AS UserCreate	ON [models].created_by = UserCreate.id
	  LEFT JOIN [DWH].man.employees		AS UserUpdate	ON [models].updated_by = UserUpdate.id
	  LEFT JOIN [DWH].[mc].[makers]						ON [models].maker_id = makers.id
	  LEFT JOIN [DWH].[mc].[item_labels] AS process		ON [models].process_type = process.val and process.name = 'models.process_type'
	  WHERE [models].[id] = @id OR @id IS NULL

END
