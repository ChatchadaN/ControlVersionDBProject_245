-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_ocr_get_mark_condition_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [lot_marking_verify_master].[value] as [mark_from]
	, [lot_marking_verify_master].[to_value] as [mark_to]
	FROM [APCSProDB].[trans].[lot_marking_verify_master]
END
