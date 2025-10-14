-- =============================================
-- Author:		<Author,,Nutchanat K.>
-- Create date: <Create Date,,14/08/2025>
-- Description:	<Description,,Get mc_group_models List>
-- =============================================
CREATE PROCEDURE [mc].[sp_get_mc_group_models_ver_001]
@machine_group_id AS INT = NULL

AS
BEGIN
	SET NOCOUNT ON;
	 
	SELECT [machine_group_id]
	     ,[machine_model_id]
	     ,ISNULL(CONVERT(VARCHAR,group_models.[created_at],120), '')  AS  [created_at]
	     ,ISNULL([employees].emp_code,'') AS [created_by]
	     ,ISNULL(CONVERT(VARCHAR,group_models.[updated_at],120), '')  AS [updated_at]
	     ,ISNULL(up.emp_code,'') AS [updated_by]
	 FROM [DWH].[mc].[group_models]
	 LEFT JOIN [10.29.1.230].[DWH].[man].[employees] ON  [employees].id = group_models.created_by
	 LEFT JOIN [10.29.1.230].[DWH].[man].[employees]  up ON  up.id = group_models.updated_by
	 where ([machine_group_id] = @machine_group_id OR ISNULL(@machine_group_id,'') = '')
END
