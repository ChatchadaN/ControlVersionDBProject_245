-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_jig_onmachine] 
	-- Add the parameters for the stored procedure here
	@MCNo AS VARCHAR(50) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT        APCSProDB.mc.machines.name AS MCNo, 
				  APCSProDB.trans.machine_jigs.jig_id, 
				  APCSProDB.trans.jigs.barcode, 
				  APCSProDB.trans.jigs.smallcode, 
				  APCSProDB.trans.jigs.qrcodebyuser, 
				  APCSProDB.trans.jigs.status, 
				  APCSProDB.jig.productions.name AS SubType,
				  APCSProDB.jig.categories.name AS Type,
				  categories.short_name,
				  APCSProDB.method.processes.name AS Process, 
				  APCSProDB.trans.jig_conditions.value AS LifeTime,
				  APCSProDB.mc.machines.id AS MC_ID,
				  APCSProDB.jig.productions.expiration_value AS STD_LifeTime
	FROM        APCSProDB.mc.machines INNER JOIN
                         APCSProDB.trans.machine_jigs ON APCSProDB.mc.machines.id = APCSProDB.trans.machine_jigs.machine_id INNER JOIN
                         APCSProDB.trans.jigs ON APCSProDB.trans.machine_jigs.jig_id = APCSProDB.trans.jigs.id INNER JOIN
                         APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
                         APCSProDB.jig.categories ON APCSProDB.jig.productions.category_id = APCSProDB.jig.categories.id INNER JOIN
                         APCSProDB.method.processes ON APCSProDB.jig.categories.lsi_process_id = APCSProDB.method.processes.id INNER JOIN
                         APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id
	WHERE APCSProDB.mc.machines.name = @MCNo AND status = 'On Machine'
END
