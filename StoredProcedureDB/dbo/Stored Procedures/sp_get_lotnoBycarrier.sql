-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_lotnoBycarrier]
	-- Add the parameters for the stored procedure here
	@carrier_no nvarchar(20) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT top 1 lot_no , carrier_no as loadCarrier,next_carrier_no as unLoadCarrier 
	, job.name as job 
	--, process_state as processstate
	, case when process_state = 0 THEN 'WIP'
			when process_state = 1 THEN 'Setup'
			when process_state = 2 THEN 'Processing'
			when process_state = 100 THEN 'WIP'
			when process_state = 101 THEN 'Setup'
			when process_state = 102 THEN 'Processing'
			when process_state = 102 THEN 'AbnormalEnd'
			ELSE 'Error'
			END as processstate 
	FROM APCSProDB.trans.lots
	INNER JOIN APCSProDB.method.jobs as job on APCSProDB.trans.lots.act_job_id = job.id
	where (carrier_no = @carrier_no or next_carrier_no = @carrier_no ) and wip_state = 20
END
