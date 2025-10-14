-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dds].[sp_get_main_update_list]
	-- Add the parameters for the stored procedure here
	@table_name varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @version int

    -- Insert statements for procedure here
	select @version = MAX([database_versions].[version])
	from [APCSProDB].[dds].[database_tables]
	inner join [APCSProDB].[dds].[database_versions] on [database_versions].[database_table_id] = [database_tables].[id]
	where [database_tables].[name] = @table_name

	select [database_tables].[name] as table_name
		, [database_versions].[version]
		, [database_versions].[description]
		, [database_tables].[id] as table_id
	from [APCSProDB].[dds].[database_tables]
	inner join [APCSProDB].[dds].[database_versions] on [database_versions].[database_table_id] = [database_tables].[id]
	where [database_tables].[name] = @table_name
	and [version] = @version
END
