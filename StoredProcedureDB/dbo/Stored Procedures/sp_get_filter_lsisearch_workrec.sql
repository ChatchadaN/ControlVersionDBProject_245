------------------------------ Creater Rule ------------------------------
-- Project Name				: LSI SEARCH PRO
-- Author Name              : Chatchadaporn N.
-- Written Date             : 20233/07/07
-- Database Referd			: StoredProcedureDB
-- Specific Logic           : 
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[sp_get_filter_lsisearch_workrec]
(		
	  @process			varchar(50) = '%'
	, @machine			varchar(50) = '%'
	, @device			varchar(50) = '%'
	, @package			varchar(50) = '%'
	, @packageGroup		varchar(50) = '%'
	, @filter			INT = 1 
						--   1: Process 2: machine 3: jobs 4: package 5:device 6:status 7:packageGroup
)
						
AS
BEGIN	 
	--SET NOCOUNT ON;
	SET @process = CASE WHEN @process = '' THEN NULL ELSE @process END
	SET @device = CASE WHEN @device = '' THEN NULL ELSE @device END
	SET @package = CASE WHEN @package = '' THEN NULL ELSE @package END
	SET @packageGroup = CASE WHEN @packageGroup = '' THEN NULL ELSE @packageGroup END
	SET NOCOUNT ON;	

	IF(@filter = 1)
	BEGIN
		SELECT processes.name as [filter_name]
		FROM APCSProDB.method.processes
		ORDER BY processes.name
	END
	ELSE IF(@filter = 2)
	BEGIN
		SELECT machines.name AS filter_name
		FROM APCSProDB.mc.group_models
		INNER JOIN APCSProDB.mc.machines with (NOLOCK) ON group_models.machine_model_id = machines.machine_model_id
		INNER JOIN APCSProDB.method.jobs with (NOLOCK) ON group_models.machine_group_id = jobs.machine_group_id
		INNER JOIN APCSProDB.method.processes with (NOLOCK) ON jobs.process_id = processes.id
		WHERE group_models.machine_model_id <> 169
		  AND (processes.name LIKE @process OR processes.name IS NULL)
		GROUP BY machines.name
		ORDER BY machines.name
	END
	ELSE IF(@filter = 3)
	BEGIN
		SELECT jobs.name as [filter_name]
		FROM APCSProDB.method.jobs
		INNER JOIN APCSProDB.method.processes with (NOLOCK) ON jobs.process_id = processes.id
		WHERE processes.name LIKE @process OR processes.name IS NULL 
		GROUP BY jobs.name
		ORDER BY jobs.name
	END
	ELSE IF(@filter = 4)
	BEGIN
		--SELECT [packages].[name] as [filter_name]
		--FROM [APCSProDB].[trans].[lots]						with (NOLOCK)
		--INNER JOIN [APCSProDB].[method].[device_slips]		with (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		--INNER JOIN [APCSProDB].[method].[device_versions]	with (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
		--INNER JOIN [APCSProDB].[method].[device_names]		with (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
		--INNER JOIN [APCSProDB].[method].[packages]			with (NOLOCK) ON [packages].[id] = [device_names].[package_id]
		--WHERE [device_names].[name] LIKE @device OR @device IS NULL
		--GROUP BY [packages].[name]
		--ORDER BY [packages].[name]

		SELECT [packages].[name] as [filter_name]
		FROM [APCSProDB].[trans].[lots]						with (NOLOCK)
		INNER JOIN [APCSProDB].[method].[device_slips]		with (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions]	with (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names]		with (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages]			with (NOLOCK) ON [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[method].[package_groups]	with (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
		WHERE package_groups.name LIKE @packageGroup OR @packageGroup IS NULL
		GROUP BY [packages].[name]
		ORDER BY [packages].[name]
	END
	ELSE IF(@filter = 5)
	BEGIN
		SELECT [device_names].name as [filter_name]
		FROM [APCSProDB].[trans].[lots]						with (NOLOCK)
		INNER join [APCSProDB].[method].[device_slips]		with (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER join [APCSProDB].[method].[device_versions]	with (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER join [APCSProDB].[method].[device_names]		with (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
		INNER join [APCSProDB].[method].[packages]			with (NOLOCK) ON [packages].[id] = [device_names].[package_id]
		WHERE [packages].[name] LIKE @package OR @package IS NULL
		GROUP BY [device_names].name
	END
	ELSE IF(@filter = 6)
	BEGIN
		SELECT label_eng as [filter_name]
		FROM APCSProDB.trans.item_labels
		WHERE name = 'lot_process_records.record_class' 
		AND item_labels.val in (1,2)
	END
	ELSE IF(@filter = 7)
	BEGIN
		SELECT [package_groups].[name] as [filter_name]
		FROM [APCSProDB].[trans].[lots]						with (NOLOCK)
		INNER JOIN [APCSProDB].[method].[device_slips]		with (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions]	with (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names]		with (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages]			with (NOLOCK) ON [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[method].[package_groups]	with (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
		GROUP BY [package_groups].[name]
		ORDER BY [package_groups].[name]
	END
END
