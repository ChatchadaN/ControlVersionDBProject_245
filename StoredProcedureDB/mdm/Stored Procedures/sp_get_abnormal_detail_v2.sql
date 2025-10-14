-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_abnormal_detail_v2]
	-- Add the parameters for the stored procedure here
	 @abmode				VARCHAR(MAX)	= NULL
	, @isdisable			VARCHAR(MAX)	= 0
	, @abname				VARCHAR(MAX)	= NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		SELECT [abnormal_detail].[id]
		, [abnormal_detail].[name]
		, [abnormal_detail].[is_disable]
		, [abnormal_mode].[name]				AS name_mode
		, [abnormal_mode].[id]					AS id_mode
		, [abnormal_detail].[created_at]
		, [abnormal_detail].[updated_at]
		, [user1].[emp_num]						AS updated_by
		, [user2].[emp_num]						AS created_by
		FROM [APCSProDB].[trans].[abnormal_detail] 
		LEFT JOIN [APCSProDB].[trans].[abnormal_mode] ON [abnormal_detail].[abnormal_mode_id] = [abnormal_mode].[id]
		LEFT JOIN [APCSProDB].[man].[users]  AS user1 ON [abnormal_detail].[updated_by] = [user1].[id]
		LEFT JOIN [APCSProDB].[man].[users]  AS user2 ON [abnormal_detail].[created_by] = [user2].[id] 
		WHERE (abnormal_mode.name = @abmode OR ISNULL(@abmode,'') = '')
		AND ([abnormal_detail].[is_disable] = @isdisable OR ISNULL(@isdisable,'') = '')
		AND (abnormal_detail.name = @abname OR ISNULL(@abname,'') = '')
	END
END
