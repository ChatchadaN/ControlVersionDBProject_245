-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_trc_read_record_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@search varchar(10)
	,	@is_held INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT *
	FROM
	(
		SELECT CAST(1 AS BIT) AS [status]
		, [trc_controls].[id]
		, [lots].[lot_no]
		, [is_held]
		, CASE WHEN [insp_type] = 1 THEN 'Piece' ELSE 'Frame' END AS [insp_type]
		, CASE WHEN [abnormal1].[name] IS NULL THEN '-' ELSE [abnormal1].[name] END AS [abnormal1]
		, CASE WHEN [abnormal2].[name] IS NULL THEN '-' ELSE [abnormal2].[name] END AS [abnormal2]
		, CASE WHEN [abnormal3].[name] IS NULL THEN '-' ELSE [abnormal3].[name] END AS [abnormal3]
		, CASE WHEN [insp_item] = 1 THEN 'Inspection 100%' WHEN [insp_item] = 2 THEN 'Sampling' WHEN [insp_item] = 3 THEN 'Evaluation' WHEN [insp_item] = 4 THEN 'Evaluation' ELSE 'Abnomal' END AS [insp_item]
		, [ng_random]
		, [qty_insp]
		, [comment]
		, CASE WHEN [machines].[name] IS NULL THEN '-' ELSE [machines].[name] END AS machine_name
		, CASE WHEN [processes].[name] IS NULL THEN '-' ELSE [processes].[name] END AS process_name
		, CASE WHEN [trc_controls].[aqi_no] IS NULL THEN '-' ELSE [trc_controls].[aqi_no] END [aqi_no]
		FROM [APCSProDB].[trans].[trc_controls]
		INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [trc_controls].[lot_id]
		LEFT JOIN [APCSProDB].[trans].[abnormal_detail] AS [abnormal1] ON [abnormal1].[id] = [trc_controls].[abnormal_mode_id1]
		LEFT JOIN [APCSProDB].[trans].[abnormal_detail] AS [abnormal2] ON [abnormal2].[id] = [trc_controls].[abnormal_mode_id2]
		LEFT JOIN [APCSProDB].[trans].[abnormal_detail] AS [abnormal3] ON [abnormal3].[id] = [trc_controls].[abnormal_mode_id3]
		LEFT JOIN [APCSProDB].[mc].[machines] ON [machines].[id] = [trc_controls].[machine_id]
		LEFT JOIN [APCSProDB].[method].[processes] ON [processes].[id] = [trc_controls].[process_id]
		WHERE [trc_controls].[is_held] = @is_held
	) AS [master_data]
	WHERE [master_data].[lot_no] LIKE CONCAT('%', @search, '%')
	OR [master_data].[insp_type] LIKE CONCAT('%', @search, '%')
	OR [master_data].[abnormal1] LIKE CONCAT('%', @search, '%')
	OR [master_data].[abnormal2] LIKE CONCAT('%', @search, '%')
	OR [master_data].[abnormal3] LIKE CONCAT('%', @search, '%')
	OR [master_data].[insp_item] LIKE CONCAT('%', @search, '%')
	OR [master_data].[comment] LIKE CONCAT('%', @search, '%')
	OR [master_data].[machine_name] LIKE CONCAT('%', @search, '%')
	OR [master_data].[process_name] LIKE CONCAT('%', @search, '%')
	OR [master_data].[aqi_no] LIKE CONCAT('%', @search, '%')
	ORDER BY [master_data].[id] DESC
END
