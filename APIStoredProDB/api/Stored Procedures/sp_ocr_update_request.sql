-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_ocr_update_request]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@request_id int
	,	@lot_no varchar(10)
	,	@mark varchar(MAX)
	,	@image varchar(MAX)
	,	@is_pass int
	,	@recheck_count int = 0
	,	@is_logo_pass int = 0
	,	@request_status int = 2
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
		EXEC [APIStoredProVersionDB].[api].[sp_ocr_update_request_ver_001]
		@username = @username
		,	@request_id = @request_id
		,	@lot_no = @lot_no
		,	@mark = @mark
		,	@image = @image
		,	@is_pass = @is_pass
		,	@recheck_count = @recheck_count
		,	@is_logo_pass = @is_logo_pass
		-- ########## VERSION 001 ##########
		*/

		/*
		-- ########## VERSION 002 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_ocr_update_request_ver_002]
		@username = @username
		,	@request_id = @request_id
		,	@lot_no = @lot_no
		,	@mark = @mark
		,	@image = @image
		,	@is_pass = @is_pass
		,	@recheck_count = @recheck_count
		,	@is_logo_pass = @is_logo_pass
		-- ########## VERSION 002 ##########
		*/

		-- ########## VERSION 003 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_ocr_update_request_ver_003]
		@username = '000000'
		,	@request_id = @request_id
		,	@lot_no = @lot_no
		,	@mark = @mark
		,	@image = @image
		,	@is_pass = @is_pass
		,	@recheck_count = @recheck_count
		,	@is_logo_pass = @is_logo_pass
		,	@request_status = @request_status
		-- ########## VERSION 003 ##########
	END
	ELSE
	BEGIN
		-- ########## VERSION DEV ##########
		EXEC [APIStoredProVersionDB].[api].[sp_ocr_update_request_ver_003]
		@username = '000000'
		,	@request_id = @request_id
		,	@lot_no = @lot_no
		,	@mark = @mark
		,	@image = @image
		,	@is_pass = @is_pass
		,	@recheck_count = @recheck_count
		,	@is_logo_pass = @is_logo_pass
		,	@request_status = @request_status
		-- ########## VERSION DEV ##########
	END
END
