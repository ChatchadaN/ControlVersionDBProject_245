-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_create_ocr_add_record]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
	,	@mark varchar(MAX)
	,	@image varchar(MAX)
	,	@is_pass int
	,	@recheck_count int = 0
	,	@is_logo_pass int = 0
	,	@is_production bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@is_production = 1)
	BEGIN
		/*
		-- ########## VERSION 001 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_create_ocr_add_record_ver_001]
		@username = @username
		,	@lot_no = @lot_no
		,	@mark = @mark
		,	@image = @image
		,	@is_pass = @is_pass
		-- ########## VERSION 001 ##########
		*/

		/*
		-- ########## VERSION 002 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_create_ocr_add_record_ver_002]
		@username = @username
		,	@lot_no = @lot_no
		,	@mark = @mark
		,	@image = @image
		,	@is_pass = @is_pass
		,	@recheck_count = @recheck_count
		-- ########## VERSION 002 ##########
		*/

		/*
		-- ########## VERSION 003 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_create_ocr_add_record_ver_003]
		@username = @username
		,	@lot_no = @lot_no
		,	@mark = @mark
		,	@image = @image
		,	@is_pass = @is_pass
		,	@recheck_count = @recheck_count
		-- ########## VERSION 003 ##########
		*/

		-- ########## VERSION 004 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_create_ocr_add_record_ver_004]
		@username = @username
		,	@lot_no = @lot_no
		,	@mark = @mark
		,	@image = @image
		,	@is_pass = @is_pass
		,	@recheck_count = @recheck_count
		,	@is_logo_pass = @is_logo_pass
		-- ########## VERSION 004 ##########
	END
	ELSE
	BEGIN
		-- ########## VERSION DEV ##########
		EXEC [APIStoredProVersionDB].[api].[sp_create_ocr_add_record_ver_004]
		@username = @username
		,	@lot_no = @lot_no
		,	@mark = @mark
		,	@image = @image
		,	@is_pass = @is_pass
		,	@recheck_count = @recheck_count
		,	@is_logo_pass = @is_logo_pass
		-- ########## VERSION DEV ##########
	END
END
