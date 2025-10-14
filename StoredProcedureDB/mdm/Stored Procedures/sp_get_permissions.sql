

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_permissions]
	-- Add the parameters for the stored procedure here
	@perID int = NULL	
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
			  ,[created_at]
			  ,[created_by]
			  ,[updated_at]
			  ,[updated_by]
		 FROM [APCSProDB].[man].[permissions]
		 WHERE ([id] = @perID OR ISNULL(@perID,'') = '')
	END
END
