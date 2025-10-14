-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_version]
	-- Add the parameters for the stored procedure here
		@mcNo varchar(30)--, @last smallint
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @machine_id int,@application_set_id int,@process_version varchar(20),@autoupdate_version varchar(20),@cellcon_program varchar(50)
    -- Insert statements for procedure here
		SELECT @machine_id = mc.id ,@application_set_id = mc.application_set_id
		from APCSProDB.mc.machines as mc 
		where mc.[name] = @mcNo

		select top(1) @process_version = app_set.[version],@cellcon_program = app_set.[name] 
		from APCSProDB.cellcon.application_histories as app_his
		inner join APCSProDB.cellcon.application_sets as app_set on app_set.id = app_his.application_set_id		
		where app_his.machine_id = @machine_id 
		order by app_his.updated_at desc

		select @autoupdate_version = app_set.[version] from APCSProDB.cellcon.application_sets as app_set
		where app_set.id = @application_set_id

		--select new version
	select @process_version as process_version,@autoupdate_version as autoupdate_version,@cellcon_program as cellcon_program


END
