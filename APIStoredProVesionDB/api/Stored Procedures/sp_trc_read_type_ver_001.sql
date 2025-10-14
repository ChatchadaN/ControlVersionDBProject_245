-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_trc_read_type_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT CAST(1 AS BIT) AS [status]
	, 1 AS [id]
	, 'Piece' AS [name]
	UNION ALL
	SELECT CAST(1 AS BIT) AS [status]
	, 2 AS [id]
	, 'Frame' AS [name]
END
