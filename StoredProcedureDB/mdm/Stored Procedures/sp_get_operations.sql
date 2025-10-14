
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_operations]
	-- Add the parameters for the stored procedure here
	@opID int = NULL	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
	SELECT  [id]
      ,[name]
      ,[descriptions]
      ,[app_name]
      ,[function_name]
      ,[parameter_1]
      ,[to_create]
      ,[to_read]
      ,[to_update]
      ,[to_delete]
      ,[created_at]
      ,[created_by]
      ,[updated_at]
      ,[updated_by]
  FROM [APCSProDB].[man].[operations]
  where ([id] = @opID OR ISNULL(@opID,'') = '')
	END
END
