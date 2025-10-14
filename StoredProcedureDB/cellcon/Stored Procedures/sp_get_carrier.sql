-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_carrier]
	-- Add the parameters for the stored procedure here
	@job varchar(30)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
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
		,'EXEC [cellcon].[sp_get_carrier] @job = '''+ @job + ''''
	--if (@job in ('FL','TP','AUTO(1)','AUTO(2)','AUTO(3)','AUTO(4)'))
   --if (@job in ('FL','FL(OS1)','T/C','BAKE','MP','AGING','REFLOW1','REFLOW2','DB1','WB','WB1','WB2','DBCure'))
	if (@job in ('DB M.BARI100%INS','DB 100%INS','WB 100%INS','Marker','Solder Test','ＨＯＮＩＮＧ	','HONING','TCY','FL','FL(OS1)','T/C','BAKE','MP','AGING','REFLOW','REFLOW1','REFLOW2','REFLOW3','REFLOW4','WB','WB1','WB2','DBCure','PL','DEFL','FLFT','AUTO X-RAY100%','FLFTTP','PLASMA','PLASMA1','PLASMA2','CD','CD1','CD2','DB','DB1','DB1(2)','DB1(3)','LASER','DETAPE','MOUNT TAPE','SAMPLING X RAY','BAKE BEFORE FL','100% INSP.','TP','AUTO(1)','AUTO(2)','GO/NGSampleJudge','AUTO(3)','AUTO(4)','AUTO(5)','LEAD SCANNER','AUTO(2)ASISAMPLE','AUTO(3)ASISAMPLE','AGING IN'
	,'PKG DICER','PKG･MOUNT','OS+AUTO(1)','AUTO(1)','STICK LABEL','ＷＢ．ＩＮＳ','SAMPLING INSP','100% X RAY','HOT O/S','FL 100% INSP.','FT-TP', 'AUTO(2) AFTER','FT 100%INSP','HORNING','TP Rework','X-RAY Period Check','OS+FT-TP','O/S Over Sample Test'
	,'AUTO(1) SBLSYL','AUTO(2) SBLSYL','AUTO(3) SBLSYL','AUTO(4) SBLSYL','AUTO(5) SBLSYL','FT-TP SBLSYL','ＤＣ'
	,'AUTO(1) BIN27', 'AUTO(1) Bin27-CF', 'AUTO(3) BIN27','AUTO(3) Bin27-CF', 'AUTO(1) RE', 'OS', '100% B/I','REEL REWORK','Manual Rework', 'Lot Matching','TP-TP','TRAY-TUBE CHANGE','OS+FT-TP SBLSYL', 'AUTO(1) HV', 'OS+AUTO(2)','OS+AUTO(1)SBLSYL','OS+AUTO(1) HV','TP 100%INSP')) --'DB2','DB3','DB4','DB2(3)','DB2(6)','DB3(6)'
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
