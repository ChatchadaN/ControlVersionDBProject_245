-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_ocr_get_lot_by_lot_no_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [id]
	FROM [APCSProDB].[trans].[lots]
	WHERE [lots].[lot_no] = @lot_no)
	BEGIN
		SELECT CAST(1 AS BIT) as [status]
	END
	ELSE
	BEGIN
		SELECT CAST(0 AS BIT) as [status]
	END
END
