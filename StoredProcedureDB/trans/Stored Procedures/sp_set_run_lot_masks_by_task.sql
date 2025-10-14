
CREATE PROCEDURE [trans].[sp_set_run_lot_masks_by_task]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @r_lot_no VARCHAR(10) 

	DECLARE cursor_r_lot_no CURSOR FOR
	SELECT [lots].[lot_no]
	FROM [APCSProDB].[trans].[lots]
	LEFT JOIN [APIStoredProDB].[dbo].[lot_masks] ON [lots].[lot_no] = [lot_masks].[lot_no]
	LEFT JOIN [APCSProDB].[trans].[surpluses] ON [lots].[lot_no] = [surpluses].[serial_no]
	LEFT JOIN [APCSProDB].[method].[packages] ON [lots].[act_package_id] = [packages].[id]
	CROSS APPLY (
		SELECT TOP 1 [Package] FROM [StoredProcedureDB].[dbo].[config_lot_marks]
		WHERE [Package] = [packages].[name]
			AND [IsEnabled] = 1
	) AS table_config
	WHERE [lots].[lot_no] LIKE '____D____V'
		AND [lots].[wip_state] = 20
		AND [lot_masks].[lot_no] IS NULL
		AND [surpluses].[in_stock] IS NOT NULL

	OPEN cursor_r_lot_no
	FETCH NEXT FROM cursor_r_lot_no
	INTO @r_lot_no
		
	WHILE (@@FETCH_STATUS = 0) -- @@FETCH_STATUS -1 End, 0 Loop 
	BEGIN
		EXEC [StoredProcedureDB].[trans].[sp_set_lot_masks_by_task] @LotNo = @r_lot_no;
		-- Next cursor
		FETCH NEXT FROM cursor_r_lot_no -- Fetch next cursor
		INTO @r_lot_no  
	END

	CLOSE cursor_r_lot_no; 
	DEALLOCATE cursor_r_lot_no; 
END
