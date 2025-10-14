-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dds].[sp_set_main_table]
	-- Add the parameters for the stored procedure here
	@status int
	, @table_name varchar(50)
	, @version_description nvarchar(100)
	, @seq_no int
	, @column_name_jpn nvarchar(50) = null
	, @column_name_eng varchar(50) = null
	, @data_type varchar(50) = null
	, @is_key int = null
	, @is_null int = null
	, @description nvarchar(500) = null
	, @description_key nvarchar(500) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @database_table_id int
		, @database_version_id int
		, @version int

    -- Insert statements for procedure here
	IF(@status = 0)
	BEGIN
		IF EXISTS(select id from [APCSProDB].[dds].[database_tables] where [name] = @table_name)
		BEGIN
			select @database_table_id = id
			from [APCSProDB].[dds].[database_tables]
			where [name] = @table_name

			select @version = MAX([version]) + 1
			from [APCSProDB].[dds].[database_versions]
			where [database_table_id] = @database_table_id

			insert into [APCSProDB].[dds].[database_versions]
			(	
				[database_table_id]
				, [version]
				, [description]
				, [is_release_rist]
				, [is_release_rohm]
				, [is_release_repi]
			)
			select @database_table_id
				, @version
				, @version_description
				, 0
				, 0
				, 0

			select @database_version_id = [id]
			from [APCSProDB].[dds].[database_versions]
			where [database_table_id] = @database_table_id
			and [version] = @version

			insert into [APCSProDB].[dds].[database_details]
			(
				[database_version_id]
				, [seq_no]
				, [column_name_jpn]
				, [column_name_eng]
				, [data_type]
				, [is_key]
				, [is_null]
				, [description]
				, [description_key]
			)
			select @database_version_id
				, @seq_no
				, @column_name_jpn
				, @column_name_eng
				, @data_type
				, @is_key
				, @is_null
				, @description
				, @description_key
		END
		ELSE
		BEGIN
			insert into [APCSProDB].[dds].[database_tables]
			(
				[name]
				, [is_enable]
			)
			select @table_name
				, 1

			select @database_table_id = id
			from [APCSProDB].[dds].[database_tables]
			where [name] = @table_name

			insert into [APCSProDB].[dds].[database_versions]
			(	
				[database_table_id]
				, [version]
				, [description]
				, [is_release_rist]
				, [is_release_rohm]
				, [is_release_repi]
			)
			select @database_table_id
				, 1
				, @version_description
				, 0
				, 0
				, 0

			select @database_version_id = [id]
			from [APCSProDB].[dds].[database_versions]
			where [database_table_id] = @database_table_id
			and [version] = 1

			insert into [APCSProDB].[dds].[database_details]
			(
				[database_version_id]
				, [seq_no]
				, [column_name_jpn]
				, [column_name_eng]
				, [data_type]
				, [is_key]
				, [is_null]
				, [description]
				, [description_key]
			)
			select @database_version_id
				, @seq_no
				, @column_name_jpn
				, @column_name_eng
				, @data_type
				, @is_key
				, @is_null
				, @description
				, @description_key
		END
	END
	ELSE
	BEGIN
		IF EXISTS(select id from [APCSProDB].[dds].[database_tables] where [name] = @table_name)
		BEGIN
			select @database_table_id = id
			from [APCSProDB].[dds].[database_tables]
			where [name] = @table_name

			select @version = MAX([version])
			from [APCSProDB].[dds].[database_versions]
			where [database_table_id] = @database_table_id

			select @database_version_id = [id]
			from [APCSProDB].[dds].[database_versions]
			where [database_table_id] = @database_table_id
			and [version] = @version

			insert into [APCSProDB].[dds].[database_details]
			(
				[database_version_id]
				, [seq_no]
				, [column_name_jpn]
				, [column_name_eng]
				, [data_type]
				, [is_key]
				, [is_null]
				, [description]
				, [description_key]
			)
			select @database_version_id
				, @seq_no
				, @column_name_jpn
				, @column_name_eng
				, @data_type
				, @is_key
				, @is_null
				, @description
				, @description_key
		END
	END
END
