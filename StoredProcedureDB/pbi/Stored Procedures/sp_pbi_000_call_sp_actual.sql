


-- =============================================
-- Author:		<A.Kosato>
-- Create date: <12th Oct 2018>
-- Description:	<LOT1_TABLE to Lots>
-- =============================================
CREATE PROCEDURE [pbi].[sp_pbi_000_call_sp_actual] (
	@ServerName_APCSPro NVARCHAR(128) = ''
    ,@DatabaseName_APCSPro NVARCHAR(128) = 'APCSProDB'
	,@ServerName_APCSProDWH NVARCHAR(128)  = ''
    ,@DatabaseName_APCSProDWH NVARCHAR(128) = 'APCSProDWH'
	,@StartDay DATE = NULL
	,@EndDay DATE = NULL
	,@logtext NVARCHAR(max) output
	,@errnum  int output
	,@errline int output
	,@errmsg nvarchar(max) output
	) AS
BEGIN

    ---------------------------------------------------------------------------
	--(1) declare
    ---------------------------------------------------------------------------
	DECLARE @return_value int = -1

   ---------------------------------------------------------------------------
	--(3) main script
   ---------------------------------------------------------------------------	
   
   Delete APCSProDWH.pbi.factory_data   
   
   EXEC	@return_value = [pbi].[sp_pbi_001_act_operation_time]
   	@ServerName_APCSPro = @ServerName_APCSPro,
    @DatabaseName_APCSPro = @DatabaseName_APCSPro,
	@ServerName_APCSProDWH = @ServerName_APCSProDWH,
    @DatabaseName_APCSProDWH = @DatabaseName_APCSProDWH,
	@StartDay = @StartDay,
	@EndDay = @EndDay,
	@logtext = @logtext OUTPUT,
	@errnum = @errnum OUTPUT,
	@errline = @errline OUTPUT,
	@errmsg = @errmsg OUTPUT
   SELECT	@logtext as N'@logtext',
			@errnum as N'@errnum',
			@errline as N'@errline',
			@errmsg as N'@errmsg'

   EXEC	@return_value = [pbi].[sp_pbi_002_production_in]
   	@ServerName_APCSPro = @ServerName_APCSPro,
    @DatabaseName_APCSPro = @DatabaseName_APCSPro,
	@ServerName_APCSProDWH = @ServerName_APCSProDWH,
    @DatabaseName_APCSProDWH = @DatabaseName_APCSProDWH,
	@StartDay = @StartDay,
	@EndDay = @EndDay,
	@logtext = @logtext OUTPUT,
	@errnum = @errnum OUTPUT,
	@errline = @errline OUTPUT,
	@errmsg = @errmsg OUTPUT
   SELECT	@logtext as N'@logtext',
			@errnum as N'@errnum',
			@errline as N'@errline',
			@errmsg as N'@errmsg'

   EXEC	@return_value = [pbi].[sp_pbi_003_production_out]
   	@ServerName_APCSPro = @ServerName_APCSPro,
    @DatabaseName_APCSPro = @DatabaseName_APCSPro,
	@ServerName_APCSProDWH = @ServerName_APCSProDWH,
    @DatabaseName_APCSProDWH = @DatabaseName_APCSProDWH,
	@StartDay = @StartDay,
	@EndDay = @EndDay,
	@logtext = @logtext OUTPUT,
	@errnum = @errnum OUTPUT,
	@errline = @errline OUTPUT,
	@errmsg = @errmsg OUTPUT
   SELECT	@logtext as N'@logtext',
			@errnum as N'@errnum',
			@errline as N'@errline',
			@errmsg as N'@errmsg'

   EXEC	@return_value = [pbi].[sp_pbi_004_production_og]
   	@ServerName_APCSPro = @ServerName_APCSPro,
    @DatabaseName_APCSPro = @DatabaseName_APCSPro,
	@ServerName_APCSProDWH = @ServerName_APCSProDWH,
    @DatabaseName_APCSProDWH = @DatabaseName_APCSProDWH,
	@StartDay = @StartDay,
	@EndDay = @EndDay,
	@logtext = @logtext OUTPUT,
	@errnum = @errnum OUTPUT,
	@errline = @errline OUTPUT,
	@errmsg = @errmsg OUTPUT
   SELECT	@logtext as N'@logtext',
			@errnum as N'@errnum',
			@errline as N'@errline',
			@errmsg as N'@errmsg'

   EXEC	@return_value = [pbi].[sp_pbi_005_wip]
   	@ServerName_APCSPro = @ServerName_APCSPro,
    @DatabaseName_APCSPro = @DatabaseName_APCSPro,
	@ServerName_APCSProDWH = @ServerName_APCSProDWH,
    @DatabaseName_APCSProDWH = @DatabaseName_APCSProDWH,
	@StartDay = @StartDay,
	@EndDay = @EndDay,
	@logtext = @logtext OUTPUT,
	@errnum = @errnum OUTPUT,
	@errline = @errline OUTPUT,
	@errmsg = @errmsg OUTPUT
   SELECT	@logtext as N'@logtext',
			@errnum as N'@errnum',
			@errline as N'@errline',
			@errmsg as N'@errmsg'

   EXEC	@return_value = [pbi].[sp_pbi_006_gothrough_ratio]
   	@ServerName_APCSPro = @ServerName_APCSPro,
    @DatabaseName_APCSPro = @DatabaseName_APCSPro,
	@ServerName_APCSProDWH = @ServerName_APCSProDWH,
    @DatabaseName_APCSProDWH = @DatabaseName_APCSProDWH,
	@StartDay = @StartDay,
	@EndDay = @EndDay,
	@logtext = @logtext OUTPUT,
	@errnum = @errnum OUTPUT,
	@errline = @errline OUTPUT,
	@errmsg = @errmsg OUTPUT
   SELECT	@logtext as N'@logtext',
			@errnum as N'@errnum',
			@errline as N'@errline',
			@errmsg as N'@errmsg'

   EXEC	@return_value = [pbi].[sp_pbi_007_update]
   	@ServerName_APCSPro = @ServerName_APCSPro,
    @DatabaseName_APCSPro = @DatabaseName_APCSPro,
	@ServerName_APCSProDWH = @ServerName_APCSProDWH,
    @DatabaseName_APCSProDWH = @DatabaseName_APCSProDWH,
	@logtext = @logtext OUTPUT,
	@errnum = @errnum OUTPUT,
	@errline = @errline OUTPUT,
	@errmsg = @errmsg OUTPUT
   SELECT	@logtext as N'@logtext',
			@errnum as N'@errnum',
			@errline as N'@errline',
			@errmsg as N'@errmsg'

RETURN 0;

END ;
