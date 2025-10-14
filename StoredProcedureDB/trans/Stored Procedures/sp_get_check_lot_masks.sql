
CREATE PROCEDURE [trans].[sp_get_check_lot_masks]
	-- Add the parameters for the stored procedure here
	@LotNo VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [Mark].[lot_no]
		, [lot_masks].[mno] AS mno_cur
		, [package]
		, [device]
		, [FT_SYMBOL_1] 
		, [FT_SYMBOL_2] 
		, [FT_SYMBOL_3] 
		, [FT_SYMBOL_4] 
		, [FT_SYMBOL_5] 
		, [FT_SYMBOL_6] 
		, [member_lot_no]
		, [MEM_FT_SYMBOL_1]
		, [MEM_FT_SYMBOL_2]
		, [MEM_FT_SYMBOL_3]
		, [MEM_FT_SYMBOL_4]
		, [MEM_FT_SYMBOL_5]
		, [MEM_FT_SYMBOL_6]
		, [Mark].[mno]
	FROM (
		SELECT [surpluses].[serial_no] AS [lot_no]
			, [packages].[name] AS [package]
			, [device_names].[name] AS [device]
			, [denpyo].[FT_SYMBOL_1] 
			, [denpyo].[FT_SYMBOL_2] 
			, [denpyo].[FT_SYMBOL_3] 
			, [denpyo].[FT_SYMBOL_4] 
			, [denpyo].[FT_SYMBOL_5] 
			, [denpyo].[FT_SYMBOL_6] 
			, (CASE 
				WHEN [lot_member].[lot_no] IS NOT NULL THEN [lot_member].[lot_no] 
				ELSE '-' 
			END) AS [member_lot_no]
			, [denpyo_2].[FT_SYMBOL_1] AS [MEM_FT_SYMBOL_1]
			, [denpyo_2].[FT_SYMBOL_2] AS [MEM_FT_SYMBOL_2]
			, [denpyo_2].[FT_SYMBOL_3] AS [MEM_FT_SYMBOL_3]
			, [denpyo_2].[FT_SYMBOL_4] AS [MEM_FT_SYMBOL_4]
			, [denpyo_2].[FT_SYMBOL_5] AS [MEM_FT_SYMBOL_5]
			, [denpyo_2].[FT_SYMBOL_6] AS [MEM_FT_SYMBOL_6]
			, [lot_masks1].[mno]
			, (CASE 
				WHEN [denpyo].[LOT_NO_2] IS NOT NULL THEN 1
				WHEN [denpyo_2].[LOT_NO_2] IS NOT NULL THEN 1
				WHEN [lot_masks1].[mno] IS NOT NULL THEN 1
				ELSE 0
			END) AS [state]
		FROM [APCSProDB].[trans].[surpluses]
		LEFT JOIN [APCSProDB].[trans].[lots] AS [lot_master] ON [surpluses].[lot_id] = [lot_master].[id]
		LEFT JOIN [APCSProDB].[method].[device_names] ON [lot_master].[act_device_name_id] = [device_names].[id]
		LEFT JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
		LEFT JOIN [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] AS [denpyo] ON [surpluses].[serial_no] = [denpyo].[LOT_NO_2]
			AND ([surpluses].[serial_no] LIKE '____A____V'
				OR [surpluses].[serial_no] LIKE '____F____V'
				OR [surpluses].[serial_no] LIKE '____E____V'
				OR [surpluses].[serial_no] LIKE '____G____V')
		LEFT JOIN [APCSProDB].[trans].[lot_combine] ON [surpluses].[lot_id] = [lot_combine].[lot_id]
			AND [lot_combine].[lot_id] != [lot_combine].[member_lot_id]
		LEFT JOIN [APCSProDB].[trans].[lots] AS [lot_member] ON [lot_combine].[member_lot_id] = [lot_member].[id]
		LEFT JOIN [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] AS [denpyo_2] ON [lot_member].[lot_no] = [denpyo_2].[LOT_NO_2]
			AND ([lot_member].[lot_no] LIKE '____A____V'
				OR [lot_member].[lot_no] LIKE '____F____V'
				OR [lot_member].[lot_no] LIKE '____E____V'
				OR [lot_member].[lot_no] LIKE '____G____V')
		LEFT JOIN [APIStoredProDB].[dbo].[lot_masks] AS [lot_masks1] ON [lot_member].[lot_no] = [lot_masks1].[lot_no]
		WHERE [lot_master].[lot_no] = @LotNo
	) AS [Mark]
	LEFT JOIN [APIStoredProDB].[dbo].[lot_masks] ON [Mark].[lot_no] = [lot_masks].[lot_no]
	WHERE [Mark].[lot_no] NOT LIKE '____A____V'
		AND [Mark].[lot_no] NOT LIKE '____F____V'
		AND [Mark].[lot_no] NOT LIKE '____E____V'
		AND [Mark].[lot_no] NOT LIKE '____G____V'
	ORDER BY [lot_no] ASC;
END
