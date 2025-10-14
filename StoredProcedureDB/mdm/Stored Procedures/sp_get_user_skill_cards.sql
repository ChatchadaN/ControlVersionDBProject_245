

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_user_skill_cards]
	-- Add the parameters for the stored procedure here
	@userID int = NULL	

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		SELECT [id]
      ,[user_id]
      ,[emp_code]
      ,[comment]
      ,[expired_on]
      ,[created_at]
      ,[created_by]
      ,[updated_at]
      ,[updated_by]
  FROM [APCSProDB].[man].[user_skill_cards]
   where ([user_id] = @userID OR ISNULL(@userID,'') = '')
	END
END
