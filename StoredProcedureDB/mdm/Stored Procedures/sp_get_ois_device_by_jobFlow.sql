-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_ois_device_by_jobFlow]
	-- Add the parameters for the stored procedure here
	@jobs INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @jobs_common INT

	SELECT @jobs_common = to_job_id FROM APCSProDB.trans.job_commons
	WHERE job_id = @jobs

	SET @jobs_common = CASE WHEN @jobs_common IS NULL THEN @jobs ELSE @jobs_common END

    -- Insert statements for procedure here
	BEGIN
	/****** Script for SelectTopNRows command from SSMS  ******/
	--SELECT MAX(device_names.id) as id 
	--	 , device_names.ft_name as device_names
	--  FROM APCSProDB.[method].[device_slips]
	--  INNER JOIN APCSProDB.method.device_versions on [device_slips].device_id = device_versions.device_id
	--  INNER JOIN APCSProDB.method.device_names on device_versions.device_name_id = device_names.id
	--  INNER JOIN APCSProDB.method.device_flows on [device_slips].[device_slip_id] = device_flows.device_slip_id
	--  INNER JOIN APCSProDB.method.jobs on device_flows.job_id = jobs.id
	--  INNER JOIN APCSProDB.method.processes on device_flows.act_process_id = processes.id
	--WHERE  device_names.ft_name IS NOT NULL
	--AND [device_slips].is_released = 1
	--AND jobs.id = @jobs
	--GROUP BY device_names.ft_name
	--ORDER BY device_names.ft_name

	--edit 09/12/2024 chatchadaporn n
		SELECT MAX(device_names.id) as id 
			 , device_names.ft_name as device_names
			FROM APCSProDB.[method].[device_slips]
			INNER JOIN APCSProDB.method.device_versions on [device_slips].device_id = device_versions.device_id
			INNER JOIN APCSProDB.method.device_names on device_versions.device_name_id = device_names.id
			INNER JOIN APCSProDB.method.device_flows on [device_slips].[device_slip_id] = device_flows.device_slip_id
			INNER JOIN APCSProDB.method.jobs on device_flows.job_id = jobs.id
			INNER JOIN APCSProDB.method.processes on device_flows.act_process_id = processes.id
		WHERE  device_names.ft_name IS NOT NULL
		AND [device_slips].is_released = 1
		AND jobs.id = @jobs_common
		GROUP BY device_names.ft_name
		ORDER BY device_names.ft_name

	END
END
