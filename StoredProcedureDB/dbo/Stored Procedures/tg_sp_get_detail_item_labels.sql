-- =============================================
-- Author:		<null>
-- Create date: <02/08/2022>
-- Description:	<update monitoring items and insert monitoring items records>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_detail_item_labels] 
	@dbname VARCHAR(100),
    @schema VARCHAR(100), 
	@name VARCHAR(100), 
	@val VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
	DECLARE @sqltmp NVARCHAR(MAX) = '';
	DECLARE @sqltable TABLE (
		[name] VARCHAR(50)
	);

	SET @sqltmp = N'';
	SET @sqltmp += N'SELECT ';
	SET @sqltmp += N'	[item_l].[label_eng] AS [name] ';
	SET @sqltmp += N'FROM [' + @dbname + '].[' + @schema + '].[item_labels] AS [item_l] with (NOLOCK) ';
	SET @sqltmp += N'WHERE [item_l].[name] = ''' + @name + ''' ';
	SET @sqltmp += N'	AND [item_l].[val] = ''' + @val + '''; ';
	
	BEGIN TRY
		INSERT INTO @sqltable
		EXECUTE (@sqltmp);
	END TRY
	BEGIN CATCH
		
	END CATCH

	IF NOT EXISTS (SELECT [name] FROM @sqltable)
	BEGIN
		SELECT IIF(@name = 'lots.pc_instruction_code', 'Normal', 'Not Found') AS [name];
	END
	ELSE 
	BEGIN
		SELECT [name] 
		FROM @sqltable;
	END
END
