-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_create_andon_add_record]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
	,	@process_id int
	,	@machine_id int
	,	@comment_id int
	,	@line_no varchar(max)
	,	@equipment_no varchar(max)
	,	@is_production bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@is_production = 1)
	BEGIN
		---- ########## VERSION 001 ##########
		--EXEC [APIStoredProVersionDB].[api].[sp_create_andon_add_record_ver_001]
		--@username = @username
		--,	@lot_no = @lot_no
		--,	@process_id = @process_id
		--,	@machine_id = @machine_id
		--,	@comment_id = @comment_id
		--,	@line_no = @line_no
		--,	@equipment_no = @equipment_no
		---- ########## VERSION 001 ##########

		/*
		-- ########## VERSION 002 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_create_andon_add_record_ver_002]
		@username = @username
		,	@lot_no = @lot_no
		,	@process_id = @process_id
		,	@machine_id = @machine_id
		,	@comment_id = @comment_id
		,	@line_no = @line_no
		,	@equipment_no = @equipment_no
		-- ########## VERSION 002 ##########
		*/

		-- ########## VERSION 003 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_create_andon_add_record_ver_003]
		@username = @username
		,	@lot_no = @lot_no
		,	@process_id = @process_id
		,	@machine_id = @machine_id
		,	@comment_id = @comment_id
		,	@line_no = @line_no
		,	@equipment_no = @equipment_no
		-- ########## VERSION 003 ##########
	END
	ELSE
	BEGIN
		---- ########## VERSION DEV ##########
		--EXEC [APIStoredProVersionDB].[api].[sp_create_andon_add_record_ver_002]
		--@username = @username
		--,	@lot_no = @lot_no
		--,	@process_id = @process_id
		--,	@machine_id = @machine_id
		--,	@comment_id = @comment_id
		--,	@line_no = @line_no
		--,	@equipment_no = @equipment_no
		---- ########## VERSION DEV ##########

		-- ########## VERSION 003 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_create_andon_add_record_ver_003]
		@username = @username
		,	@lot_no = @lot_no
		,	@process_id = @process_id
		,	@machine_id = @machine_id
		,	@comment_id = @comment_id
		,	@line_no = @line_no
		,	@equipment_no = @equipment_no
		-- ########## VERSION 003 ##########
	END
END
