


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_package_stripmap_parameters]
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
	SET @CMD_TEXT += N'    LO.act_package_id ';
	SET @CMD_TEXT += N'    ,PS.origin_location ';
	SET @CMD_TEXT += N'	,PS.origin_offset_x ';
	SET @CMD_TEXT += N'	,PS.origin_offset_y ';
	SET @CMD_TEXT += N'    ,PS.map_tool_origin_location ';
	SET @CMD_TEXT += N'	,PS.map_tool_origin_offset_x ';
	SET @CMD_TEXT += N'	,PS.map_tool_origin_offset_y ';
	SET @CMD_TEXT += N'	,case when PS.origin_location is null or ';
	SET @CMD_TEXT += N'	           PS.origin_offset_x is null or ';
	SET @CMD_TEXT += N'			   PS.origin_offset_y is null or ';
	SET @CMD_TEXT += N'	           PS.map_tool_origin_location is null or ';
	SET @CMD_TEXT += N'			   PS.map_tool_origin_offset_x is null or ';
	SET @CMD_TEXT += N'			   PS.map_tool_origin_offset_y is null then 1 ';
	SET @CMD_TEXT += N'		  else 0 ';
	SET @CMD_TEXT += N'     end as setup_error ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.works as WK with ( NOLOCK ) ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.lots as LO with ( NOLOCK ) ';
	SET @CMD_TEXT += N'    on LO.id = WK.lot_id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.method.package_stripmap_parameters as PS with (NOLOCK) ';
	SET @CMD_TEXT += N'    on PS.package_id = LO.act_package_id '; 
	SET @CMD_TEXT += N'where WK.id = ' + CONVERT(varchar,@WORK_ID) + ' ';

	EXECUTE(@CMD_TEXT)

	return @@ROWCOUNT
END
