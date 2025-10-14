-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_cru_comment_make]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128),
	@COMMENT	NVARCHAR(max)

AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @COMMENT_ID INT
	DECLARE @CMD_TEXT NVARCHAR(MAX) = '';
	DECLARE @CMD_PARA NVARCHAR(MAX) = '';

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N'	' + '@COMMENT_ID = CM.id ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.comments as CM ';
	SET @CMD_TEXT += N'where CM.val = ''' + @COMMENT +''' ';

	SET @CMD_PARA = N'@COMMENT_ID INT OUTPUT';
	EXECUTE sp_executesql @CMD_TEXT, @CMD_PARA, @COMMENT_ID OUTPUT

	IF @COMMENT_ID is not null
		BEGIN 
			SET @CMD_TEXT  = N'';
			SET @CMD_TEXT += N'select ';
			SET @CMD_TEXT += N' ''' + CONVERT(varchar,@COMMENT_ID) + ''' as CURRENT_NUM ';
			EXECUTE(@CMD_TEXT)

			RETURN @COMMENT_ID
		END
	ELSE
		BEGIN
			EXECUTE  @COMMENT_ID = stripmap.sp_cru_countup_numbers @DATABASE_NAME=@DATABASE_NAME, @ID_NAME='comments.id', @UP_NUM=1,@SCHEMA_NAME='trans'

			SET @CMD_TEXT  = N'';
			SET @CMD_TEXT += N'insert ';
			SET @CMD_TEXT += N' ' + @DATABASE_NAME + '.trans.comments ';
			SET @CMD_TEXT += N'( ';
			SET @CMD_TEXT += N' ' + 'id, ';
			SET @CMD_TEXT += N' ' + 'val ';
			SET @CMD_TEXT += N') ';
			SET @CMD_TEXT += N'select ';
			SET @CMD_TEXT += N' ' + CONVERT(varchar,@COMMENT_ID) + ', ';
			SET @CMD_TEXT += N' ''' + @COMMENT + ''' ';
			EXECUTE(@CMD_TEXT)

			RETURN @COMMENT_ID
		END
END
