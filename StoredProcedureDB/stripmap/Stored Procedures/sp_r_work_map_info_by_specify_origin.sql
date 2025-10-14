

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_work_map_info_by_specify_origin]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128),
	@WORK_ID INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @CMD_TEXT NVARCHAR(4000) = '';

	SET NOCOUNT ON;

	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N'WK.id as WORK_NO ';
	SET @CMD_TEXT += N', SB.x as X ';
	SET @CMD_TEXT += N', SB.y as Y ';
	SET @CMD_TEXT += N', case when (PS.map_tool_origin_location in (0, 1) and PS.origin_location in (0, 3)) or ';		-- tool_origin:Top Right or Bottom Right かつ origin:Top Left or Bottom Left
	SET @CMD_TEXT += N'            (PS.map_tool_origin_location in (2, 3) and PS.origin_location in (1, 2)) then ';		-- tool_origin:Bottom Left or Top Left かつ origin:Top Right or Bottom Right
	SET @CMD_TEXT += N'        (PS.map_tool_origin_offset_x + (DN.strip_column_number - 1) - (SB.x - PS.origin_offset_x)) ';
	SET @CMD_TEXT += N'	   else ';
	SET @CMD_TEXT += N'        (PS.map_tool_origin_offset_x + (SB.x - PS.origin_offset_x)) ';
	SET @CMD_TEXT += N'  end as ShowX ';
	SET @CMD_TEXT += N', case when (PS.map_tool_origin_location in (1, 2) and PS.origin_location in (0, 1)) or ';		-- tool_origin:Bottom Right or Bottom Left かつ origin:Top Left or Top TopRight
	SET @CMD_TEXT += N'            (PS.map_tool_origin_location in (0, 3) and PS.origin_location in (2, 3)) then ';		-- tool_origin:Top Right or Top Left かつ origin:Bottom Right or Bottom Left
	SET @CMD_TEXT += N'        (PS.map_tool_origin_offset_y + (DN.strip_row_number - 1) - (SB.y - PS.origin_offset_y)) ';
	SET @CMD_TEXT += N'	   else ';
	SET @CMD_TEXT += N'        (PS.map_tool_origin_offset_y + (SB.y - PS.origin_offset_y)) ';
	SET @CMD_TEXT += N'  end as ShowY ';
	SET @CMD_TEXT += N',' + 'SB.bin_id as BIN_ID ';
	SET @CMD_TEXT += N',' + 'case when BD.bin_num is null then -1 else BD.bin_num end as BIN_NO ';
	SET @CMD_TEXT += N', PR.id as LAY_NO ';
	SET @CMD_TEXT += N', SB.is_revised as IS_REVISED ';
	SET @CMD_TEXT += N', case when PS.origin_location in (1,2) then ';				-- Top Right, Bottom Right
	SET @CMD_TEXT += N'		(DN.strip_column_number - 1) - (SB.x - PS.origin_offset_x) ';
	SET @CMD_TEXT += N'	else ';																	-- Top Left, Bottom Left														
	SET @CMD_TEXT += N'		SB.x - PS.origin_offset_x	';
	SET @CMD_TEXT += N'  end as ModuleX ';
	SET @CMD_TEXT += N', case when PS.origin_location in (2,3) then ';				-- Bottom Right, Bottom Left
	SET @CMD_TEXT += N'		(DN.strip_row_number - 1) - (SB.y - PS.origin_offset_y) ';
	SET @CMD_TEXT += N'	else ';																	-- Bottom Right, Bottom Left
	SET @CMD_TEXT += N'		SB.y - PS.origin_offset_y ';
	SET @CMD_TEXT += N'  end as ModuleY ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.works as WK with(nolock) ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.sub_works as SB with ( NOLOCK ) on SB.work_id = WK.id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.lots as LO with ( NOLOCK ) on LO.id = WK.lot_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.device_names as DN with ( NOLOCK ) on DN.id = LO.act_device_name_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.device_flows as DF with ( NOLOCK ) on DF.device_slip_id = LO.device_slip_id and DF.step_no = LO.step_no ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.jobs as JB with ( NOLOCK ) on JB.id = DF.job_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.processes as PR with ( NOLOCK ) on PR.id = JB.process_id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.mc.bin_definitions as BD with ( NOLOCK ) on BD.id = SB.bin_id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.method.package_stripmap_parameters as PS with (NOLOCK) on PS.package_id = LO.act_package_id ';
	SET @CMD_TEXT += N'where WK.id = ' + CONVERT(varchar,@WORK_ID) + ' ';
	SET @CMD_TEXT += N'order by SB.y, SB.x ';
	EXECUTE(@CMD_TEXT)

	return @@ROWCOUNT
END
