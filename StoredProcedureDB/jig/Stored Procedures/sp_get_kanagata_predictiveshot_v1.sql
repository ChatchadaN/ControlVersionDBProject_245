-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [jig].[sp_get_kanagata_predictiveshot_v1]
	-- Add the parameters for the stored procedure here
	@kanagataNo varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	Declare @root_id as int
	Declare @tmpData as varchar(50)
	SET @root_id = (select APCSProDB.trans.jigs.id from APCSProDB.trans.jigs where APCSProDB.trans.jigs.qrcodebyuser = @kanagataNo)
	if (@root_id is null)
	begin
		Select 'False' as Result,'Kanagata :[' + @kanagataNo+'] not found in trans.jigs.qrcodebyuser'  as Reason
	end
	else
		begin
			if exists(	select table1.Cul_ShotPerFrame from (select jigs.id,barcode,value,warn_value as SafetyFactor,expiration_value as STDLifeTime,
			(case when (value+warn_value) > expiration_value then 'Expire' else 'Ready' end) as Cul_ShotPerFrame,root_jig_id 
			from APCSProDB. trans.jigs INNER JOIN APCSProDB.trans.jig_conditions on jigs.id = jig_conditions.id 
			inner join APCSProDB.jig.productions on APCSProDB.jig.productions.id = jigs.jig_production_id
			inner join APCSProDB.jig.production_counters on production_counters.production_id = productions.id
			where jigs.id <> @root_id and root_jig_id = @root_id) as table1 where table1.Cul_ShotPerFrame = 'Expire')
				begin
					Select 'False' as Result,'Kanagata part Lifetime (Expired)'  as Reason
				end
			else
				begin
					Select 'True' as Result, '' as Reason
				end
		end
END