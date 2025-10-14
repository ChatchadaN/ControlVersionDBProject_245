-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_device_flow] 
	-- Add the parameters for the stored procedure here
	@id INT  
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
		 SELECT   device_flows.id	
				, processes.name		AS processes	
				, jobs.name				AS jobs
				, device_flows.step_no  
				, device_flows.next_step_no  
				, device_flows.recipe
				, device_flows.is_skipped 
				, device_flows.material_set_id	AS material_sets 
				, device_flows.jig_set_id		AS jig_sets  
				, device_flows.is_sblsyl  
		 FROM APCSProDB.method.device_names  
		 INNER JOIN APCSProDB.method.device_versions  
		 ON device_names.id = device_versions.device_name_id  
		 INNER JOIN APCSProDB.method.device_slips  
		 ON  device_slips.device_id = device_versions.device_id  
		 INNER JOIN APCSProDB.method.device_flows  
		 ON device_flows.device_slip_id = device_slips.device_slip_id  
		 INNER JOIN APCSProDB.method.processes  
		 ON processes.id = device_flows.act_process_id  
		 INNER JOIN APCSProDB.method.jobs  
		 ON jobs.id = device_flows.job_id  
		 WHERE device_names.id =  @id
		 AND   device_versions.device_type = 0 
		 AND device_slips.version_num = (SELECT MAX(device_slips.version_num) 
										 FROM APCSProDB.method.device_slips  
										 WHERE device_id = device_versions.device_id  AND device_slips.is_released = 1  )
		 ORDER BY device_flows.step_no 

END