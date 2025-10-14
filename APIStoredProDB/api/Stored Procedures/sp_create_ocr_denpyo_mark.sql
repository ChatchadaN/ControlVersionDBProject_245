-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_create_ocr_denpyo_mark]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[api].[sp_create_ocr_denpyo_mark_ver_001]
	-- ########## VERSION 001 ##########
END
