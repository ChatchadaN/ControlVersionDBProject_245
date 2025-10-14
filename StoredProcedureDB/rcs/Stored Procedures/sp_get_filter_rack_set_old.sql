------------------------------ Creater Rule ------------------------------
-- Project Name				: RCS
-- Author Name              : Chatchadaporn N.
-- Written Date             : 2025/01/06
-- Database Referd			: StoredProcedureDB
-- Specific Logic           : 
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [rcs].[sp_get_filter_rack_set_old]
(		
	@package_set [dbo].[rcs_package] readonly
	, @filter			INT = 1
	--   1: Device 2: Job 3: Package 4: Rack 5: Rack Set
)
						
AS
BEGIN	 
	--SET NOCOUNT ON;
	SET NOCOUNT ON;	

	-- Devices
	IF (@filter = 1)
	BEGIN
		DECLARE @package_tb TABLE (id INT)
		INSERT INTO @package_tb
		SELECT id FROM @package_set

		IF EXISTS(SELECT 1 FROM @package_tb)
		BEGIN
			Print 'Filter Device'
			SELECT id as filter_id
			, assy_name as filter_name
			FROM APCSProDB.method.device_names
			WHERE package_id IN (SELECT id FROM @package_tb)
			ORDER BY package_id asc
		END
		ELSE
		BEGIN
			Print 'All Device'
			SELECT id as filter_id
			, assy_name as filter_name
			FROM APCSProDB.method.device_names
			ORDER BY package_id asc
		END
	END

	-- Jobs
	ELSE IF (@filter = 2)
	BEGIN
		SELECT id as filter_id
		, name as filter_name
		FROM APCSProDB.method.jobs
		ORDER BY id asc
	END

	-- Packages
	ELSE IF(@filter = 3)
	BEGIN
		SELECT id as filter_id
			, name as filter_name
		FROM APCSProDB.method.packages
		ORDER BY id asc
	END

	-- Rack
	ELSE IF (@filter = 4)
	BEGIN
		SELECT id as filter_id
		, name as filter_name
		FROM APCSProDB.rcs.rack_controls
		WHERE is_enable = 1
		ORDER BY id asc
	END

	-- Rack Set
	ELSE IF (@filter = 5)
	BEGIN
		SELECT id as filter_id
		, name as filter_name
		FROM APCSProDB.rcs.rack_sets
	END
END