-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_trc_create_record]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
	,	@is_held int
	,	@insp_type int
	,	@abnormal_mode_id1 int
	,	@abnormal_mode_id2 int
	,	@abnormal_mode_id3 int
	,	@insp_item int
	,	@ng_random int
	,	@qty_insp int
	,	@comment varchar(MAX)
	,	@image varchar(MAX)
	,	@machine_id int
	,	@process_id int = null
	,	@aqi_no varchar(MAX) = null
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
		EXEC [APIStoredProVersionDB].[api].[sp_trc_create_record_ver_001]
		@username = @username
		,	@lot_no = @lot_no
		,	@is_held = @is_held
		,	@insp_type = @insp_type
		,	@abnormal_mode_id1 = @abnormal_mode_id1
		,	@abnormal_mode_id2 = @abnormal_mode_id2
		,	@abnormal_mode_id3 = @abnormal_mode_id3
		,	@insp_item = @insp_item
		,	@ng_random = @ng_random
		,	@qty_insp = @qty_insp
		,	@comment = @comment
		,	@image = @image
		,	@machine_id = @machine_id
		,	@process_id = @process_id
		,	@aqi_no = @aqi_no
		-- ########## VERSION 001 ##########
	END
	ELSE
	BEGIN
		-- ########## VERSION DEV ##########
		EXEC [APIStoredProVersionDB].[api].[sp_trc_create_record_ver_001]
		@username = @username
		,	@lot_no = @lot_no
		,	@is_held = @is_held
		,	@insp_type = @insp_type
		,	@abnormal_mode_id1 = @abnormal_mode_id1
		,	@abnormal_mode_id2 = @abnormal_mode_id2
		,	@abnormal_mode_id3 = @abnormal_mode_id3
		,	@insp_item = @insp_item
		,	@ng_random = @ng_random
		,	@qty_insp = @qty_insp
		,	@comment = @comment
		,	@image = @image
		,	@machine_id = @machine_id
		,	@process_id = @process_id
		,	@aqi_no = @aqi_no
		-- ########## VERSION DEV ##########
	END
END
