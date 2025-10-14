-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [tg].[sp_get_mark_info]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @package_id INT
	DECLARE @device_id INT
	DECLARE @is_special BIT
	DECLARE @is_mix BIT
	DECLARE @lot_mix_d TABLE(lot_id BIGINT, lot_no CHAR(20))
	DECLARE @lot_mix_temp TABLE(lot_id BIGINT, lot_no CHAR(20))
	DECLARE @lot_master TABLE(lot_id BIGINT, lot_no CHAR(20))

	IF EXISTS(SELECT [id]
		FROM [APCSProDB].[trans].[lots]
		WHERE [lots].[lot_no] = @lot_no)
	BEGIN
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
			WHERE (([lot_marking_verify_condition].[package_id] = @package_id
			AND device_id IS NULL)
			OR (package_id = @package_id
			AND device_id = @device_id))
			AND condition_value = 1)
		BEGIN
			SELECT @is_special = CAST(1 AS BIT)
		END
		ELSE
		BEGIN
			SELECT @is_special = CAST(0 AS BIT)
		END

		IF EXISTS(SELECT [lots].[id]
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN [APCSProDB].[trans].[lot_combine] ON [lot_combine].[lot_id] = [lots].[id]
			WHERE [lots].[lot_no] = @lot_no
			AND [lot_combine].[lot_id] != [lot_combine].[member_lot_id])
		BEGIN
			INSERT INTO @lot_master
			SELECT [lots].[id]
			, [lots].[lot_no]
			FROM [APCSProDB].[trans].[lots]
			WHERE [lots].[lot_no] = @lot_no

			INSERT INTO @lot_mix_d
			SELECT [mix_lots].[id]
			, [mix_lots].[lot_no]
			FROM [APCSProDB].[trans].[lots] AS [master_lots]
			INNER JOIN [APCSProDB].[trans].[lot_combine] ON [lot_combine].[lot_id] = [master_lots].[id]
			INNER JOIN [APCSProDB].[trans].[lots] AS [mix_lots] ON [mix_lots].[id] = [lot_combine].[member_lot_id]
			WHERE [master_lots].[lot_no] = @lot_no
			AND [lot_combine].[lot_id] != [lot_combine].[member_lot_id]
			AND SUBSTRING([mix_lots].[lot_no],5,1) = 'D'

			INSERT INTO @lot_master
			SELECT [mix_lots].[id]
			, [mix_lots].[lot_no]
			FROM [APCSProDB].[trans].[lots] AS [master_lots]
			INNER JOIN [APCSProDB].[trans].[lot_combine] ON [lot_combine].[lot_id] = [master_lots].[id]
			INNER JOIN [APCSProDB].[trans].[lots] AS [mix_lots] ON [mix_lots].[id] = [lot_combine].[member_lot_id]
			WHERE [master_lots].[lot_no] = @lot_no
			AND [lot_combine].[lot_id] != [lot_combine].[member_lot_id]
			AND SUBSTRING([mix_lots].[lot_no],5,1) != 'D'

			IF EXISTS(SELECT [lot_no] FROM @lot_mix_d)
			BEGIN
				SELECT @is_mix = CAST(1 AS BIT)
			END
			ELSE
			BEGIN
				SELECT @is_mix = CAST(0 AS BIT)
			END

			WHILE (@is_mix = 1)
			BEGIN
				INSERT INTO @lot_mix_temp
				SELECT [lot_id]
				, [lot_no]
				FROM @lot_mix_d

				DELETE FROM @lot_mix_d

				INSERT INTO @lot_mix_d
				SELECT [mix_lots].[id]
				, [mix_lots].[lot_no]
				FROM @lot_mix_temp AS [master_lots]
				INNER JOIN [APCSProDB].[trans].[lot_combine] ON [lot_combine].[lot_id] = [master_lots].[lot_id]
				INNER JOIN [APCSProDB].[trans].[lots] AS [mix_lots] ON [mix_lots].[id] = [lot_combine].[member_lot_id]
				WHERE [lot_combine].[lot_id] != [lot_combine].[member_lot_id]
				AND SUBSTRING([mix_lots].[lot_no],5,1) = 'D'

				INSERT INTO @lot_master
				SELECT [mix_lots].[id]
				, [mix_lots].[lot_no]
				FROM @lot_mix_temp AS [master_lots]
				INNER JOIN [APCSProDB].[trans].[lot_combine] ON [lot_combine].[lot_id] = [master_lots].[lot_id]
				INNER JOIN [APCSProDB].[trans].[lots] AS [mix_lots] ON [mix_lots].[id] = [lot_combine].[member_lot_id]
				WHERE [lot_combine].[lot_id] != [lot_combine].[member_lot_id]
				AND SUBSTRING([mix_lots].[lot_no],5,1) != 'D'

				DELETE FROM @lot_mix_temp

				IF EXISTS(SELECT lot_no FROM @lot_mix_d)
				BEGIN
					SELECT @is_mix = CAST(1 AS BIT)
				END
				ELSE
				BEGIN
					SELECT @is_mix = CAST(0 AS BIT)
				END
			END

			SELECT CAST(1 AS BIT) AS [status]
			, [FT_SYMBOL_1] + [FT_SYMBOL_2] As [mark]
			FROM @lot_master
			INNER JOIN [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] ON [LCQW_UNION_WORK_DENPYO_PRINT].[LOT_NO_2] = [@lot_master].[lot_no]
			GROUP BY [FT_SYMBOL_1],[FT_SYMBOL_2]
		END
		ELSE
		BEGIN
			SELECT CAST(1 AS BIT) AS [status]
			, [FT_SYMBOL_1] + [FT_SYMBOL_2] AS [mark]
			FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
			WHERE [LOT_NO_2] = @lot_no
		END
	END
	ELSE
	BEGIN
		SELECT CAST(0 AS BIT) AS [status]
		, '' AS [mark]
	END
END
