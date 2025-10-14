-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dds].[sp_get_main_table_list]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select [database_tables].[id]
		, [database_tables].[name] as table_name
		, COUNT(case when [database_versions].[is_release_rist] in(1,3,8,9) then NULL else 1 end) as total_rist
		, COUNT(case when [database_versions].[is_release_rohm] in(1,3,8,9) then NULL else 1 end) as total_rohm
		, COUNT(case when [database_versions].[is_release_repi] in(1,3,8,9) then NULL else 1 end) as total_repi
		, [item_labels].[label_eng]
	from [APCSProDB].[dds].[database_tables]
	inner join [APCSProDB].[dds].[database_versions] on [database_tables].[id] = [database_versions].[database_table_id]
	left join [APCSProDB].[dds].[item_labels] on [item_labels].[val] = [database_tables].[is_enable] and [item_labels].[name] = 'database_tables.is_enable'
	group by [database_tables].[id], [database_tables].[name], [item_labels].[label_eng]
END
