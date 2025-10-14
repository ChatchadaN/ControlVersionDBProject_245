-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_kanagata_total_standard_record_endlot_v1]
	-- Add the parameters for the stored procedure here
		@KanagataName as varchar(50) ='%'

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT Top(1)

	(SELECT  DISTINCT productions.expiration_value
	FROM APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = (select id from APCSProDB.trans.jigs where qrcodebyuser = @KanagataName) and root_jig_id <> jigs.id and name like ('%TIE Bar Cut Punch%')) AS STD_TIEBarCutPunch


	,(SELECT  DISTINCT productions.expiration_value
	FROM  APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = (select id from APCSProDB.trans.jigs where qrcodebyuser = @KanagataName) and root_jig_id <> jigs.id and name like ('%TIE Bar Cut Die')) AS STD_TIEBarCutDie



	,(SELECT  DISTINCT productions.expiration_value
	FROM  APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = (select id from APCSProDB.trans.jigs where qrcodebyuser = @KanagataName) and root_jig_id <> jigs.id and name like ('%Support Die')) AS STD_SupportDie


	,(SELECT  DISTINCT productions.expiration_value
	FROM  APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = (select id from APCSProDB.trans.jigs where qrcodebyuser = @KanagataName) and root_jig_id <> jigs.id and name like ('%Support Punch%')) AS STD_SupportPunch


	,(SELECT  DISTINCT productions.expiration_value
	FROM  APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = (select id from APCSProDB.trans.jigs where qrcodebyuser = @KanagataName) and root_jig_id <> jigs.id and name like ('%Flash Punch%')) AS STD_FlashPunch


	,(SELECT  DISTINCT productions.expiration_value
	FROM  APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = (select id from APCSProDB.trans.jigs where qrcodebyuser = @KanagataName) and root_jig_id <> jigs.id and name like ('%Gate Cut Punch%')) AS STD_GateCutPunch


	,(SELECT  DISTINCT productions.expiration_value
	FROM  APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = (select id from APCSProDB.trans.jigs where qrcodebyuser = @KanagataName) and root_jig_id <> jigs.id and name like ('%Frame Cut Punch%')) AS STD_FrameCutPunch


	,(SELECT  DISTINCT productions.expiration_value
	FROM  APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = (select id from APCSProDB.trans.jigs where qrcodebyuser = @KanagataName) and root_jig_id <> jigs.id and name like ('%Frame Cut Die%')) AS STD_FrameCutDie


	,(SELECT  DISTINCT productions.expiration_value
	FROM  APCSProDB.trans.jigs    INNER JOIN
		  APCSProDB.jig.productions ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id

	where root_jig_id = (select id from APCSProDB.trans.jigs where qrcodebyuser = @KanagataName) and root_jig_id <> jigs.id and name like ('%Stipper Guide%')) AS STD_StripperGuidePunch
END