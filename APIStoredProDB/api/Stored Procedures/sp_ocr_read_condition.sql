-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_ocr_read_condition]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@is_production bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@is_production = 1)
	BEGIN
		-- ########## VERSION 001 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_ocr_read_condition_ver_001]
		@username = @username
		-- ########## VERSION 001 ##########
	END
	ELSE
	BEGIN
		-- ########## VERSION DEV ##########
		EXEC [APIStoredProVersionDB].[api].[sp_ocr_read_condition_ver_001]
		@username = @username
		-- ########## VERSION DEV ##########
	END
END
