
CREATE PROCEDURE [trans].[sp_set_lot_masks_by_task]
	-- Add the parameters for the stored procedure here
	@LotNo VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @Device CHAR(20) = '',
		@Package CHAR(20) = '',
		@ColumnMark VARCHAR(MAX) = '',
		@FT_SYMBOL_1 VARCHAR(20) = '',	
		@FT_SYMBOL_2 VARCHAR(20) = '',	
		@FT_SYMBOL_3 VARCHAR(20) = '',
		@FT_SYMBOL_4 VARCHAR(20) = '',
		@FT_SYMBOL_5 VARCHAR(20) = '',
		@result VARCHAR(500) = '',
		@result1 VARCHAR(500) = '',
		@KMno VARCHAR(100)

	DECLARE @t2 TABLE (
		[result] VARCHAR(500)
	)

	----# Find device, package
	SELECT @Device = [device_names].[name]
		, @Package = [packages].[name]
	FROM [APCSProDB].[trans].[lots]
	LEFT JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
	LEFT JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
	WHERE [lot_no] = @LotNo

	----# Find A,F,E,G from D
	IF EXISTS (
		SELECT [lot_member].[lot_no]
		FROM [APCSProDB].[trans].[lot_combine] 
		LEFT JOIN [APCSProDB].[trans].[lots] AS [lot_master] ON [lot_combine].[lot_id] = [lot_master].[id]
		LEFT JOIN [APCSProDB].[trans].[lots] AS [lot_member] ON [lot_combine].[member_lot_id] = [lot_member].[id]
		WHERE [lot_combine].[lot_id] != [lot_combine].[member_lot_id]
			AND [lot_master].[lot_no] = @LotNo
			AND ( [lot_member].[lot_no] LIKE '____A____V'
				OR [lot_member].[lot_no] LIKE '____F____V'
				OR [lot_member].[lot_no] LIKE '____E____V'
				OR [lot_member].[lot_no] LIKE '____G____V' )
	)
	BEGIN
		----# Found Find A,F,E,G from D

		----# Find by device and package from config
		IF EXISTS (
			SELECT [Package] FROM [StoredProcedureDB].[dbo].[config_lot_marks]
			WHERE [Package] = @Package
				AND [Device] = @Device
				AND [IsEnabled] = 1
		)
		BEGIN
			SELECT @ColumnMark = ColumnMark,
				@FT_SYMBOL_1 = FT_SYMBOL_1,	
				@FT_SYMBOL_2 = FT_SYMBOL_2,	
				@FT_SYMBOL_3 = FT_SYMBOL_3,
				@FT_SYMBOL_4 = FT_SYMBOL_4,
				@FT_SYMBOL_5 = FT_SYMBOL_5
			FROM [StoredProcedureDB].[dbo].[config_lot_marks]
			WHERE [Package] = @Package
				AND [Device] = @Device
				AND [IsEnabled] = 1
		END

		----# Find by device and package = 'ALL' from config
		IF EXISTS (
			SELECT [Package] FROM [StoredProcedureDB].[dbo].[config_lot_marks]
			WHERE [Package] = @Package
				AND [Device] = 'ALL'
				AND [IsEnabled] = 1
		) AND (@ColumnMark = '')
		BEGIN
			SELECT @ColumnMark = ColumnMark,
				@FT_SYMBOL_1 = FT_SYMBOL_1,	
				@FT_SYMBOL_2 = FT_SYMBOL_2,	
				@FT_SYMBOL_3 = FT_SYMBOL_3,
				@FT_SYMBOL_4 = FT_SYMBOL_4,
				@FT_SYMBOL_5 = FT_SYMBOL_5
			FROM [StoredProcedureDB].[dbo].[config_lot_marks]
			WHERE [Package] = @Package
				AND [Device] = 'ALL'
				AND [IsEnabled] = 1
		END

		----# have data in config
		IF (@ColumnMark != '')
		BEGIN
			--SELECT @result = IIF(@result != '', @result + '+' + 
			--'(' + ( CASE
			--	WHEN value = 'FT_SYMBOL_1' THEN 'SUBSTRING(' + value + ', 1,' +  IIF(@FT_SYMBOL_1 = 'ALL' OR ISNULL(@FT_SYMBOL_1,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_1) + ')'
			--	WHEN value = 'FT_SYMBOL_2' THEN 'SUBSTRING(' + value + ', 1,' +  IIF(@FT_SYMBOL_2 = 'ALL' OR ISNULL(@FT_SYMBOL_2,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_2) + ')'
			--	WHEN value = 'FT_SYMBOL_3' THEN 'SUBSTRING(' + value + ', 1,' +  IIF(@FT_SYMBOL_3 = 'ALL' OR ISNULL(@FT_SYMBOL_3,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_3) + ')'
			--	WHEN value = 'FT_SYMBOL_4' THEN 'SUBSTRING(' + value + ', 1,' +  IIF(@FT_SYMBOL_4 = 'ALL' OR ISNULL(@FT_SYMBOL_4,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_4) + ')'
			--	WHEN value = 'FT_SYMBOL_5' THEN 'SUBSTRING(' + value + ', 1,' +  IIF(@FT_SYMBOL_5 = 'ALL' OR ISNULL(@FT_SYMBOL_5,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_5) + ')'
			--	ELSE value
			--END ) + ')', '' +
			--'(' + ( CASE
			--	WHEN value = 'FT_SYMBOL_1' THEN 'SUBSTRING(' + value + ', 1,' +  IIF(@FT_SYMBOL_1 = 'ALL' OR ISNULL(@FT_SYMBOL_1,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_1) + ')'
			--	WHEN value = 'FT_SYMBOL_2' THEN 'SUBSTRING(' + value + ', 1,' +  IIF(@FT_SYMBOL_2 = 'ALL' OR ISNULL(@FT_SYMBOL_2,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_2) + ')'
			--	WHEN value = 'FT_SYMBOL_3' THEN 'SUBSTRING(' + value + ', 1,' +  IIF(@FT_SYMBOL_3 = 'ALL' OR ISNULL(@FT_SYMBOL_3,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_3) + ')'
			--	WHEN value = 'FT_SYMBOL_4' THEN 'SUBSTRING(' + value + ', 1,' +  IIF(@FT_SYMBOL_4 = 'ALL' OR ISNULL(@FT_SYMBOL_4,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_4) + ')'
			--	WHEN value = 'FT_SYMBOL_5' THEN 'SUBSTRING(' + value + ', 1,' +  IIF(@FT_SYMBOL_5 = 'ALL' OR ISNULL(@FT_SYMBOL_5,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_5) + ')'
			--	ELSE value
			--END ) + ')' )
			SELECT @result = IIF(@result != '', @result + '+' + 
			'(' + ( CASE
				WHEN value = 'FT_SYMBOL_1' THEN 'SUBSTRING(REPLACE(' + value + ','' '',''''), 1,' +  IIF(@FT_SYMBOL_1 = 'ALL' OR ISNULL(@FT_SYMBOL_1,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_1) + ')'
				WHEN value = 'FT_SYMBOL_2' THEN 'SUBSTRING(REPLACE(' + value + ','' '',''''), 1,' +  IIF(@FT_SYMBOL_2 = 'ALL' OR ISNULL(@FT_SYMBOL_2,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_2) + ')'
				WHEN value = 'FT_SYMBOL_3' THEN 'SUBSTRING(REPLACE(' + value + ','' '',''''), 1,' +  IIF(@FT_SYMBOL_3 = 'ALL' OR ISNULL(@FT_SYMBOL_3,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_3) + ')'
				WHEN value = 'FT_SYMBOL_4' THEN 'SUBSTRING(REPLACE(' + value + ','' '',''''), 1,' +  IIF(@FT_SYMBOL_4 = 'ALL' OR ISNULL(@FT_SYMBOL_4,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_4) + ')'
				WHEN value = 'FT_SYMBOL_5' THEN 'SUBSTRING(REPLACE(' + value + ','' '',''''), 1,' +  IIF(@FT_SYMBOL_5 = 'ALL' OR ISNULL(@FT_SYMBOL_5,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_5) + ')'
				ELSE value
			END ) + ')', '' +
			'(' + ( CASE
				WHEN value = 'FT_SYMBOL_1' THEN 'SUBSTRING(REPLACE(' + value + ','' '',''''), 1,' +  IIF(@FT_SYMBOL_1 = 'ALL' OR ISNULL(@FT_SYMBOL_1,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_1) + ')'
				WHEN value = 'FT_SYMBOL_2' THEN 'SUBSTRING(REPLACE(' + value + ','' '',''''), 1,' +  IIF(@FT_SYMBOL_2 = 'ALL' OR ISNULL(@FT_SYMBOL_2,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_2) + ')'
				WHEN value = 'FT_SYMBOL_3' THEN 'SUBSTRING(REPLACE(' + value + ','' '',''''), 1,' +  IIF(@FT_SYMBOL_3 = 'ALL' OR ISNULL(@FT_SYMBOL_3,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_3) + ')'
				WHEN value = 'FT_SYMBOL_4' THEN 'SUBSTRING(REPLACE(' + value + ','' '',''''), 1,' +  IIF(@FT_SYMBOL_4 = 'ALL' OR ISNULL(@FT_SYMBOL_4,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_4) + ')'
				WHEN value = 'FT_SYMBOL_5' THEN 'SUBSTRING(REPLACE(' + value + ','' '',''''), 1,' +  IIF(@FT_SYMBOL_5 = 'ALL' OR ISNULL(@FT_SYMBOL_5,'') = '', CAST(20 AS VARCHAR(2)), @FT_SYMBOL_5) + ')'
				ELSE value
			END ) + ')' )
			FROM STRING_SPLIT(@ColumnMark, ',')

			SELECT TOP 1 @result1 = '''' + TRIM([lot_member].[lot_no]) + ''''
			FROM [APCSProDB].[trans].[lot_combine] 
			LEFT JOIN [APCSProDB].[trans].[lots] AS [lot_master] ON [lot_combine].[lot_id] = [lot_master].[id]
			LEFT JOIN [APCSProDB].[trans].[lots] AS [lot_member] ON [lot_combine].[member_lot_id] = [lot_member].[id]
			WHERE [lot_combine].[lot_id] != [lot_combine].[member_lot_id]
				AND [lot_master].[lot_no] = @LotNo
				AND ( [lot_member].[lot_no] LIKE '____A____V'
					OR [lot_member].[lot_no] LIKE '____F____V'
					OR [lot_member].[lot_no] LIKE '____E____V'
					OR [lot_member].[lot_no] LIKE '____G____V' )

			INSERT INTO @t2
			EXEC ('SELECT ' 
				+ @result 
				+ ' FROM [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]'
				+ ' WHERE [LOT_NO_2] = ' + @result1)

			IF EXISTS ( SELECT * FROM @t2 )
			BEGIN
				IF NOT EXISTS (
					SELECT [lot_no] 
					FROM [APIStoredProDB].[dbo].[lot_masks]
					WHERE [lot_no] = @LotNo
				)
				BEGIN
					INSERT INTO [APIStoredProDB].[dbo].[lot_masks]
					SELECT @LotNo AS [lot_no]
						, [result] AS [mno]
						, 'INSERT by TASK (' + HOST_NAME() + ')' AS [comment]
						, GETDATE() AS [date_stamp]
					FROM @t2;

					SELECT @KMno = [result] FROM @t2
					PRINT '[TASK INSERT LOT MARK] LotNo : ' + @LotNo + ', Mark : ' + @KMno + ', INSERT : sucess'
					RETURN;
				END
				ELSE
				BEGIN
					--SELECT @LotNo AS [lot_no]
					--	, NULL AS [Mno]
					--	, 'ERROR1' AS [State]
					--	, 'have data in table [lot_masks]' AS [Coment]
					PRINT '[TASK INSERT LOT MARK] LotNo : ' + @LotNo + ', ERROR : have data in table [lot_masks]'
					RETURN;
				END
			END
			ELSE
			BEGIN
				--SELECT @LotNo AS [lot_no]
				--	, NULL AS [Mno]
				--	, 'ERROR2' AS [State]
				--	, 'not found data in table [LCQW_UNION_WORK_DENPYO_PRINT]' AS [Coment]
				PRINT '[TASK INSERT LOT MARK] LotNo : ' + @LotNo + ', ERROR : not found data in table [LCQW_UNION_WORK_DENPYO_PRINT]'
				RETURN;
			END
		END
		ELSE
		BEGIN
			--SELECT @LotNo AS [lot_no]
			--	, NULL AS [Mno]
			--	, 'ERROR' AS [State] 
			--	, 'config not found' AS [Coment]
			PRINT '[TASK INSERT LOT MARK] LotNo : ' + @LotNo + ', ERROR : config not found'
			RETURN;
		END
	END
	ELSE
	BEGIN
		----# Not found Find A,F,E,G from D

		----# Find by device and package from config
		IF EXISTS (
			SELECT [Package] FROM [StoredProcedureDB].[dbo].[config_lot_marks]
			WHERE [Package] = @Package
				AND [Device] = @Device
				AND [IsEnabled] = 1
		) OR EXISTS (
			SELECT [Package] FROM [StoredProcedureDB].[dbo].[config_lot_marks]
			WHERE [Package] = @Package
				AND [Device] = 'ALL'
				AND [IsEnabled] = 1
		)
		BEGIN
			IF EXISTS (
				SELECT TOP 1 [lot_masks1].[mno]
				FROM [APCSProDB].[trans].[lot_combine] 
				LEFT JOIN [APCSProDB].[trans].[lots] AS [lot_master] ON [lot_combine].[lot_id] = [lot_master].[id]
				LEFT JOIN [APCSProDB].[trans].[lots] AS [lot_member] ON [lot_combine].[member_lot_id] = [lot_member].[id]
				LEFT JOIN [APIStoredProDB].[dbo].[lot_masks] AS [lot_masks1] ON [lot_member].[lot_no] = [lot_masks1].[lot_no]
				WHERE [lot_combine].[lot_id] != [lot_combine].[member_lot_id]
					AND [lot_masks1].[mno] IS NOT NULL
					AND [lot_master].[lot_no] = @LotNo
			)
			BEGIN
				INSERT INTO @t2
				SELECT TOP 1 [lot_masks1].[mno]
				FROM [APCSProDB].[trans].[lot_combine] 
				LEFT JOIN [APCSProDB].[trans].[lots] AS [lot_master] ON [lot_combine].[lot_id] = [lot_master].[id]
				LEFT JOIN [APCSProDB].[trans].[lots] AS [lot_member] ON [lot_combine].[member_lot_id] = [lot_member].[id]
				LEFT JOIN [APIStoredProDB].[dbo].[lot_masks] AS [lot_masks1] ON [lot_member].[lot_no] = [lot_masks1].[lot_no]
				WHERE [lot_combine].[lot_id] != [lot_combine].[member_lot_id]
					AND [lot_masks1].[mno] IS NOT NULL
					AND [lot_master].[lot_no] = @LotNo

				INSERT INTO [APIStoredProDB].[dbo].[lot_masks]
				SELECT @LotNo AS [lot_no]
					, [result] AS [mno]
					, 'INSERT by TASK (' + HOST_NAME() + ')' AS [comment]
					, GETDATE() AS [date_stamp]
				FROM @t2;

				SELECT @KMno = [result] FROM @t2
				PRINT '[TASK INSERT LOT MARK] LotNo : ' + @LotNo + ', Mark : ' + @KMno + ', INSERT : sucess'
				RETURN;
			END
			ELSE
			BEGIN
				--SELECT @LotNo AS [lot_no]
				--	, NULL AS [Mno]
				--	, 'ERROR' AS [State] 
				--	, 'mark not found' AS [Coment]
				PRINT '[TASK INSERT LOT MARK] LotNo : ' + @LotNo + ', ERROR : mark not found'
				RETURN;
			END
		END
		ELSE
		BEGIN
			--SELECT @LotNo AS [lot_no]
			--	, NULL AS [Mno]
			--	, 'ERROR' AS [State] 
			--	, 'config not found' AS [Coment]
			PRINT '[TASK INSERT LOT MARK] LotNo : ' + @LotNo + ', ERROR : config not found'
			RETURN;
		END
	END
END
