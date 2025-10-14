-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_ocr_get_mark_info]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
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
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_001]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 001 ##########
		*/

		/*
		-- ########## VERSION 002 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_002]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 002 ##########
		*/

		/*
		-- ########## VERSION 003 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_003]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 003 ##########
		*/

		/*
		-- ########## VERSION 004 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_004]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 004 ##########
		*/

		/*
		-- ########## VERSION 005 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_005]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 005 ##########
		*/

		/*
		-- ########## VERSION 006 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_006]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 006 ##########
		*/

		/*
		-- ########## VERSION 007 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_007]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 007 ##########
		*/

		/*
		-- ########## VERSION 008 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_008]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 008 ##########
		*/

		/*
		-- ########## VERSION 009 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_009]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 009 ##########
		*/

		/*
		-- ########## VERSION 010 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_010]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 010 ##########
		*/

		/*
		-- ########## VERSION 011 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_011]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 011 ##########
		*/

		/*
		-- ########## VERSION 012 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_012]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 012 ##########
		*/

		/*
		-- ########## VERSION 013 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_013]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 013 ##########
		*/

		/*
		-- ########## VERSION 014 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_014]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 014 ##########
		*/

		/*
		-- ########## VERSION 015 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_015]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 015 ##########
		*/

		/*
		-- ########## VERSION 016 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_016]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 016 ##########
		*/

		/*
		-- ########## VERSION 017 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_017]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 017 ##########
		*/

		/*
		-- ########## VERSION 018 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_018]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 018 ##########
		*/

		-- ########## VERSION 019 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_019]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION 019 ##########
	END
	ELSE
	BEGIN
		-- ########## VERSION DEV ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_ocr_get_mark_info_ver_019]
		@username = @username
		, @lot_no = @lot_no
		-- ########## VERSION DEV ##########
	END
END
