-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_autoupdate_history]
	-- Add the parameters for the stored procedure here
	@mcNo varchar(30), @last smallint
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	If @last = 1
	BEGIN
		SELECT Dup_MC.name AS mcName
			 , MCModels.name AS mcModel
			 , Dup_MC.cell_ip
			 , Dup_MC.machine_ip1
			 --, Dup_MC.machine_ip2
			 , AppsSet.name AS mainProgramName
			 , LAST_VALUE(AppsSet.version) OVER(PARTITION BY Dup_MC.name
												ORDER BY AppsHistory.updated_at
												RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS mainAutoUpdateProgramVersion
			 , AppsSet.version AS mainProgramVersion
			 , Apps.name AS subProgramName
			 , Apps.version AS subProgramVersion
			 , Files.name AS filesName
			 , Files.version AS fileVersion
			 , Files.directory AS directory
			 , AppsHistory.updated_at AS updated_at
			 
			FROM APCSProDB.cellcon.application_histories				AS AppsHistory
			INNER JOIN APCSProDB.cellcon.application_sets				AS AppsSet		ON AppsHistory.application_set_id	= AppsSet.id
			INNER JOIN APCSProDB.cellcon.application_application_sets	AS AppsAppsSet	ON AppsSet.id						= AppsAppsSet.application_set_id
			INNER JOIN APCSProDB.cellcon.applications					AS Apps			ON AppsAppsSet.application_id		= Apps.id
			INNER JOIN APCSProDB.cellcon.applications_file				AS AppsFile		ON Apps.id							= AppsFile.application_id
			INNER JOIN APCSProDB.cellcon.files							AS Files		ON AppsFile.file_id					= Files.id
			RIGHT JOIN APCSProDB.mc.machines								AS Dup_MC		ON AppsHistory.machine_id			= Dup_MC.id 
																					   and AppsHistory.application_set_id	= Dup_MC.application_set_id
			--INNER JOIN APCSProDB.mc.machines							AS All_MC		ON AppsHistory.machine_id			= All_MC.id
			INNER JOIN APCSProDB.mc.models								AS MCModels		ON Dup_MC.machine_model_id			= MCModels.id
		
			--WHERE Dup_MC.name = @mcNo and Dup_MC.name not like '%000'
			WHERE Dup_MC.name like '%' + @mcNo + '%' and Dup_MC.name not like '%000' and Files.name = 'Rohm.Common.CellController.dll' and Apps.name != 'LPM'
			ORDER BY Dup_MC.cell_ip, Dup_MC.name, updated_at desc, subProgramName, filesName	
	END
	ELSE
	BEGIN
		SELECT All_MC.name AS mcName
			 , MCModels.name AS mcModel
			 , All_MC.cell_ip
			 , All_MC.machine_ip1
			 --, All_MC.machine_ip2
			 , AppsSet.name AS mainProgramName
			 , LAST_VALUE(AppsSet.version) OVER(PARTITION BY All_MC.name
												ORDER BY AppsHistory.updated_at
												RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS mainAutoUpdateProgramVersion
			 , AppsSet.version AS mainMachineProgramVersion
			 , Apps.name AS subProgramName
			 , Apps.version AS subProgramVersion
			 , Files.name AS filesName
			 , Files.version AS fileVersion
			 , Files.directory AS directory
			 , AppsHistory.updated_at AS updated_at
		
			FROM APCSProDB.cellcon.application_histories				AS AppsHistory
			INNER JOIN APCSProDB.cellcon.application_sets				AS AppsSet		ON AppsHistory.application_set_id	= AppsSet.id
			INNER JOIN APCSProDB.cellcon.application_application_sets	AS AppsAppsSet	ON AppsSet.id						= AppsAppsSet.application_set_id
			INNER JOIN APCSProDB.cellcon.applications					AS Apps			ON AppsAppsSet.application_id		= Apps.id
			INNER JOIN APCSProDB.cellcon.applications_file				AS AppsFile		ON Apps.id							= AppsFile.application_id
			INNER JOIN APCSProDB.cellcon.files							AS Files		ON AppsFile.file_id					= Files.id
			LEFT  JOIN APCSProDB.mc.machines							AS Dup_MC		ON AppsHistory.machine_id			= Dup_MC.id 
																					   and AppsHistory.application_set_id	= Dup_MC.application_set_id
			INNER JOIN APCSProDB.mc.machines							AS All_MC		ON AppsHistory.machine_id			= All_MC.id
			INNER JOIN APCSProDB.mc.models								AS MCModels		ON All_MC.machine_model_id			= MCModels.id 
		
			WHERE All_MC.name like '%' + @mcNo + '%' and All_MC.name not like '%000' --and All_MC.name not like '%99'
		
			ORDER BY cell_ip, All_MC.name, updated_at desc, subProgramName, filesName
	END
END
