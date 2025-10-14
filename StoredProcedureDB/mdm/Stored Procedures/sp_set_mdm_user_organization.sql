-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_mdm_user_organization]
	-- Add the parameters for the stored procedure here
	@Update_by as int,
	@OrgID as int,
	@user_ID as int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRY
		IF NOT EXISTS(SELECT user_id FROM [APCSProDB].[man].[user_organizations] WHERE user_id = @user_ID)
		BEGIN
			INSERT INTO  [APCSProDB].[man].[user_organizations]
			(
				[user_id],
				[organization_id],
				[created_by],
				[created_at]
			)
			VALUES
			(
				@user_ID,
				@OrgID,
				@Update_by,
				GETDATE()
			)

			INSERT INTO [APCSProDB].[man_hist].user_organizations_hist
			(
			  [category]
			  ,[user_id]
			  ,[organization_id]
			  ,[created_at]
			  ,[created_by]
			  ,[updated_at]
			  ,[updated_by]
			)
			SELECT
				1
				,[user_id]
				,[organization_id]
				,[created_at]
				,[created_by]
				,[updated_at]
				,[updated_by]
			FROM [APCSProDB].[man].[user_organizations]
			WHERE user_id = @user_ID
		END
		ELSE IF EXISTS(SELECT user_id FROM [APCSProDB].[man].[user_organizations] WHERE user_id = @user_ID)
		BEGIN
			UPDATE [APCSProDB].[man].[user_organizations]
			SET
			organization_id = @OrgID,
			updated_by = @Update_by,
			updated_at = GETDATE()
			WHERE user_id = @user_ID

			INSERT INTO [APCSProDB].[man_hist].user_organizations_hist
			(
			   [category]
			  ,[user_id]
			  ,[organization_id]
			  ,[created_at]
			  ,[created_by]
			  ,[updated_at]
			  ,[updated_by]
			)
			SELECT
				2
				,[user_id]
				,[organization_id]
				,[created_at]
				,[created_by]
				,[updated_at]
				,[updated_by]
			FROM [APCSProDB].[man].[user_organizations]
			WHERE user_id = @user_ID

		END
	END TRY
	BEGIN CATCH
		SELECT 'FALSE' AS Is_Pass, ERROR_MESSAGE()
	END CATCH

END


