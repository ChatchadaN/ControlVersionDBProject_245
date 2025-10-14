
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_stripmap_base]
	-- Add the parameters for the stored procedure here
	@LotId INT,
	@JobId INT,
	@JobName NVARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT 
		T.*
		, BD_DB.bin_description AS BIN_DEF_DB	-- bin_description for each DB machine / ŠeDB‘•’u‚Ìbin_description
		, CAST(BD_DB.die_quality AS int) AS BIN_STATUS_DB	-- die_quality for each DB machine / ŠeDB‘•’u‚Ìdie_quality
	FROM (
		SELECT
			WK.work_no AS WORK_NO
			, SB.x AS X
			, SB.y AS Y
			, CASE WHEN (PS.map_tool_origin_location IN (0, 1) AND PS.origin_location IN (0, 3)) OR
			(PS.map_tool_origin_location IN (2, 3) AND PS.origin_location IN (1, 2)) THEN
			(PS.map_tool_origin_offset_x + (DN.strip_column_number - 1) - (SB.x - PS.origin_offset_x))
			ELSE
			(PS.map_tool_origin_offset_x + (SB.x - PS.origin_offset_x))
			END AS ShowX
			, CASE WHEN (PS.map_tool_origin_location IN (1, 2) AND PS.origin_location IN (0, 1)) OR
			(PS.map_tool_origin_location IN (0, 3) AND PS.origin_location IN (2, 3)) THEN
			(PS.map_tool_origin_offset_y + (DN.strip_row_number - 1) - (SB.y - PS.origin_offset_y))
			ELSE
			(PS.map_tool_origin_offset_y + (SB.y - PS.origin_offset_y))
			END AS ShowY
			, SB.bin_id AS BIN_ID
			, CASE WHEN BD.bin_num IS NULL THEN '' ELSE BD.bin_description END AS BIN_DEF
			, CASE WHEN BD.bin_num IS NULL THEN -1 ELSE BD.die_quality END AS BIN_STATUS
			, CASE WHEN PS.origin_location IN (1,2) THEN
			(DN.strip_column_number - 1) - (SB.x - PS.origin_offset_x)
			ELSE
			SB.x - PS.origin_offset_x
			END AS ModuleX
			, CASE WHEN PS.origin_location IN (2,3) THEN
			(DN.strip_row_number - 1) - (SB.y - PS.origin_offset_y)
			ELSE
			SB.y - PS.origin_offset_y
			END AS ModuleY
			, PR.id AS ProcessId
			, CASE @jobName 
				WHEN 'DB1' THEN -- If '|' is 0, bin_id; if '|' is 1 or more, bin_id_histories first bin_id / '|'‚ª0‚Ìê‡‚Í bin_idA'|'‚ª1ˆÈã‚Ìê‡‚Í bin_id_histories ‚Ìæ“ª bin_id
					CASE WHEN LEN(SB.bin_id_histories) - LEN(REPLACE(SB.bin_id_histories, '|', '')) = 0 THEN SB.bin_id
					ELSE LEFT(bin_id_histories, CHARINDEX('|', bin_id_histories) - 1) END
				WHEN 'DB2' THEN -- NULL if '|' is 0, bin_id at the end of bin_id_histories if '|' is 1, bin_Id in the middle of bin_id_histories if '|' is 2 / '|'‚ª0‚Ìê‡‚Í NULLA'|'‚ª1‚Ìê‡‚Í bin_id_histories ‚Ì––”ö bin_idA'|'‚ª2‚Ìê‡‚Í bin_id_histories ‚Ì^‚ñ’† bin_Id
					CASE LEN(SB.bin_id_histories) - LEN(REPLACE(SB.bin_id_histories, '|', ''))
					  WHEN 0 THEN NULL
					  WHEN 1 THEN RIGHT(bin_id_histories, CHARINDEX('|', REVERSE(bin_id_histories)) - 1)
					ELSE LEFT(SUBSTRING(bin_id_histories, CHARINDEX('|', bin_id_histories) + 1, LEN(bin_id_histories)), CHARINDEX('|', SUBSTRING(bin_id_histories, CHARINDEX('|', bin_id_histories) + 1, LEN(bin_id_histories))) - 1) END
				WHEN 'DB3' THEN -- NULL if '|' is 0 or 1, or tail of bin_id_histories if '|' is 2 bin_id / '|'‚ª0‚Ü‚½‚Í1‚Ìê‡‚Í NULLA'|'‚ª2‚Ìê‡‚Í bin_id_histories ‚Ì––”ö bin_id
					CASE WHEN LEN(SB.bin_id_histories) - LEN(REPLACE(SB.bin_id_histories, '|', '')) <= 1 THEN NULL
					ELSE RIGHT(bin_id_histories, CHARINDEX('|', REVERSE(bin_id_histories)) - 1) END
			ELSE NULL END AS BIN_ID_DB	-- NULL fixed except for DB / DBˆÈŠO‚ÍNULLŒÅ’è
		FROM 
			[APCSProDB].[trans].[works] AS WK WITH(NOLOCK)
		INNER JOIN [APCSProDB].[trans].[sub_works] AS SB WITH(NOLOCK) 
		ON SB.work_id = WK.id
		INNER JOIN [APCSProDB].[trans].[lots] AS LO WITH(NOLOCK) 
		ON LO.id = WK.lot_id
		INNER JOIN [APCSProDB].[method].[device_names] AS DN WITH(NOLOCK) 
		ON DN.id = LO.act_device_name_id
		INNER JOIN [APCSProDB].[method].[jobs] AS JB WITH(NOLOCK) 
		ON JB.id = SB.job_id
		INNER JOIN [APCSProDB].[method].[processes] AS PR WITH(NOLOCK) 
		ON PR.id = JB.process_id

		-- Exclude bin_id edited by StripMapViewer(only bin_id registered in BinCode_Set of MDM is acquired) / StripMapViewer‚Å•ÒW‚µ‚½bin_id‚ðœŠO(MDM‚ÌBinCode_Set‚É“o˜^‚³‚ê‚Ä‚¢‚ébin_id‚Ì‚ÝŽæ“¾)
		INNER JOIN [APCSProDB].[mc].[group_models] AS GM WITH(NOLOCK) 
		ON GM.machine_group_id = JB.machine_group_id
		INNER JOIN [APCSProDB].[mc].[models] AS M WITH(NOLOCK) 
		ON M.id = GM.machine_model_id
		INNER JOIN [APCSProDB].[mc].[model_bin_upload] AS MBU WITH(NOLOCK) 
		ON MBU.machine_model_id = M.id
		AND MBU.bin_id = SB.bin_id

		LEFT OUTER JOIN [APCSProDB].[mc].[bin_definitions] AS BD WITH(NOLOCK) 
		ON BD.id = SB.bin_id
		LEFT OUTER JOIN [APCSProDB].[method].[package_stripmap_parameters] AS PS WITH(NOLOCK) 
		ON PS.package_id = LO.act_package_id
		WHERE 
			WK.lot_id = @LotId
		AND JB.id = @JobId
	) T
	LEFT OUTER JOIN [APCSProDB].[mc].[bin_definitions] AS BD_DB WITH(NOLOCK) 
	ON BD_DB.id = T.BIN_ID_DB
	ORDER BY
		T.Y, T.X, T.WORK_NO
END