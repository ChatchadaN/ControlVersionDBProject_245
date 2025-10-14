

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_roles]
	-- Add the parameters for the stored procedure here
	@rolID int = NULL	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
SELECT [id]
      ,[name]
      ,[descriptions]
      ,[validity_period]
      ,[created_at]
      ,[created_by]
      ,[updated_at]
      ,[updated_by]
  FROM [APCSProDB].[man].[roles]
  where ([id] = @rolID OR ISNULL(@rolID,'') = '')
	END
END
