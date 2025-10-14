-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_get_lot_extend_info]
	@template_id INT = 0,
	-- @process VARCHAR(20) = NULL,
	@flow NVARCHAR(30) = NULL,
	@mc_no NVARCHAR(30) = NULL,
	@lot_no NVARCHAR(20) = NULL,
	-- @package_group VARCHAR(10) = NULL
	@package CHAR(20) = NULL,
	@device CHAR(20) = NULL,
	-- @status VARCHAR(10) = NULL
	@opno_setup VARCHAR(8) = NULL,
	@lot_start_time DATETIME = NULL,
	@lot_end_time DATETIME = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    EXEC [APIStoredProVersionDB].[lds].[sp_get_lot_extend_info_ver_002]
			@template_id = @template_id,
			-- @process = @process,
			@flow = @flow,
			@mc_no = @mc_no,
			@lot_no = @lot_no,
			@package = @package,
			@device = @device,
			@opno_setup = @opno_setup,
			@lot_start_time = @lot_start_time,
			@lot_end_time = @lot_end_time;


END
