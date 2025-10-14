-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_kanagata_total_standard_record_endlot]
	-- Add the parameters for the stored procedure here
		@KanagataName as varchar(50) ='%'

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

DECLARE @jig_id AS INT
SET @jig_id = (select id from APCSProDB.trans.jigs where qrcodebyuser = @KanagataName)

SELECT Top(1)

	(SELECT  DISTINCT production_counters.alarm_value
	FROM APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id INNER JOIN
		  APCSProDB.jig.production_counters on production_counters.production_id = productions.id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%TIE Bar Cut Punch%')) AS STD_TIEBarCutPunch


	,	(SELECT  DISTINCT production_counters.alarm_value
	FROM APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id INNER JOIN
		  APCSProDB.jig.production_counters on production_counters.production_id = productions.id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%TIE Bar Cut Die')) AS STD_TIEBarCutDie



	,	(SELECT  DISTINCT production_counters.alarm_value
	FROM APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id INNER JOIN
		  APCSProDB.jig.production_counters on production_counters.production_id = productions.id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Support Die')) AS STD_SupportDie


	,	(SELECT  DISTINCT production_counters.alarm_value
	FROM APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id INNER JOIN
		  APCSProDB.jig.production_counters on production_counters.production_id = productions.id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Support Punch%')) AS STD_SupportPunch


	,	(SELECT  DISTINCT production_counters.alarm_value
	FROM APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id INNER JOIN
		  APCSProDB.jig.production_counters on production_counters.production_id = productions.id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Flash Punch%')) AS STD_FlashPunch


	,	(SELECT  DISTINCT production_counters.alarm_value
	FROM APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id INNER JOIN
		  APCSProDB.jig.production_counters on production_counters.production_id = productions.id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Gate Cut Punch%')) AS STD_GateCutPunch


	,	(SELECT  DISTINCT production_counters.alarm_value
	FROM APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id INNER JOIN
		  APCSProDB.jig.production_counters on production_counters.production_id = productions.id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Frame Cut Punch%')) AS STD_FrameCutPunch


	,	(SELECT  DISTINCT production_counters.alarm_value
	FROM APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id INNER JOIN
		  APCSProDB.jig.production_counters on production_counters.production_id = productions.id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Frame Cut Die%')) AS STD_FrameCutDie


	,	(SELECT  DISTINCT production_counters.alarm_value
	FROM APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id INNER JOIN
		  APCSProDB.jig.production_counters on production_counters.production_id = productions.id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Stipper Guide%')) AS STD_StripperGuidePunch
END