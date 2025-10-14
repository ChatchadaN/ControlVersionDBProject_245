-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_trc_read_item_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT CAST(1 AS BIT) AS [status]
	, CAST([val] AS INT) AS [id]
	, [label_eng] AS [name]
	FROM [APCSProDB].[trans].[item_labels]
	WHERE [name] = 'trc_controls.insp_item'
END
