-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_user_role]
	-- Add the parameters for the stored procedure here
	@userID int = 0	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		SELECT [user_id] 
		,[role_id] 
		,[name] AS role_name
		,[user_roles].[expired_on]
		,[user_roles].[created_at]
		,[user_roles].[created_by]
		,[user_roles].[updated_at]
		,[user_roles].[updated_by]
		FROM [APCSProDB].[man].[user_roles] 
		INNER JOIN [APCSProDB].[man].[roles] ON [user_roles].[role_id] = [roles].[id]
		where user_id = @userID
	END
END
