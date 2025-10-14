-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_ocr_read_compare]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
	,	@mark varchar(MAX)
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
		EXEC [APIStoredProVersionDB].[api].[sp_ocr_read_compare_ver_001]
		@username = @username
		,	@lot_no = @lot_no
		,	@mark = @mark
		-- ########## VERSION 001 ##########
	END
	ELSE
	BEGIN
		-- ########## VERSION DEV ##########
		EXEC [APIStoredProVersionDB].[api].[sp_ocr_read_compare_ver_001]
		@username = @username
		,	@lot_no = @lot_no
		,	@mark = @mark
		-- ########## VERSION DEV ##########
	END
END
