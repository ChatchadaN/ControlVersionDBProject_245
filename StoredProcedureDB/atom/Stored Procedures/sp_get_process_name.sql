-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_process_name]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	

    -- Insert statements for procedure here
	SELECT ISNULL(process_special.name, process_master.name) AS process_name
	FROM APCSProDB.trans.lots
	INNER JOIN APCSProDB.method.jobs AS job_master ON job_master.id = lots.act_job_id
	INNER JOIN APCSProDB.method.processes AS process_master ON process_master.id = job_master.process_id
	LEFT JOIN APCSProDB.trans.special_flows ON lots.is_special_flow = 1
		AND lots.special_flow_id = special_flows.id
	LEFT JOIN APCSProDB.trans.lot_special_flows ON special_flows.id = lot_special_flows.special_flow_id
		AND special_flows.step_no = lot_special_flows.step_no
	LEFT JOIN APCSProDB.method.jobs AS job_special ON job_special.id = lot_special_flows.job_id
	LEFT JOIN APCSProDB.method.processes AS process_special ON process_special.id = job_special.process_id
	WHERE lots.lot_no = @lot_no
	
END
