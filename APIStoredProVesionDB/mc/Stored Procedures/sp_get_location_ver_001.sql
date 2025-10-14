-- =============================================
-- Author:		<Author,,Nutchanat K.>
-- Create date: <15/09/2025>
-- Description:	<Get get_location List>
-- =============================================
CREATE PROCEDURE [mc].[sp_get_location_ver_001]
@id AS INT = 0

AS
BEGIN
	SET NOCOUNT ON;
	SET @id = CASE WHEN @id = 0 THEN null ELSE @id END
SELECT locations.[id]
      ,[name]
      ,[headquarter_id]
      ,[address]
      --,[x]
      --,[y]
      --,[z]
      --,[depth]
      --,[queue]
      --,[wh_code]
	  ,ISNULL(CONVERT(VARCHAR,[locations].[created_at],120),'') AS [created_at]
      ,ISNULL(UserCreate.emp_code,'')				AS created_by
	  ,ISNULL(CONVERT(VARCHAR,[locations].[updated_at],120), '' ) AS [updated_at]
      ,ISNULL(UserUpdate.emp_code, '' )					AS updated_by
     FROM [DWH].[trans].[locations]
	 LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserCreate ON  UserCreate.id = locations.created_by
	 LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserUpdate ON  UserUpdate.id = locations.updated_by
	 WHERE locations.[id] = @id OR @id IS NULL
END
