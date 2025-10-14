-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_kanagata_updateshot_v2]
	@kanagataNo varchar(50),
	@shotcounter int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	Declare @root_id3 as int

	SET @root_id3 = (select  APCSProDB.trans.jigs.id from APCSProDB.trans.jigs where APCSProDB.trans.jigs.qrcodebyuser = @kanagataNo )
	
	BEGIN TRY
		IF  (SELECT processes.name FROM APCSProDB.trans.jigs INNER JOIN 
						APCSProDB.jig.productions ON jig_production_id = productions.id INNER JOIN 
						APCSProDB.jig.categories ON category_id = categories.id INNER JOIN 
						APCSProDB.method.processes ON categories.lsi_process_id = processes.id
				WHERE qrcodebyuser = @kanagataNo) = 'MP'
		BEGIN
				update APCSProDB.trans.jig_conditions 
				SET value = value + @shotcounter
				where jig_conditions.id in(select jig_conditions.id
				from APCSProDB.trans.jigs INNER JOIN APCSProDB.trans.jig_conditions on jigs.id = jig_conditions.id 
				where jigs.id = @root_id3 and root_jig_id = @root_id3)
		END
		ELSE BEGIN
				update APCSProDB.trans.jig_conditions 
				SET value = value + @shotcounter
				where jig_conditions.id in(select jig_conditions.id
				from APCSProDB.trans.jigs INNER JOIN APCSProDB.trans.jig_conditions on jigs.id = jig_conditions.id 
				where jigs.id <> @root_id3 and root_jig_id = @root_id3)	
		END

		SELECT 'TRUE' AS Is_Pass
	END TRY
	BEGIN CATCH
		SELECT 'FALSE' AS Is_Pass,'Update Lifetime Error. !!' AS Error_Message_ENG
					,N'การอัดเดท Lifetime ผิดพลาด !!' AS Error_Message_THA
					,N'กรุณาติดต่อ System' AS Handling
	END CATCH
END

