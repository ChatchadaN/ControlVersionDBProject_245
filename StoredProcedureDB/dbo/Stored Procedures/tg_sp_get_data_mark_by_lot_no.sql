-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_mark_by_lot_no]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @MemberLotNo VARCHAR(10) = @lot_no;
	----------------------------------------------------------------------------------------------------------
	DECLARE @Counter INT 
	DECLARE @CounterTotal INT
	--//table data
	DECLARE @table TABLE(
		[LotId] INT,
		[LotNo] VARCHAR(10),
		[Floor] INT
	)
	DECLARE @tableD TABLE(
		[LotId] INT,
		[LotNo] VARCHAR(10),
		[Floor] INT
	)
	--//table data loop
	DECLARE @table2 TABLE(
		[LotNo] VARCHAR(10)
	)
	----------------------------------------------------------------------------------------------------------
	IF (SUBSTRING(@MemberLotNo,5,1) = 'D')
	BEGIN
		SET @Counter = 1
		SET @CounterTotal = 1
		WHILE ( @Counter <= @CounterTotal)
		BEGIN
			--//row 1 data from @MemberLotNo
			IF (@Counter = 1)
			BEGIN
				DELETE FROM @table2;
				INSERT INTO @table2 ([LotNo])
				SELECT [lot_no] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @MemberLotNo;
			END
			----------------------------------------------------------------------------------------------------------
			--//Check data exists
			IF EXISTS(
				SELECT [lots].[id] AS [LotId] 
					, [lots].[lot_no] AS [LotNo]
					, [m_lots].[id] AS [MemberLotId] 
					, [m_lots].[lot_no] AS [MemberLotNo]
				FROM  [APCSProDB].[trans].[lot_combine]
				INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [lot_combine].[lot_id]
				INNER JOIN [APCSProDB].[trans].[lots] AS [m_lots] ON [m_lots].[id] = [lot_combine].[member_lot_id]
				WHERE [lots].[lot_no] IN (SELECT [LotNo] FROM @table2)
					AND SUBSTRING([m_lots].[lot_no],5,1) <> 'D'
			)
			BEGIN
				----------------------------------------------------------------------------------------------------------
				--//set data to @table
				INSERT INTO @table 
				(
					[LotId],
					[LotNo],
					[Floor]
				)
				SELECT [m_lots].[id] AS [LotId]
					, [m_lots].[lot_no] AS [LotNo]
					, @Counter AS [Floor]
				FROM  [APCSProDB].[trans].[lot_combine]
				INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [lot_combine].[lot_id]
				INNER JOIN [APCSProDB].[trans].[lots] AS [m_lots] ON [m_lots].[id] = [lot_combine].[member_lot_id]
				WHERE [lots].[lot_no] IN (SELECT [LotNo] FROM @table2)
					AND [lots].[id] != [m_lots].[id]
					AND SUBSTRING([m_lots].[lot_no],5,1) <> 'D';

				DELETE FROM @table2;
				----------------------------------------------------------------------------------------------------------
			END
			ELSE
			BEGIN
				------------------------------------------------------------------------------------------------------------
				INSERT INTO @tableD 
				(
					[LotId],
					[LotNo],
					[Floor]
				)
				SELECT [m_lots].[id] AS [LotId]
					, [m_lots].[lot_no] AS [LotNo]
					, @Counter AS [Floor]
				FROM  [APCSProDB].[trans].[lot_combine]
				INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [lot_combine].[lot_id]
				INNER JOIN [APCSProDB].[trans].[lots] AS [m_lots] ON [m_lots].[id] = [lot_combine].[member_lot_id]
				WHERE [lots].[lot_no] IN (SELECT [LotNo] FROM @table2)
					AND [lots].[id] != [m_lots].[id];

				DELETE FROM @table2;
				INSERT INTO @table2 ([LotNo])
				SELECT [LotNo] FROM @tableD;
		
				DELETE FROM @tableD;

				IF EXISTS (SELECT [LotNo] FROM @table2)
				BEGIN
					SET @CounterTotal = @CounterTotal + 1;
				END
			END
			----------------------------------------------------------------------------------------------------------
			SET @Counter = @Counter  + 1;
		END

		IF EXISTS(SELECT * FROM @table)
		BEGIN
			SELECT CASE WHEN (CAST([ASSY_SYMBOL_1] AS VARCHAR(MAX)) != [ASSY_SYMBOL_1]) THEN '' ELSE [ASSY_SYMBOL_1] END
					+ CASE WHEN (CAST([ASSY_SYMBOL_2] AS VARCHAR(MAX)) != [ASSY_SYMBOL_2]) THEN '' ELSE [ASSY_SYMBOL_2] END
					+ CASE WHEN (CAST([ASSY_SYMBOL_3] AS VARCHAR(MAX)) != [ASSY_SYMBOL_3]) THEN '' ELSE [ASSY_SYMBOL_3] END
					+ CASE WHEN (CAST([ASSY_SYMBOL_4] AS VARCHAR(MAX)) != [ASSY_SYMBOL_4]) THEN '' ELSE [ASSY_SYMBOL_4] END
					+ CASE WHEN (CAST([ASSY_SYMBOL_5] AS VARCHAR(MAX)) != [ASSY_SYMBOL_5]) THEN '' ELSE [ASSY_SYMBOL_5] END
					+ CASE WHEN (CAST([ASSY_SYMBOL_6] AS VARCHAR(MAX)) != [ASSY_SYMBOL_6]) THEN '' ELSE [ASSY_SYMBOL_6] END AS [mark]
				, [temp].[LotNo] AS [lot_no]
				, CASE WHEN (CAST([ASSY_SYMBOL_1] AS VARCHAR(MAX)) != [ASSY_SYMBOL_1]) THEN 1 ELSE 0 END
					+ CASE WHEN (CAST([ASSY_SYMBOL_2] AS VARCHAR(MAX)) != [ASSY_SYMBOL_2]) THEN 1 ELSE 0 END
					+ CASE WHEN (CAST([ASSY_SYMBOL_3] AS VARCHAR(MAX)) != [ASSY_SYMBOL_3]) THEN 1 ELSE 0 END
					+ CASE WHEN (CAST([ASSY_SYMBOL_4] AS VARCHAR(MAX)) != [ASSY_SYMBOL_4]) THEN 1 ELSE 0 END
					+ CASE WHEN (CAST([ASSY_SYMBOL_5] AS VARCHAR(MAX)) != [ASSY_SYMBOL_5]) THEN 1 ELSE 0 END
					+ CASE WHEN (CAST([ASSY_SYMBOL_6] AS VARCHAR(MAX)) != [ASSY_SYMBOL_6]) THEN 1 ELSE 0 END AS [logo_mark]
			FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] AS [denpyo] WITH (NOLOCK) 
			INNER JOIN @table AS [temp] ON [denpyo].[LOT_NO_2] = [temp].[LotNo]
		END
		ELSE
		BEGIN
			SELECT 'NO MARK DATA' AS [mark]
				, @MemberLotNo AS [lot_no]
				, 0 AS [logo_mark]
		END
	END
	ELSE
	BEGIN
		SELECT NULL AS [mark]
			, NULL AS [lot_no]
			, NULL AS [logo_mark]
		FROM @table
	END
	----------------------------------------------------------------------------------------------------------
END
