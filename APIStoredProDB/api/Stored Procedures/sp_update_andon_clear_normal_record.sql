-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_update_andon_clear_normal_record]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
	,	@andon_control_id int
	,	@is_production bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@is_production = 1)
	BEGIN
		-- ########## VERSION 003 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_update_andon_clear_normal_record_ver_003]
			@username = @username
			,	@lot_no = @lot_no
			,	@andon_control_id = @andon_control_id
		-- ########## VERSION 003 ##########
		
		---- ########## VERSION 001 ##########
		--EXEC [APIStoredProVersionDB].[api].[sp_update_andon_clear_normal_record_ver_001]
		--@username = @username
		--,	@lot_no = @lot_no
		--,	@andon_control_id = @andon_control_id
		---- ########## VERSION 001 ##########
	END
	ELSE
	BEGIN
		-- ########## VERSION 003 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_update_andon_clear_normal_record_ver_003]
			@username = @username
			,	@lot_no = @lot_no
			,	@andon_control_id = @andon_control_id
		-- ########## VERSION 003 ##########
	
		---- ########## VERSION DEV ##########
		--EXEC [APIStoredProVersionDB].[api].[sp_update_andon_clear_normal_record_ver_001]
		--@username = @username
		--,	@lot_no = @lot_no
		--,	@andon_control_id = @andon_control_id
		---- ########## VERSION DEV ##########
	END
END
