-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_andon_get_record_by_process] 
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@list_process_id varchar(max)
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
		EXEC [APIStoredProVersionDB].[api].[sp_read_andon_get_record_by_process_ver_001]
		@username = @username
		,	@process_id = @process_id
		-- ########## VERSION 001 ##########
		*/

		-- ########## VERSION 002 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_andon_get_record_by_process_ver_002]
		@username = @username
		,	@list_process_id = @list_process_id
		-- ########## VERSION 002 ##########
	END
	ELSE
	BEGIN
		-- ########## VERSION DEV ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_andon_get_record_by_process_ver_002]
		@username = @username
		,	@list_process_id = @list_process_id
		-- ########## VERSION DEV ##########
	END
END
