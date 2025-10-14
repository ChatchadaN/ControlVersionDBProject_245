-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dds].[sp_set_main_release_list]
	-- Add the parameters for the stored procedure here
	@is_release_rist int = NULL
	, @is_release_rohm int = NULL
	, @is_release_repi int = NULL
	, @database_version_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF NOT EXISTS(select [id] from [APCSProDB].[dds].[database_versions] where [id] = @database_version_id and [is_release_rist] = @is_release_rist)
	BEGIN
		UPDATE [APCSProDB].[dds].[database_versions]
			SET [is_release_rist] = @is_release_rist
		WHERE [id] = @database_version_id
	END

	IF NOT EXISTS(select [id] from [APCSProDB].[dds].[database_versions] where [id] = @database_version_id and [is_release_rohm] = @is_release_rohm)
	BEGIN
		UPDATE [APCSProDB].[dds].[database_versions]
			SET [is_release_rohm] = @is_release_rohm
		WHERE [id] = @database_version_id
	END

	IF NOT EXISTS(select [id] from [APCSProDB].[dds].[database_versions] where [id] = @database_version_id and [is_release_repi] = @is_release_repi)
	BEGIN
		UPDATE [APCSProDB].[dds].[database_versions]
			SET [is_release_repi] = @is_release_repi
		WHERE [id] = @database_version_id
	END
END
