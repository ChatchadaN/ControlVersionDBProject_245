------------------------------ Creater Rule ------------------------------
-- Project Name				: RCS
-- Author Name              : Chatchadaporn N.
-- Written Date             : 2025/01/07
-- Database Referd			: StoredProcedureDB
-- Specific Logic           : 
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [rcs].[sp_get_rack_set_lists]
(
	@rack_set_id INT
	, @value_type INT = 0
	--(1 : device, 2 : job, 3 : package)
	, @filter INT
	--(1 : data for show manage data 2 : data for show in matching w/ rack  3 : show details rack set list )
)				
AS
BEGIN	 
	--SET NOCOUNT ON;
	SET NOCOUNT ON;	
	IF (@filter = 1)
	BEGIN
		-- 1 : data for manage 
		--(1 : device, 2 : job, 3 : package)
		SELECT rack_set_lists.rack_set_id
			, rack_sets.name as rack_set
			, rack_set_lists.value_type
			, item_labels.label_eng AS type_item
			, rack_set_lists.value AS item_id
			, COALESCE(packages.name,jobs.name,device_names.assy_name) AS item_name
			, rack_set_lists.created_at
			, user1.emp_num AS created_by
			, rack_set_lists.updated_at
			, user2.emp_num AS updated_by
		FROM APCSProDB.rcs.rack_set_lists
		INNER JOIN APCSProDB.rcs.rack_sets ON rack_set_lists.rack_set_id = rack_sets.id
		INNER JOIN APCSProDB.rcs.item_labels ON rack_set_lists.value_type = item_labels.val AND item_labels.[name] = 'rack_settings.value_type' 
		LEFT JOIN APCSProDB.method.device_names ON  device_names.id = rack_set_lists.value AND item_labels.val = 1
		--AND item_labels.label_eng = 'Device'  
		LEFT JOIN APCSProDB.method.packages ON  packages.id = rack_set_lists.value AND item_labels.val = 3
		--AND item_labels.label_eng = 'Package'  
		LEFT JOIN APCSProDB.method.jobs ON  jobs.id = rack_set_lists.value  AND item_labels.val = 2
		--AND item_labels.label_eng = 'Job' 
		LEFT JOIN [APCSProDB].[man].[users] AS user1 ON rack_set_lists.[created_by] = [user1].[id]
		LEFT JOIN [APCSProDB].[man].[users] AS user2 ON rack_set_lists.[updated_by] = [user2].[id]
		WHERE rack_set_id = @rack_set_id
		AND value_type = @value_type
	END
	ELSE IF (@filter = 2)
	BEGIN
		--2 : data for show in matching w/ rack
		DECLARE @RackSetLsits TABLE 
		(
			rack_set_id INT
			, device_name_id INT
			, job_id INT
			, package_id INT
		)
		
		;WITH RackSetList AS (
			SELECT 
				rack_set_id
				, value
				, value_type
				, label_eng
				, created_at
				, created_by
				, updated_at
				, updated_by
				, ROW_NUMBER() OVER (PARTITION BY label_eng ORDER BY value ) AS RowNum
			FROM (
				SELECT rack_set_id
					, value
					, value_type
					, item_labels.label_eng
					, rack_set_lists.created_at
					, rack_set_lists.created_by
					, rack_set_lists.updated_at
					, rack_set_lists.updated_by
				FROM APCSProDB.rcs.rack_set_lists
				INNER JOIN APCSProDB.rcs.item_labels ON rack_set_lists.value_type = item_labels.val 
					AND item_labels.[name] = 'rack_settings.value_type' 
				WHERE rack_set_id = @rack_set_id	
			) AS SourceTable
		),
		DeviceData AS (
			SELECT 
				RowNum
				,value AS device_name
			FROM RackSetList
			WHERE value_type = 1
			--WHERE label_eng = 'Device'
		),
		JobsData AS (
			SELECT 
				RowNum
				,value AS job	
			FROM RackSetList
			WHERE value_type = 2
			--WHERE label_eng = 'Job'
		)

		INSERT INTO @RackSetLsits
		SELECT rsl.rack_set_id
			,d.device_name
			,j.job
			,packages.id as packages
		FROM RackSetList rsl
		CROSS JOIN DeviceData d
		CROSS JOIN JobsData j
		INNER JOIN APCSProDB.method.device_names ON d.device_name = device_names.id
		INNER JOIN APCSProDB.method.packages ON device_names.package_id = packages.id

		SELECT 
			rack_set_lists.rack_set_id
			, rack_set_lists.package_id
			, rack_set_lists.job_id
			, rack_set_lists.device_name_id		
			, rack_sets.name as rack_set
			, packages.name as packages
			, jobs.name as jobs
			, device_names.assy_name as device_names
		FROM @RackSetLsits AS rack_set_lists
		INNER JOIN APCSProDB.rcs.rack_sets ON rack_set_lists.rack_set_id = rack_sets.id
		INNER JOIN APCSProDB.method.packages ON rack_set_lists.package_id = packages.id
		INNER JOIN APCSProDB.method.jobs ON rack_set_lists.job_id = jobs.id
		INNER JOIN APCSProDB.method.device_names ON rack_set_lists.device_name_id = device_names.id
	
		GROUP BY rack_set_id, job_id , device_name_id, rack_set_lists.package_id 
		, rack_sets.name , packages.name, jobs.name, device_names.assy_name
	END
	ELSE IF (@filter = 3)
	BEGIN
		-- 3 : show details rack set list		
		SELECT rack_set_lists.rack_set_id
			, rack_sets.name as rack_set
			, rack_set_lists.value_type
			, item_labels.label_eng AS type_item
			, rack_set_lists.value AS item_id
			, COALESCE(packages.name,jobs.name,[device_names].[assy_name]) AS item_name
			, rack_set_lists.created_at
			, user1.emp_num AS created_by
			, rack_set_lists.updated_at
			, user2.emp_num AS updated_by
		FROM APCSProDB.rcs.rack_set_lists
		INNER JOIN APCSProDB.rcs.rack_sets ON rack_set_lists.rack_set_id = rack_sets.id
		INNER JOIN APCSProDB.rcs.item_labels ON rack_set_lists.value_type = item_labels.val AND item_labels.[name] = 'rack_settings.value_type' 
		LEFT JOIN APCSProDB.method.device_names ON  device_names.id = rack_set_lists.value AND item_labels.val = 1
		--AND item_labels.label_eng = 'device_names'  
		LEFT JOIN APCSProDB.method.packages ON  packages.id = rack_set_lists.value AND item_labels.val = 3
		--AND item_labels.label_eng = 'package'  
		LEFT JOIN APCSProDB.method.jobs ON  jobs.id = rack_set_lists.value AND item_labels.val = 2
		--AND item_labels.label_eng = 'jobs'
		LEFT JOIN [APCSProDB].[man].[users] AS user1 ON rack_set_lists.[created_by] = [user1].[id]
		LEFT JOIN [APCSProDB].[man].[users] AS user2 ON rack_set_lists.[updated_by] = [user2].[id]
		WHERE rack_set_id = @rack_set_id
	END
END