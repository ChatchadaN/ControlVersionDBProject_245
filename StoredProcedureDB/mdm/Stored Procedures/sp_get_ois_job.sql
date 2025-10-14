-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_ois_job]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
	/****** Script for SelectTopNRows command from SSMS  ******/
	--SELECT MAX(jobs.id) as id, jobs.name as jobs 
	--	FROM [APCSProDB].[method].[device_slips]
	--	INNER JOIN APCSProDB.method.device_versions ON [device_slips].device_id = device_versions.device_id
	--	INNER JOIN APCSProDB.method.device_names ON device_versions.device_name_id = device_names.id
	--	INNER JOIN APCSProDB.method.device_flows ON [device_slips].[device_slip_id] = device_flows.device_slip_id
	--	INNER JOIN APCSProDB.method.jobs ON device_flows.job_id = jobs.id
	--	INNER JOIN APCSProDB.method.processes ON device_flows.act_process_id = processes.id
	--WHERE processes.id in (8,9)
	--GROUP BY jobs.name  
	--ORDER BY jobs.name

	--edit 28/11/2024 chatchadaporn n
	SELECT  MAX(j2.id) as id, j2.name as jobs 
	FROM APCSProDB.trans.job_commons
		INNER JOIN APCSProDB.method.jobs j1 on job_commons.job_id = j1.id
		INNER JOIN APCSProDB.method.jobs j2 on job_commons.to_job_id = j2.id
	group by j2.name
	END
END
