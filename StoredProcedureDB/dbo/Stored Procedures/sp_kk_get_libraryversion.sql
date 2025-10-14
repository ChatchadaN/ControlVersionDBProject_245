-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_kk_get_libraryversion]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

/****** SSMS の SelectTopNRows コマンドのスクリプト  ******/
SELECT 
      --g.[name] as group_name
		g.name as group_name
	  ,md.name
	  ,m.id as machine_id
	  ,m.name as machine_name
	  ,m.application_set_id
	  ,appf.file_id
	  ,f.name
	  ,f.version
	  ,f.update_at
  FROM 
  apcsprodb.mc.models as md inner join
	apcsprodb.mc.group_models as gm 
	--	on gm.machine_group_id = g.id 
	on md.id = gm.machine_model_id
	left outer  join apcsprodb.mc.groups as g
		on g.id = gm.machine_group_id
	inner join apcsprodb.mc.machines as m 
		on m.machine_model_id = gm.machine_model_id
	inner join apcsprodb.cellcon.application_application_sets as apps 
		on apps.application_set_id = m.application_set_id 
	inner join apcsprodb.cellcon.applications_file as appf 
		on appf.application_id = apps.application_id 
	inner join apcsprodb.cellcon.files as f 
		on f.id = appf.file_id
  where --g.id in(1,6) and 
	 m.application_set_id is not null
	and f.name = 'iLibrary.dll'

	order by md.name,f.version
END
