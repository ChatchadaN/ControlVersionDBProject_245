-- =============================================
-- Author:		<Author,,Nutchanat K.>
-- Create date: <15/09/2025>
-- Description:	<Get get_location List>
-- =============================================
CREATE PROCEDURE [mc].[sp_get_machine_level_ver_001]
@val AS VARCHAR(15) = NULL

AS
BEGIN
    SET NOCOUNT ON;

    SELECT [name]
          ,[val]
          ,[label_eng]
          ,[label_jpn]
          ,[label_sub]
          ,[color_code]
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[created_at],120),'') AS [created_at]
          ,ISNULL(UserCreate.emp_code,'') AS created_by
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[updated_at],120), '') AS [updated_at]
          ,ISNULL(UserUpdate.emp_code, '') AS updated_by
    FROM [DWH].[mc].[item_labels]
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserCreate 
        ON UserCreate.id = item_labels.created_by
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserUpdate 
        ON UserUpdate.id = item_labels.updated_by
    WHERE [name] = 'machine.machine_level'
      AND (@val IS NULL OR item_labels.[val] = @val)
END
