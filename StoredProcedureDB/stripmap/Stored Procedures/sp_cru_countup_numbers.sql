-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_cru_countup_numbers]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128),
	@ID_NAME varchar(30),
	@UP_NUM INT,
	@SCHEMA_NAME varchar(30)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @CMD_TEXT NVARCHAR(MAX) = '';
	DECLARE @CMD_PARA NVARCHAR(MAX) = '';
	DECLARE @CURRENT_NUM INT

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N'	' + '@CURRENT_NUM = NU.id ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.' + @SCHEMA_NAME + '.numbers as NU ';
	SET @CMD_TEXT += N'where NU.name = ''' + @ID_NAME + ''' ';

	SET @CMD_PARA = N'@CURRENT_NUM INT OUTPUT';
	EXECUTE sp_executesql @CMD_TEXT, @CMD_PARA, @CURRENT_NUM OUTPUT

	IF @CURRENT_NUM is NULL
		BEGIN
			SET @CMD_TEXT  = N'';
			SET @CMD_TEXT += N'insert ';
			SET @CMD_TEXT += N'	' + @DATABASE_NAME + '.' + @SCHEMA_NAME + '.numbers(id, name) ';
			SET @CMD_TEXT += N'select ';
			SET @CMD_TEXT += N' ' + CONVERT(varchar,@UP_NUM) + ', ''' + @ID_NAME + ''' ';
			EXECUTE(@CMD_TEXT)

			SET @CURRENT_NUM = @UP_NUM
		END
	ELSE
		BEGIN
			SET @CMD_TEXT  = N'';
			SET @CMD_TEXT += N'update ';
			SET @CMD_TEXT += N'NU SET ';
			SET @CMD_TEXT += N'	' + 'NU.id = NU.id + ' + CONVERT(varchar,@UP_NUM) + ' ';
			SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.' + @SCHEMA_NAME + '.numbers as NU ';
			SET @CMD_TEXT += N'where NU.name = ''' + @ID_NAME + ''' ';
			EXECUTE(@CMD_TEXT)

			SET @CURRENT_NUM = @CURRENT_NUM + @UP_NUM
		END

    SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N' ''' + CONVERT(varchar,@CURRENT_NUM) + ''' as CURRENT_NUM ';
	EXECUTE(@CMD_TEXT)

	return @CURRENT_NUM
END
