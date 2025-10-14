-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dds].[sp_get_main_version_list]
	-- Add the parameters for the stored procedure here
	@database_table_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select [id]
		, [version]
		, [description]
		, [release_rist].[label_eng] as [release_rist]
		, [release_rohm].[label_eng] as [release_rohm]
		, [release_repi].[label_eng] as [release_repi]
		, [is_release_rist]
		, [is_release_rohm]
		, [is_release_repi]
	from [APCSProDB].[dds].[database_versions]
	left join [APCSProDB].[dds].[item_labels] as [release_rist] on [release_rist].[val] = [database_versions].[is_release_rist] and [release_rist].[name] = 'database_versions.is_release_rist'
	left join [APCSProDB].[dds].[item_labels] as [release_rohm] on [release_rohm].[val] = [database_versions].[is_release_rohm] and [release_rohm].[name] = 'database_versions.is_release_rohm'
	left join [APCSProDB].[dds].[item_labels] as [release_repi] on [release_repi].[val] = [database_versions].[is_release_repi] and [release_repi].[name] = 'database_versions.is_release_repi'
	where [database_table_id] = @database_table_id
	order by [version] desc
END
