-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [jig].[sp_get_kanagata_predictiveshot]
	-- Add the parameters for the stored procedure here
	@kanagataNo varchar(100)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	Declare @root_id as int
			,@process as varchar(5)

	Declare @tmpData as varchar(50)

	select @root_id = APCSProDB.trans.jigs.id,@process = TRIM(processes.name) from APCSProDB.trans.jigs 
	INNER JOIN APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
	INNER JOIN APCSProDB.jig.categories ON APCSProDB.jig.productions.category_id = APCSProDB.jig.categories.id
	INNER JOIN APCSProDB.method.processes ON processes.id = categories.lsi_process_id
	where APCSProDB.trans.jigs.qrcodebyuser = @kanagataNo

	if (@root_id is null)
	begin
		Select 'FALSE' as Is_Pass,'Kanagata :[' + @kanagataNo+'] number is not registered. !!'   AS Error_Message_ENG
		,N'Kanagata :[' + @kanagataNo +N'] นี้ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
		,N'กรุณาลงทะเบียน Kanagata ที่เว็บ JIG' AS Handling
	end
	else
		begin

		if not exists(select 1
			from APCSProDB. trans.jigs INNER JOIN APCSProDB.trans.jig_conditions on jigs.id = jig_conditions.id 
			inner join APCSProDB.jig.productions on APCSProDB.jig.productions.id = jigs.jig_production_id
			inner join APCSProDB.jig.production_counters on production_counters.production_id = productions.id
			where jigs.id <> @root_id and root_jig_id = @root_id) 
		begin
			Select 'FALSE' as Is_Pass,'Kanagata Part not yet registered. !!' AS Error_Message_ENG
				,N'Kanakata Part ยังไม่ถูกลงทะเบียน!!' AS Error_Message_THA
				,N'กรุณาลงทะเบียน Kanagata Part ที่เว็บ JIG' AS Handling
			RETURN
		end
		
		if exists(	select table1.Cul_ShotPerFrame from (select jigs.id,barcode,value,warn_value as SafetyFactor,production_counters.alarm_value  as STDLifeTime,
			(case when (value+warn_value) > production_counters.alarm_value  then 'Expire' else 'Ready' end) as Cul_ShotPerFrame,root_jig_id 
			from APCSProDB. trans.jigs INNER JOIN APCSProDB.trans.jig_conditions on jigs.id = jig_conditions.id 
			inner join APCSProDB.jig.productions on APCSProDB.jig.productions.id = jigs.jig_production_id
			inner join APCSProDB.jig.production_counters on production_counters.production_id = productions.id
			where jigs.id <> @root_id and root_jig_id = @root_id) as table1 where table1.Cul_ShotPerFrame = 'Expire')
				begin
					Select 'FALSE' as Is_Pass,'Kanagata Part Life Time expire. !!' AS Error_Message_ENG
						,N'Kanakata Part หมดอายุการใช้งาน !!' AS Error_Message_THA
						,N'ตรวจสอบ Part ที่หมดอายุที่เว็บ JIG' AS Handling
						,MAX(FORMAT((CONVERT (decimal(18 , 2),APCSProDB.trans.jig_conditions.value) / CONVERT (decimal(18 , 2),APCSProDB.jig.production_counters.alarm_value )) * 100, 'N2')) AS LifeTime_Percen 

					FROM APCSProDB.trans.jigs  INNER JOIN 
					APCSProDB.trans.jig_conditions ON jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN 
					APCSProDB.jig.productions ON APCSProDB.jig.productions.id = jigs.jig_production_id INNER JOIN 
					APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 

					where jigs.id <> @root_id and root_jig_id = @root_id

				end
			else
				begin
					Select 'TRUE' as Is_Pass,'' AS Error_Message_ENG
						,N'' AS Error_Message_THA
						,N'' AS Handling
						,MAX(FORMAT((CONVERT (decimal(18 , 2),APCSProDB.trans.jig_conditions.value) / CONVERT (decimal(18 , 2),APCSProDB.jig.production_counters.alarm_value)) * 100, 'N2')) AS LifeTime_Percen 

					FROM APCSProDB.trans.jigs  INNER JOIN 
					APCSProDB.trans.jig_conditions ON jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN 
					APCSProDB.jig.productions ON APCSProDB.jig.productions.id = jigs.jig_production_id INNER JOIN 
					APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 

					where jigs.id <> @root_id and root_jig_id = @root_id
				end
		end
END