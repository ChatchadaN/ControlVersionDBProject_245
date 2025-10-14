-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_andon_get_abnormal_mode_ver_001]
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
		, CONVERT(INT, [val]) AS [id]
		, [label_eng] AS [name]
		, [label_sub] AS [mode]
		FROM [APCSProDB].[trans].[item_labels]
		WHERE [name] = 'andon_controls.comment_id_at_finding'
		AND CONVERT(INT, [val]) > 100
		ORDER BY CONVERT(INT, [val])
	END
	ELSE
	BEGIN
		SELECT CAST(1 AS BIT) AS [status]
		, CONVERT(INT, [val]) AS [id]
		, [label_eng] AS [name]
		, [label_sub] AS [mode]
		FROM [APCSProDB].[trans].[item_labels]
		WHERE [name] = 'andon_controls.comment_id_at_finding'
		AND CONVERT(INT, [val]) <= 100
		ORDER BY CONVERT(INT, [val])
	END
END
