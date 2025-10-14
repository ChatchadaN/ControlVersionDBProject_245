-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create Date,,20223101>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_listlot_stop] 
	-- Add the parameters for the stored procedure here
	--old
	--@lot_no varchar(10) = '%'
	--, @package_group varchar(50) = '%'
	--, @package varchar(50) = '%'
	--, @device varchar(50) = '%'
	--, @lot_type varchar(1) = '%'
	--, @process varchar(50) = '%'
	--, @job varchar(50) = '%'
	--, @status varchar(50) = '%'
	--, @process_state varchar(50) = '%'
	--, @quality_state varchar(50) = '%'
	--, @wip_state varchar(50) = '%'
	--, @fab_wafer varchar(50) = '%'
	--, @assy_name varchar(50) = '%'
	--new
	@lot_no varchar(10) = '%'
	, @device varchar(50) = '%'
	, @assy_name varchar(50) = '%'
	, @package varchar(50) = '%'
	, @fab_wafer varchar(50) = '%'
	, @status int  -- 0:list stoplot, 1:release stoplot, 2:cancel stoplot
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	------ ########## VERSION 003 ##########
	--EXEC [StoredProcedureDB].[atom].[sp_get_listlot_stop_ver_003]
	--	@lot_no = @lot_no
	--	, @device = @device
	--	, @assy_name = @assy_name
	--	, @package = @package
	--	, @fab_wafer = @fab_wafer
	--	, @status = @status;
	------ ########## VERSION 003 ##########

	---- ########## VERSION 004 ##########
	EXEC [StoredProcedureDB].[atom].[sp_get_listlot_stop_ver_004]
		@lot_no = @lot_no
		, @device = @device
		, @assy_name = @assy_name
		, @package = @package
		, @fab_wafer = @fab_wafer
		, @status = @status;
	---- ########## VERSION 004 ##########
END
