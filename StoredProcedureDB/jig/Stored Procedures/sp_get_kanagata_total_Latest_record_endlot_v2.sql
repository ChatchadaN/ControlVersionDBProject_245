-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_kanagata_total_Latest_record_endlot_v2]
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

	(SELECT DISTINCT APCSProDB.jig.production_counters.warn_value
	 FROM  APCSProDB.jig.productions INNER JOIN
           APCSProDB.jig.production_counters ON APCSProDB.jig.productions.id = APCSProDB.jig.production_counters.production_id INNER JOIN
           APCSProDB.trans.jigs ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%TIE Bar Punch%')) AS STD_TIEBarPunch


	,(SELECT DISTINCT APCSProDB.jig.production_counters.warn_value
	 FROM  APCSProDB.jig.productions INNER JOIN
           APCSProDB.jig.production_counters ON APCSProDB.jig.productions.id = APCSProDB.jig.production_counters.production_id INNER JOIN
           APCSProDB.trans.jigs ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%TIE Bar Die%')) AS STD_TIEBarDie


	,(SELECT DISTINCT APCSProDB.jig.production_counters.warn_value
	 FROM  APCSProDB.jig.productions INNER JOIN
           APCSProDB.jig.production_counters ON APCSProDB.jig.productions.id = APCSProDB.jig.production_counters.production_id INNER JOIN
           APCSProDB.trans.jigs ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Curve Punch%')) AS STD_CurvePunch


	,(SELECT DISTINCT APCSProDB.jig.production_counters.warn_value
	 FROM  APCSProDB.jig.productions INNER JOIN
           APCSProDB.jig.production_counters ON APCSProDB.jig.productions.id = APCSProDB.jig.production_counters.production_id INNER JOIN
           APCSProDB.trans.jigs ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Lead Cut Punch%')) AS STD_LeadCutPunch


	,(SELECT DISTINCT APCSProDB.jig.production_counters.warn_value
	 FROM  APCSProDB.jig.productions INNER JOIN
           APCSProDB.jig.production_counters ON APCSProDB.jig.productions.id = APCSProDB.jig.production_counters.production_id INNER JOIN
           APCSProDB.trans.jigs ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Guide Post%')) AS STD_GuidePost


	,(SELECT DISTINCT APCSProDB.jig.production_counters.warn_value
	 FROM  APCSProDB.jig.productions INNER JOIN
           APCSProDB.jig.production_counters ON APCSProDB.jig.productions.id = APCSProDB.jig.production_counters.production_id INNER JOIN
           APCSProDB.trans.jigs ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Guide Bushu%')) AS STD_GuideBushu


	,(SELECT DISTINCT APCSProDB.jig.production_counters.warn_value
	 FROM  APCSProDB.jig.productions INNER JOIN
           APCSProDB.jig.production_counters ON APCSProDB.jig.productions.id = APCSProDB.jig.production_counters.production_id INNER JOIN
           APCSProDB.trans.jigs ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Lead Die%')) AS STD_LeadDie


	,(SELECT DISTINCT APCSProDB.jig.production_counters.warn_value
	 FROM  APCSProDB.jig.productions INNER JOIN
           APCSProDB.jig.production_counters ON APCSProDB.jig.productions.id = APCSProDB.jig.production_counters.production_id INNER JOIN
           APCSProDB.trans.jigs ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Lead Die(External)%')) AS STD_LeadDieEX


	,(SELECT DISTINCT APCSProDB.jig.production_counters.warn_value
	 FROM  APCSProDB.jig.productions INNER JOIN
           APCSProDB.jig.production_counters ON APCSProDB.jig.productions.id = APCSProDB.jig.production_counters.production_id INNER JOIN
           APCSProDB.trans.jigs ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Support Punch%')) AS STD_SupportPunch


	,(SELECT DISTINCT APCSProDB.jig.production_counters.warn_value
	 FROM  APCSProDB.jig.productions INNER JOIN
           APCSProDB.jig.production_counters ON APCSProDB.jig.productions.id = APCSProDB.jig.production_counters.production_id INNER JOIN
           APCSProDB.trans.jigs ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Support Die%')) AS STD_SupportDie


	,(SELECT DISTINCT APCSProDB.jig.production_counters.warn_value
	 FROM  APCSProDB.jig.productions INNER JOIN
           APCSProDB.jig.production_counters ON APCSProDB.jig.productions.id = APCSProDB.jig.production_counters.production_id INNER JOIN
           APCSProDB.trans.jigs ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Fin Cut Punch%')) AS STD_FinCutPunch


	,(SELECT DISTINCT APCSProDB.jig.production_counters.warn_value
	 FROM  APCSProDB.jig.productions INNER JOIN
           APCSProDB.jig.production_counters ON APCSProDB.jig.productions.id = APCSProDB.jig.production_counters.production_id INNER JOIN
           APCSProDB.trans.jigs ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Fin Cut Die%')) AS STD_FinCutDie


	,(SELECT DISTINCT APCSProDB.jig.production_counters.warn_value
	 FROM  APCSProDB.jig.productions INNER JOIN
           APCSProDB.jig.production_counters ON APCSProDB.jig.productions.id = APCSProDB.jig.production_counters.production_id INNER JOIN
           APCSProDB.trans.jigs ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Cum%')) AS STD_Cum


	,(SELECT DISTINCT APCSProDB.jig.production_counters.warn_value
	 FROM  APCSProDB.jig.productions INNER JOIN
           APCSProDB.jig.production_counters ON APCSProDB.jig.productions.id = APCSProDB.jig.production_counters.production_id INNER JOIN
           APCSProDB.trans.jigs ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Die Block%')) AS STD_DieBlock


	,(SELECT DISTINCT APCSProDB.jig.production_counters.warn_value
	 FROM  APCSProDB.jig.productions INNER JOIN
           APCSProDB.jig.production_counters ON APCSProDB.jig.productions.id = APCSProDB.jig.production_counters.production_id INNER JOIN
           APCSProDB.trans.jigs ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Flash Punch%')) AS STD_FlashPunch


	,(SELECT DISTINCT APCSProDB.jig.production_counters.warn_value
	 FROM  APCSProDB.jig.productions INNER JOIN
           APCSProDB.jig.production_counters ON APCSProDB.jig.productions.id = APCSProDB.jig.production_counters.production_id INNER JOIN
           APCSProDB.trans.jigs ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = @jig_id and root_jig_id <> jigs.id and name like ('%Sub Gate Punch%')) AS STD_SubGatePunch
END