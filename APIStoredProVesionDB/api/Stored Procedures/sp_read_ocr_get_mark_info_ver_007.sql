-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_ocr_get_mark_info_ver_007]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @mix_lot_no CHAR(20)
	DECLARE @package_id INT
	DECLARE @device_id INT
	DECLARE @is_special BIT

	SELECT @package_id = [packages].[id]
	, @device_id = [device_names].[id]
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	INNER JOIN [APCSProDB].[method].[packages] ON [packages].[id] = [device_names].[package_id]
	WHERE [lots].[lot_no] = @lot_no

	IF EXISTS(SELECT [id]
		FROM [APCSProDB].[trans].[lot_marking_verify_condition]
		WHERE ([lot_marking_verify_condition].[package_id] = @package_id
		AND device_id IS NULL)
		OR (package_id = @package_id
		AND device_id = @device_id))
	BEGIN
		SELECT @is_special = CAST(1 AS BIT)
	END
	ELSE
	BEGIN
		SELECT @is_special = CAST(0 AS BIT)
	END

	IF EXISTS(SELECT [LOT_NO_2]
		FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
		WHERE [LOT_NO_2] = @lot_no)
	BEGIN
		IF (SUBSTRING(@lot_no,5,1) = 'E')
		BEGIN
			SELECT CAST(1 AS BIT) AS [status]
			, CASE WHEN (CAST([ASSY_SYMBOL_1] AS VARCHAR(MAX)) != [ASSY_SYMBOL_1]) THEN '' ELSE [ASSY_SYMBOL_1] END
				+ CASE WHEN (CAST([ASSY_SYMBOL_2] AS VARCHAR(MAX)) != [ASSY_SYMBOL_2]) THEN '' ELSE [ASSY_SYMBOL_2] END
				+ CASE WHEN (CAST([ASSY_SYMBOL_3] AS VARCHAR(MAX)) != [ASSY_SYMBOL_3]) THEN '' ELSE [ASSY_SYMBOL_3] END
				+ CASE WHEN (CAST([ASSY_SYMBOL_4] AS VARCHAR(MAX)) != [ASSY_SYMBOL_4]) THEN '' ELSE [ASSY_SYMBOL_4] END
				+ CASE WHEN (CAST([ASSY_SYMBOL_5] AS VARCHAR(MAX)) != [ASSY_SYMBOL_5]) THEN '' ELSE [ASSY_SYMBOL_5] END
				+ CASE WHEN (CAST([ASSY_SYMBOL_6] AS VARCHAR(MAX)) != [ASSY_SYMBOL_6]) THEN '' ELSE [ASSY_SYMBOL_6] END AS [mark]
			, @is_special AS [is_special]
			, CAST(0 AS BIT) AS [is_request]
			FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
			WHERE [LOT_NO_2] = @lot_no
		END
		ELSE
		BEGIN
			SELECT CAST(1 AS BIT) AS [status]
			, CASE WHEN (CAST([FT_SYMBOL_1] AS VARCHAR(MAX)) != [FT_SYMBOL_1]) THEN '' ELSE [FT_SYMBOL_1] END
				+ CASE WHEN (CAST([FT_SYMBOL_2] AS VARCHAR(MAX)) != [FT_SYMBOL_2]) THEN '' ELSE [FT_SYMBOL_2] END
				+ CASE WHEN (CAST([FT_SYMBOL_3] AS VARCHAR(MAX)) != [FT_SYMBOL_3]) THEN '' ELSE [FT_SYMBOL_3] END
				+ CASE WHEN (CAST([FT_SYMBOL_4] AS VARCHAR(MAX)) != [FT_SYMBOL_4]) THEN '' ELSE [FT_SYMBOL_4] END
				+ CASE WHEN (CAST([FT_SYMBOL_5] AS VARCHAR(MAX)) != [FT_SYMBOL_5]) THEN '' ELSE [FT_SYMBOL_5] END
				+ CASE WHEN (CAST([FT_SYMBOL_6] AS VARCHAR(MAX)) != [FT_SYMBOL_6]) THEN '' ELSE [FT_SYMBOL_6] END AS [mark]
			, @is_special AS [is_special]
			, CAST(0 AS BIT) AS [is_request]
			FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
			WHERE [LOT_NO_2] = @lot_no
		END
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT [lots].[id]
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN [APCSProDB].[trans].[lot_combine] ON [lot_combine].[lot_id] = [lots].[id]
			WHERE [lots].[lot_no] = @lot_no)
		BEGIN
			SELECT TOP(1) @mix_lot_no = [mix_lots].[lot_no]
			FROM [APCSProDB].[trans].[lots] AS [master_lots]
			INNER JOIN [APCSProDB].[trans].[lot_combine] ON [lot_combine].[lot_id] = [master_lots].[id]
			INNER JOIN [APCSProDB].[trans].[lots] AS [mix_lots] ON [mix_lots].[id] = [lot_combine].[member_lot_id]
			WHERE [master_lots].[lot_no] = @lot_no
			ORDER BY [mix_lots].[qty_hasuu]

			WHILE(SUBSTRING(@mix_lot_no,5,1) = 'D')
			BEGIN
				IF EXISTS(SELECT [mix_lots].[lot_no]
					FROM [APCSProDB].[trans].[lots] AS [master_lots]
					INNER JOIN [APCSProDB].[trans].[lot_combine] ON [lot_combine].[lot_id] = [master_lots].[id]
					INNER JOIN [APCSProDB].[trans].[lots] AS [mix_lots] ON [mix_lots].[id] = [lot_combine].[member_lot_id]
					WHERE [master_lots].[lot_no] = @mix_lot_no)
				BEGIN
					SELECT TOP(1) @mix_lot_no = [mix_lots].[lot_no]
					FROM [APCSProDB].[trans].[lots] AS [master_lots]
					INNER JOIN [APCSProDB].[trans].[lot_combine] ON [lot_combine].[lot_id] = [master_lots].[id]
					INNER JOIN [APCSProDB].[trans].[lots] AS [mix_lots] ON [mix_lots].[id] = [lot_combine].[member_lot_id]
					WHERE [master_lots].[lot_no] = @mix_lot_no
					ORDER BY [mix_lots].[qty_hasuu]
				END
				ELSE
				BEGIN
					SELECT @mix_lot_no = '-'
				END
			END

			IF EXISTS(SELECT [LOT_NO_2]
				FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
				WHERE [LOT_NO_2] = @mix_lot_no)
			BEGIN
				IF (SUBSTRING(@lot_no,5,1) = 'E')
				BEGIN
					SELECT CAST(1 AS BIT) AS [status]
					, CASE WHEN (CAST([ASSY_SYMBOL_1] AS VARCHAR(MAX)) != [ASSY_SYMBOL_1]) THEN '' ELSE [ASSY_SYMBOL_1] END
						+ CASE WHEN (CAST([ASSY_SYMBOL_2] AS VARCHAR(MAX)) != [ASSY_SYMBOL_2]) THEN '' ELSE [ASSY_SYMBOL_2] END
						+ CASE WHEN (CAST([ASSY_SYMBOL_3] AS VARCHAR(MAX)) != [ASSY_SYMBOL_3]) THEN '' ELSE [ASSY_SYMBOL_3] END
						+ CASE WHEN (CAST([ASSY_SYMBOL_4] AS VARCHAR(MAX)) != [ASSY_SYMBOL_4]) THEN '' ELSE [ASSY_SYMBOL_4] END
						+ CASE WHEN (CAST([ASSY_SYMBOL_5] AS VARCHAR(MAX)) != [ASSY_SYMBOL_5]) THEN '' ELSE [ASSY_SYMBOL_5] END
						+ CASE WHEN (CAST([ASSY_SYMBOL_6] AS VARCHAR(MAX)) != [ASSY_SYMBOL_6]) THEN '' ELSE [ASSY_SYMBOL_6] END AS [mark]
					, @is_special AS [is_special]
					, CAST(0 AS BIT) AS [is_request]
					FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
					WHERE [LOT_NO_2] = @mix_lot_no
				END
				ELSE
				BEGIN
					SELECT CAST(1 AS BIT) AS [status]
					, CASE WHEN (CAST([FT_SYMBOL_1] AS VARCHAR(MAX)) != [FT_SYMBOL_1]) THEN '' ELSE [FT_SYMBOL_1] END
						+ CASE WHEN (CAST([FT_SYMBOL_2] AS VARCHAR(MAX)) != [FT_SYMBOL_2]) THEN '' ELSE [FT_SYMBOL_2] END
						+ CASE WHEN (CAST([FT_SYMBOL_3] AS VARCHAR(MAX)) != [FT_SYMBOL_3]) THEN '' ELSE [FT_SYMBOL_3] END
						+ CASE WHEN (CAST([FT_SYMBOL_4] AS VARCHAR(MAX)) != [FT_SYMBOL_4]) THEN '' ELSE [FT_SYMBOL_4] END
						+ CASE WHEN (CAST([FT_SYMBOL_5] AS VARCHAR(MAX)) != [FT_SYMBOL_5]) THEN '' ELSE [FT_SYMBOL_5] END
						+ CASE WHEN (CAST([FT_SYMBOL_6] AS VARCHAR(MAX)) != [FT_SYMBOL_6]) THEN '' ELSE [FT_SYMBOL_6] END AS [mark]
					, @is_special AS [is_special]
					, CAST(0 AS BIT) AS [is_request]
					FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
					WHERE [LOT_NO_2] = @mix_lot_no
				END
			END
			ELSE
			BEGIN
				SELECT CAST(1 AS BIT) AS [status]
				, 'NO MARK DATA' AS [mark]
				, @is_special AS [is_special]
				, CAST(1 AS BIT) AS [is_request]
			END
		END
		ELSE
		BEGIN
			SELECT CAST(0 AS BIT) AS [status]
			, '' AS [mark]
			, @is_special AS [is_special]
			, CAST(0 AS BIT) AS [is_request]
		END
	END
END
