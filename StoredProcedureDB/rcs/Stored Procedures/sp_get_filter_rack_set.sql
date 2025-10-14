------------------------------ Creater Rule ------------------------------
-- Project Name				: RCS
-- Author Name              : Chatchadaporn N.
-- Written Date             : 2025/01/06
-- Database Referd			: StoredProcedureDB
-- Specific Logic           : 
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [rcs].[sp_get_filter_rack_set]
(		
	 @filter			INT = 1
	 , @rack_set_id		INT = 0
	--   1: Device 2: Job 3: Package 4: Rack 5: Rack Set
)
						
AS
BEGIN	 
	--SET NOCOUNT ON;
	SET NOCOUNT ON;	

	-- Devices
	IF (@filter = 1)
	BEGIN
		IF (@rack_set_id = 0 )
		BEGIN
			SELECT id as filter_id
			, assy_name as filter_name
			, '' AS filter_name_2
			FROM APCSProDB.method.device_names
			ORDER BY package_id asc
		END
		ELSE
		BEGIN
			SELECT 
				device_names.id AS filter_id
				, TRIM(device_names.name) + ' / ' + TRIM(device_names.assy_name) + '' AS filter_name
				, packages.name AS filter_name_2
			FROM APCSProDB.method.device_names
			INNER JOIN APCSProDB.method.packages ON device_names.package_id = packages.id
			WHERE package_id IN ( SELECT packages.id
				FROM APCSProDB.rcs.rack_set_lists
				INNER JOIN APCSProDB.method.packages ON rack_set_lists.value = packages.id
				WHERE rack_set_id = @rack_set_id
				AND value_type = 3 )
			AND device_names.id NOT IN (SELECT device_names.id
				FROM APCSProDB.rcs.rack_set_lists
				INNER JOIN APCSProDB.method.device_names ON rack_set_lists.value = device_names.id
				WHERE  rack_set_id = @rack_set_id
				AND value_type = 1)
			ORDER BY packages.name ASC
		END

		--DECLARE @package_tb TABLE (id INT)
		--INSERT INTO @package_tb
		--SELECT id FROM @package_set

		--IF EXISTS(SELECT 1 FROM @package_tb)
		--BEGIN
		--	Print 'Filter Device'
		--	SELECT id as filter_id
		--	, assy_name as filter_name
		--	FROM APCSProDB.method.device_names
		--	WHERE package_id IN (SELECT id FROM @package_tb)
		--	ORDER BY package_id asc
		--END
		--ELSE
		--BEGIN
		--	Print 'All Device'
		--	SELECT id as filter_id
		--	, assy_name as filter_name
		--	FROM APCSProDB.method.device_names
		--	ORDER BY package_id asc
		--END
	END

	-- Jobs
	ELSE IF (@filter = 2)
	BEGIN
		SELECT id AS filter_id
			, name AS filter_name
			, '' AS filter_name_2
		FROM APCSProDB.method.jobs
		ORDER BY id asc
	END

	-- Packages
	ELSE IF(@filter = 3)
	BEGIN
		SELECT id as filter_id
			, name as filter_name
			, '' AS filter_name_2
		FROM APCSProDB.method.packages
		ORDER BY id asc
	END

	-- Rack
	ELSE IF (@filter = 4)
	BEGIN
		SELECT id as filter_id
		, name as filter_name
		, '' AS filter_name_2
		FROM APCSProDB.rcs.rack_controls
		WHERE is_enable = 1
		ORDER BY id asc
	END

	-- Rack Set
	ELSE IF (@filter = 5)
	BEGIN
		SELECT id as filter_id
		, name as filter_name
		, '' AS filter_name_2
		FROM APCSProDB.rcs.rack_sets
	END
END
