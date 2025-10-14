-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_andon_get_record]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@process_id int = 0
	,	@status_id int = 0
	,	@lot_no varchar(max) = '%'
	,	@package varchar(max) = '%'
	,	@device varchar(max) = '%'
	,	@machine_name varchar(max) = '%'
	,	@start_time varchar(max) = ''
	,	@end_time varchar(max) = ''
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
		EXEC [APIStoredProVersionDB].[api].[sp_read_andon_get_record_ver_001]
		@username = @username
		-- ########## VERSION 001 ##########

		/*
		-- ########## VERSION 002 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_andon_get_record_ver_002]
		@username = @username
		,	@process_id = @process_id
		,	@status_id = @status_id
		,	@start_time = @start_time
		,	@end_time = @end_time
		-- ########## VERSION 002 ##########
		*/

		/*
		-- ########## VERSION 003 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_andon_get_record_ver_003]
		@username = @username
		,	@process_id = @process_id
		,	@status_id = @status_id
		,	@lot_no = @lot_no
		,	@package = @package
		,	@device = @device
		,	@machine_name = @machine_name
		,	@start_time = @start_time
		,	@end_time = @end_time
		-- ########## VERSION 003 ##########
		*/
	END
	ELSE
	BEGIN
		-- ########## VERSION DEV ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_andon_get_record_ver_003]
		@username = @username
		,	@process_id = @process_id
		,	@status_id = @status_id
		,	@lot_no = @lot_no
		,	@package = @package
		,	@device = @device
		,	@machine_name = @machine_name
		,	@start_time = @start_time
		,	@end_time = @end_time
		-- ########## VERSION DEV ##########
	END
END
