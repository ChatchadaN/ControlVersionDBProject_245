
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_comments]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128)

AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @CMD_TEXT NVARCHAR(MAX) = '';

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select distinct ';
	SET @CMD_TEXT += N'	CM.val ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.lot_process_records as LPR with(nolock) ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.comments as CM with(nolock)on CM.id = LPR.qc_comment_id ';
	SET @CMD_TEXT += N'where LPR.record_class = 41 ';

	EXECUTE sp_executesql @CMD_TEXT

	RETURN @@ROWCOUNT
		
END
