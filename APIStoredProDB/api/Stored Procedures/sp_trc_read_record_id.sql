-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_trc_read_record_id]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@trc_id INT = 1
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
		EXEC [APIStoredProVersionDB].[api].[sp_trc_read_record_id_ver_001]
		@username = @username
		,	@trc_id = @trc_id
		-- ########## VERSION 001 ##########
	END
	ELSE
	BEGIN
		-- ########## VERSION DEV ##########
		EXEC [APIStoredProVersionDB].[api].[sp_trc_read_record_id_ver_001]
		@username = @username
		,	@trc_id = @trc_id
		-- ########## VERSION DEV ##########
	END
END
