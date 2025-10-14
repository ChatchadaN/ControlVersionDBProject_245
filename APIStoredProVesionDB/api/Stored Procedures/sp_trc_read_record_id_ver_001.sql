-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_trc_read_record_id_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	, @trc_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [trc_controls].[id]
	FROM [APCSProDB].[trans].[trc_controls]
	INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [trc_controls].[lot_id]
	WHERE [trc_controls].[id] = @trc_id)
	BEGIN
		SELECT CAST(1 AS BIT) AS [status]
		, [trc_controls].[id]
		, [lots].[lot_no]
		, [is_held]
		, [insp_type]
		, [abnormal_mode_id1]
		, [abnormal_mode_id2]
		, [abnormal_mode_id3]
		, [insp_item]
		, [ng_random]
		, [qty_insp]
		, [comment]
		, [trc_controls].[machine_id]
		, [trc_controls].[process_id]
		, [trc_controls].[aqi_no]
		FROM [APCSProDB].[trans].[trc_controls]
		INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [trc_controls].[lot_id]
		WHERE [trc_controls].[id] = @trc_id
	END
	ELSE
	BEGIN
		SELECT CAST(0 AS BIT) AS [status]
		, 0 AS [id]
		, '' AS [lot_no]
		, 0 AS[is_held]
		, 0 AS [insp_type]
		, 0 AS [abnormal_mode_id1]
		, 0 AS [abnormal_mode_id2]
		, 0 AS [abnormal_mode_id3]
		, 0 AS [insp_item]
		, 0 AS [ng_random]
		, 0 AS [qty_insp]
		, '' AS [comment]
		, 0 AS [machine_id]
		, 0 AS [process_id]
		, '' AS [aqi_no]
	END
END
