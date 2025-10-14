-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_andon_read_abnormal_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@is_abnormal bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@is_abnormal = 1)
	BEGIN
		SELECT CAST(1 AS BIT) AS [status]
			, [abnormal_detail].[id] AS [id]
			, [abnormal_detail].[name] AS [name]
			, [abnormal_mode].[name] AS [mode]
		FROM [APCSProDB].[trans].[abnormal_detail]
		INNER JOIN [APCSProDB].[trans].[abnormal_mode] ON [abnormal_mode].[id] = [abnormal_detail].[abnormal_mode_id]
		WHERE [abnormal_mode].[mode] = 1
			AND [abnormal_detail].[is_disable] = 0
	END
	ELSE
	BEGIN
		SELECT CAST(1 AS BIT) AS [status]
			, [abnormal_detail].[id] AS [id]
			, [abnormal_detail].[name] AS [name]
			, [abnormal_mode].[name] AS [mode]
		FROM [APCSProDB].[trans].[abnormal_detail]
		INNER JOIN [APCSProDB].[trans].[abnormal_mode] ON [abnormal_mode].[id] = [abnormal_detail].[abnormal_mode_id]
		WHERE [abnormal_mode].[mode] = 0
			AND [abnormal_detail].[is_disable] = 0	
	END
END
