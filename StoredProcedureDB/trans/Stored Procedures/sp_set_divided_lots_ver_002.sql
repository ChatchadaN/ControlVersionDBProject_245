
CREATE PROCEDURE [trans].[sp_set_divided_lots_ver_002]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10),
	@type_action INT --1: update create text ,2: update send text
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @lot_id INT
	
	IF (@type_action = 1)
	BEGIN
		SET @lot_id = (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no);

		IF (@lot_id IS NOT NULL)
		BEGIN
			UPDATE [APCSProDWH].[atom].[divided_lots]
			SET [divided_lots].[is_create_text] = 1
				, [updated_at] = GETDATE()
				, [updated_by] = 1339
			WHERE [lot_id] = @lot_id;

			------ # start insert data to is
			--DECLARE @sql VARCHAR(MAX) = '';
			--DECLARE @tablecheck TABLE (
			--	[LOT_NO] VARCHAR(10)
			--);

			--SET @sql += 'SELECT [LOT_NO] ';
			--SET @sql += 'FROM [ISDB].[DBLSISHT].[dbo].[LOT_DIVIDE] ';
			--SET @sql += 'WHERE [LOT_NO] = ''' + @lot_no + ''';';

			--INSERT INTO @tablecheck
			--EXEC(@sql);

			--IF NOT EXISTS (SELECT [LOT_NO] FROM @tablecheck)
			--BEGIN
			--	SET @sql = '';

			--	SET @sql += 'INSERT INTO [ISDB].[DBLSISHT].[dbo].[LOT_DIVIDE] ';
			--	SET @sql += '	( [LOT_NO] ';
			--	SET @sql += '	, [DATE_TIMESTAMP] ';
			--	SET @sql += '	, [FLAG] ) ';
			--	SET @sql += 'VALUES ';
			--	SET @sql += '	( ''' + @lot_no + ''' ';
			--	SET @sql += '	, ''' + FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss') + ''' ';
			--	SET @sql += '	, ''0'' ); ';

			--	EXEC(@sql);
			--END
			------ # end insert data to is
		END
	END
	ELSE IF (@type_action = 2)
	BEGIN
		SET @lot_id = (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no);

		IF (@lot_id IS NOT NULL)
		BEGIN
			UPDATE [APCSProDWH].[atom].[divided_lots]
			SET [divided_lots].[is_send_text] = 1
				, [updated_at] = GETDATE()
				, [updated_by] = 1339
			WHERE [lot_id] = @lot_id;
		END
	END
END
