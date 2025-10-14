-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_frame_control]
	-- Add the parameters for the stored procedure here
	@job varchar(30)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		DECLARE @enabled bit,@message varchar(50)
    -- Insert statements for procedure here
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [cellcon].[sp_get_frame_control] @job = '''+ @job + ''''

	if (@job not in ('FL', 'ＦＬ', 'FT-TP', 'TP', 'FL(OS1)', 'LEAD SCANNER', 'OUT GOING INSP', 'TP Rework', '100% B/I', 'REEL REWORK', 'Manual Rework', 'OS', 'Lot Matching', 'TP-TP', 'OUT GOING', 'TRAY-TUBE CHANGE'

					--FT
					, 'GO/NGSampleJudge', 'FLFT', 'FLFTTP', 'OS+FT-TP'
					, 'AUTO(1)', 'AUTO(2)', 'AUTO(3)', 'AUTO(4)', 'AUTO(5)', 'OS+AUTO(1)'
					, 'AUTO(2)ASISAMPLE', 'AUTO(3)ASISAMPLE'
					, 'AUTO(1) SBLSYL', 'AUTO(2) SBLSYL', 'AUTO(3) SBLSYL', 'AUTO(4) SBLSYL', 'AUTO(5) SBLSYL', 'FT-TP SBLSYL' ,'100% INSP.'
					, 'AUTO(1) BIN27-CF', 'AUTO(1) BIN27', 'AUTO(3) BIN27-CF', 'AUTO(3) BIN27', 'AUTO(1) RE','OS+FT-TP SBLSYL', 'AUTO(1) HV', 'OS+AUTO(2)','TP 100%INSP'))
	BEGIN
		SET @enabled = '1'
		SET @message = 'JOB => ' + @job + ' is enabled'
	END
	ELSE
	BEGIN
		SET @enabled = '0'
		SET @message = 'JOB => ' + @job + ' is disabled'
	END
	SELECT @enabled as [enabled] ,@message as [message]
END