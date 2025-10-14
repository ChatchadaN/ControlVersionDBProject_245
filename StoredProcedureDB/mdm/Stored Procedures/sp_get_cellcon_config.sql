-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_cellcon_config]
	-- Add the parameters for the stored procedure here
		@id int = 0	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET @id = CASE WHEN  @id = 0 THEN NULL ELSE @id  END  

    -- Insert statements for procedure here
	BEGIN
		SELECT [config_functions].[id]
		  ,[app_name]
		  ,[comment]
		  ,[function_name]
		  ,[is_use]
		  ,[config_functions].[factory_code]
		  ,factories.short_name AS factories
		  ,[value]
		  ,[config_functions].[created_at]
		  ,[user2].[emp_num] AS created_by
		  ,[config_functions].[updated_at]
		  ,[user1].[emp_num] AS updated_by
		  ,[is_disabled]
		FROM [APCSProDB].[cellcon].[config_functions]
		INNER JOIN APCSProDB.man.factories 
		ON [config_functions].factory_code = factories.factory_code
		LEFT JOIN [APCSProDB].[man].[users]  AS user1 ON [config_functions].[updated_by] = [user1].[id]
		LEFT JOIN [APCSProDB].[man].[users]  AS user2 ON [config_functions].[created_by] = [user2].[id] 
		WHERE [config_functions].[id] =  @id  OR  @id  IS NULL 
	END
END
