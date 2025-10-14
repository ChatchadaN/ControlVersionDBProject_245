-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_andon_get_abnormal_mode]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@is_abnormal bit
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
		EXEC [APIStoredProVersionDB].[api].[sp_read_andon_get_abnormal_mode_ver_001]
		@username = @username
		,	@is_abnormal = @is_abnormal
		-- ########## VERSION 001 ##########
		*/

		-- ########## VERSION 002 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_andon_get_abnormal_mode_ver_002]
		@username = @username
		,	@is_abnormal = @is_abnormal
		-- ########## VERSION 002 ##########
	END
	ELSE
	BEGIN
		-- ########## VERSION DEV ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_andon_get_abnormal_mode_ver_002]
		@username = @username
		,	@is_abnormal = @is_abnormal
		-- ########## VERSION DEV ##########
	END
END
