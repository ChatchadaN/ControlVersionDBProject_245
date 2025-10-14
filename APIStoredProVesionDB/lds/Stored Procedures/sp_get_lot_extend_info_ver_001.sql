-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_get_lot_extend_info_ver_001]
	@record_template VARCHAR(50) = NULL,
	@process VARCHAR(20) = NULL,
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

	DECLARE @sql NVARCHAR(MAX);
	DECLARE @params NVARCHAR(MAX);
	DECLARE @columns VARCHAR(MAX);

	SELECT @columns = STRING_AGG([column_name],',')
	FROM APCSProDWR.lds.lot_record_menu ME
	LEFT JOIN APCSProDWR.lds.lot_record_menu_templates MAP ON ME.id = MAP.lot_record_menu_id
	LEFT JOIN APCSProDWR.lds.lot_record_templates RT ON MAP.lot_record_templates_id = RT.id
	WHERE (RT.[name] = @record_template AND MAP.is_display = 1)
	OR ME.is_common = 1;

    SET @sql = N'SELECT ' + @columns + '
                FROM [APCSProDWR].[trans].[lot_transactions] mst
                LEFT JOIN [APCSProDWR].[trans].[lot_extends] ext ON mst.id = ext.lot_transactions_id
                WHERE 1 = 1';

    SET @params = N'@process NVARCHAR(50), @flow NVARCHAR(30), @mc_no NVARCHAR(30), @lot_no NVARCHAR(20), @package CHAR(20), @device CHAR(20), @opno_setup VARCHAR(8), @lot_start_time DATETIME, @lot_end_time DATETIME';

    IF (ISNULL(@process,'') <> '')
        SET @sql += N' AND process = @process';

	IF (ISNULL(@flow,'') <> '')
        SET @sql += N' AND flow = @flow';

	IF (ISNULL(@mc_no,'') <> '')
        SET @sql += N' AND mc_no = @mc_no';

    IF (ISNULL(@lot_no,'') <> '')
        SET @sql += N' AND lot_no = @lot_no';

	IF (ISNULL(@package,'') <> '')
        SET @sql += N' AND package = @package';

	IF (ISNULL(@device,'') <> '')
        SET @sql += N' AND device = @device';

	IF (ISNULL(@opno_setup,'') <> '')
        SET @sql += N' AND opno_setup = @opno_setup';

	IF (ISNULL(@lot_start_time,'') <> '')
        SET @sql += N' AND lot_start_time >= @lot_start_time';

	IF (ISNULL(@lot_end_time,'') <> '')
        SET @sql += N' AND lot_end_time <= @lot_end_time';

    EXEC sp_executesql @sql, @params, @process = @process, @flow = @flow, @mc_no = @mc_no, @lot_no = @lot_no, @package = @package, @device = @device, @opno_setup = @opno_setup
									, @lot_start_time = @lot_start_time, @lot_end_time = @lot_end_time;

	/* SET @sql = 'SELECT ' + @columns + ' FROM [APCSProDWR].[trans].[lot_transactions] mst ' +
			   'LEFT JOIN [APCSProDWR].[trans].[lot_extends] ext on mst.id = ext.lot_transactions_id ' +
			   'WHERE 1 = 1 ';

			   IF (ISNULL(@process,'') <> '') 
			   BEGIN 
					SET @sql += 'AND process = ''' + @process + '''';
			   END

			   IF (ISNULL(@lot_no,'') <> '') 
			   BEGIN 
					SET @sql += 'AND lot_no = ''' + @lot_no + '''';
			   END

	EXEC sp_executesql @sql; */


END
