-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dds].[sp_get_main_detail_list]
	-- Add the parameters for the stored procedure here
	@database_version_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select [seq_no]
		, [column_name_jpn]
		, [column_name_eng]
		, [data_type]
		, [is_key]
		, [is_null]
		, [description]
		, [description_key]
	from [APCSProDB].[dds].[database_details]
	where [database_version_id] = @database_version_id
	order by [seq_no]
END
