-- =============================================
-- Author:		<Author,,Nutchanat K.>
-- Create date: <Create Date,,08/08/2025>
-- Description:	<Description,,Get mc_groups List>
-- =============================================
CREATE PROCEDURE [mc].[sp_get_mc_maker_ver_001]
@id AS INT = 0

AS
BEGIN
	SET NOCOUNT ON;
	SET @id = CASE WHEN @id = 0 THEN null ELSE @id END
SELECT makers.[id]
      ,[name]
	  ,ISNULL(CONVERT(VARCHAR,[makers].[created_at],120),'') AS [created_at]
      ,ISNULL(UserCreate.emp_code,'')				AS created_by
	  ,ISNULL(CONVERT(VARCHAR,[makers].[updated_at],120), '' ) AS [updated_at]
      ,ISNULL(UserUpdate.emp_code, '' )					AS updated_by
     FROM [DWH].[mc].[makers]
	 LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserCreate ON  UserCreate.id = makers.created_by
	 LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserUpdate ON  UserUpdate.id = makers.updated_by
	 WHERE makers.[id] = @id OR @id IS NULL
END
