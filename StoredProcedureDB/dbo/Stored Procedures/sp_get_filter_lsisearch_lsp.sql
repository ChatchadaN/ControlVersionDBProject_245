------------------------------ Creater Rule ------------------------------
-- Project Name				: LSI SEARCH PRO
-- Author Name              : Chatchadaporn N.
-- Written Date             : 20233/07/07
-- Database Referd			: StoredProcedureDB
-- Specific Logic           : 
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[sp_get_filter_lsisearch_lsp]
(		
	  @process			varchar(20) = ''
	, @machine			varchar(50) = '%'
	, @filter			INT = 1 
						--   1: Process 2: machine
)
						
AS
BEGIN	 
	--SET NOCOUNT ON;
	SET @process = CASE WHEN @process = '' THEN NULL ELSE @process END
	SET NOCOUNT ON;	

	--IF(@filter = 1)
	--BEGIN
	--	SELECT name AS filter_name
	--	FROM APCSProDB.method.processes
	--	WHERE id BETWEEN 2 AND 10
	--	GROUP BY name;
	--END
	--ELSE IF(@filter = 2)
	--BEGIN
	--	IF(@process = 'FL')
	--	BEGIN 
	--		SELECT machines.name AS filter_name
	--		FROM APCSProDB.mc.group_models
	--		INNER JOIN APCSProDB.mc.machines ON group_models.machine_model_id = machines.machine_model_id
	--		INNER JOIN APCSProDB.method.jobs ON group_models.machine_group_id = jobs.machine_group_id
	--		INNER JOIN APCSProDB.method.processes ON jobs.process_id = processes.id
	--		WHERE 
	--			(process_id BETWEEN 2 AND 10 AND group_models.machine_model_id <> 169)
	--			AND (processes.name = @process OR @process IS NULL) OR (machines.name LIKE '%FL-AXI%')
	--		GROUP BY machines.name
	--		ORDER BY machines.name
	--	END
	--	ELSE 
	--	BEGIN
	--		SELECT machines.name AS filter_name
	--		FROM APCSProDB.mc.group_models
	--		INNER JOIN APCSProDB.mc.machines ON group_models.machine_model_id = machines.machine_model_id
	--		INNER JOIN APCSProDB.method.jobs ON group_models.machine_group_id = jobs.machine_group_id
	--		INNER JOIN APCSProDB.method.processes ON jobs.process_id = processes.id
	--		WHERE (process_id BETWEEN 2 AND 10 AND group_models.machine_model_id <> 169)
	--			AND (processes.name = @process OR @process IS NULL)
	--		GROUP BY machines.name
	--		ORDER BY machines.name
	--	END
	--END

	IF(@filter = 1)
	BEGIN
		SELECT processes.name AS filter_name
		FROM APCSProDB.mc.group_models
		INNER JOIN APCSProDB.mc.machines ON group_models.machine_model_id = machines.machine_model_id
		INNER JOIN APCSProDB.method.jobs ON group_models.machine_group_id = jobs.machine_group_id
		INNER JOIN APCSProDB.method.processes ON jobs.process_id = processes.id
		GROUP BY processes.name
		ORDER BY processes.name
	END
	ELSE IF(@filter = 2)
	BEGIN	
		SELECT machines.name AS filter_name
		FROM APCSProDB.mc.group_models
		INNER JOIN APCSProDB.mc.machines ON group_models.machine_model_id = machines.machine_model_id
		INNER JOIN APCSProDB.method.jobs ON group_models.machine_group_id = jobs.machine_group_id
		INNER JOIN APCSProDB.method.processes ON jobs.process_id = processes.id
		WHERE processes.name = @process  OR @process IS NULL
		GROUP BY machines.name 
		ORDER BY machines.name 
	END
END
