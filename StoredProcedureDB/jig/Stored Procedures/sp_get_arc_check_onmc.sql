------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Written Date             : 2022/01/07
-- Procedure Name 	 		: jig.sp_get_arc_check_onmc
-- Filename					: jig.sp_get_arc_check_onmc.sql
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.mc.machines
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [jig].[sp_get_arc_check_onmc]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		@MCNo AS VARCHAR(50) = NULL
)
AS
BEGIN
	SET NOCOUNT ON;


 DECLARE @Check NVARCHAR(MAX)

 SET @Check =(SELECT  'XXX'
	FROM        APCSProDB.mc.machines INNER JOIN
    APCSProDB.trans.machine_jigs ON APCSProDB.mc.machines.id = APCSProDB.trans.machine_jigs.machine_id INNER JOIN
    APCSProDB.trans.jigs ON APCSProDB.trans.machine_jigs.jig_id = APCSProDB.trans.jigs.id INNER JOIN
    APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
    APCSProDB.jig.categories ON APCSProDB.jig.productions.category_id = APCSProDB.jig.categories.id INNER JOIN
    APCSProDB.method.processes ON APCSProDB.jig.categories.lsi_process_id = APCSProDB.method.processes.id INNER JOIN
    APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id
	WHERE APCSProDB.mc.machines.name = @MCNo 
	AND status = 'On Machine'
	AND APCSProDB.jig.categories.name = 'ARC'
 )

  
	-- CHECK MACHINES
	IF (@Check IS NOT NULL) 
		BEGIN
		 SELECT    'TRUE'   AS Is_Pass
				  , APCSProDB.mc.machines.name	AS MCNo 
				  , APCSProDB.trans.machine_jigs.jig_id
				  , APCSProDB.trans.jigs.barcode
				  , APCSProDB.trans.jigs.smallcode
				  , APCSProDB.trans.jigs.qrcodebyuser 
				  , APCSProDB.trans.jigs.status 
				  , APCSProDB.jig.productions.name				AS SubType
				  , APCSProDB.jig.categories.name				AS Type
				  , categories.short_name
				  , APCSProDB.method.processes.name				AS Process
				  , APCSProDB.trans.jig_conditions.value		AS LifeTime
				  , APCSProDB.mc.machines.id AS MC_ID
				  , APCSProDB.jig.productions.expiration_value	AS STD_LifeTime
	FROM        APCSProDB.mc.machines INNER JOIN
    APCSProDB.trans.machine_jigs ON APCSProDB.mc.machines.id = APCSProDB.trans.machine_jigs.machine_id INNER JOIN
    APCSProDB.trans.jigs ON APCSProDB.trans.machine_jigs.jig_id = APCSProDB.trans.jigs.id INNER JOIN
    APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
    APCSProDB.jig.categories ON APCSProDB.jig.productions.category_id = APCSProDB.jig.categories.id INNER JOIN
    APCSProDB.method.processes ON APCSProDB.jig.categories.lsi_process_id = APCSProDB.method.processes.id INNER JOIN
    APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id
	WHERE APCSProDB.mc.machines.name = @MCNo 
	AND status = 'On Machine'
	AND APCSProDB.jig.categories.name = 'ARC'
	END
	ELSE 
		BEGIN 
		SELECT 'FALSE' AS Is_Pass
	END

END
