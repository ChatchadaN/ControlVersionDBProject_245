------------------------------ Creater Rule ------------------------------
-- Project Name				: RCS
-- Author Name              : Chatchadaporn N.
-- Written Date             : 2024/08/09
-- Database Referd			: StoredProcedureDB
-- Specific Logic           : 
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [rcs].[sp_get_rack_auto_semi]
(		
	@item			varchar(20)
	, @location_id		varchar(20) --Stock
	
)
						
AS
BEGIN	 
	--SET NOCOUNT ON;
	SET NOCOUNT ON;	
	-----------------------------------------------------------------
	DECLARE @device_name VARCHAR(50)
	,@rack_name_id INT
	,@rack_address_id INT
	,@rack_name VARCHAR(50)
	,@rack_address  VARCHAR(50)
	,@category VARCHAR(50)
	,@location VARCHAR(50)
	,@area VARCHAR(50)

	-- Find Device Get Product code
	SELECT @device_name = product_code
	FROM APCSProDB.trans.lot_informations
	WHERE lot_no = @item

	-- Check item already exists
	IF EXISTS(SELECT 1 FROM APCSProDB.rcs.rack_addresses
	WHERE item = @item)
	BEGIN
		PRINT 'This item already exists in rack'

		SELECT 'FALSE' AS Is_Pass
		,'This item already exists in rack !!' AS Error_Message_ENG
		,N'Item นี้อยู่บน Rack แล้ว' AS Error_Message_THA
		,'' AS Rack_Address_ID
		,'' AS rack_name
		,'' AS rack_address
		,'' AS category
		,'' AS [location]
		,'' AS area

		RETURN;
	END
	
	-- Check if rack same product_code and location_id
	IF EXISTS(SELECT 1
		FROM APCSProDB.rcs.rack_addresses as rack_addresses
		INNER JOIN APCSProDB.[trans].[lot_informations] as lots ON rack_addresses.item = lots.lot_no
		INNER JOIN APCSProDB.rcs.rack_controls as rack_controls ON rack_addresses.rack_control_id = rack_controls.id
		WHERE lots.product_code = @device_name 
		AND rack_controls.location_id = @location_id)
	BEGIN
		PRINT 'EXISTS lot same product code'

		-- GET Rack name id
		SELECT @rack_name_id = rack_addresses.rack_control_id
		FROM  APCSProDB.rcs.rack_addresses as rack_addresses
		INNER JOIN APCSProDB.[trans].[lot_informations] as lots ON rack_addresses.item = lots.lot_no
		INNER JOIN APCSProDB.rcs.rack_controls as rack_controls ON rack_addresses.rack_control_id = rack_controls.id
		WHERE lots.product_code = @device_name 
			AND rack_controls.location_id = @location_id
		ORDER BY rack_control_id asc

		IF EXISTS (SELECT 1 FROM APCSProDB.rcs.rack_addresses
		WHERE rack_control_id = @rack_name_id AND item IS NULL)
		BEGIN
			PRINT 'Rack available'
			
			-- GET Rack address
			SELECT TOP 1 @rack_address_id = rack_addresses.id
			,@rack_name = rack_controls.name 
			,@rack_address = rack_addresses.[address]
			,@category = rack_categories.pattern 
			,@location = locations.name 
			,@area = locations.address
			FROM APCSProDB.rcs.rack_addresses
			INNER JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
			INNER JOIN APCSProDB.rcs.rack_categories ON rack_controls.category = rack_categories.id
			INNER JOIN APCSProDB.trans.locations ON rack_controls.location_id = locations.id
			WHERE rack_control_id = @rack_name_id
			AND item IS NULL
			ORDER BY rack_addresses.id ASC

			SELECT 'TRUE' AS Is_Pass
			,'Rack available Get Rack address id!!' AS Error_Message_ENG
			,N'Rack available Get Rack address id' AS Error_Message_THA
			,@rack_address_id AS Rack_Address_ID
			,@rack_name AS rack_name
			,@rack_address AS rack_address
			,@category AS category
			,@location AS [location]
			,@area AS area

		END
		ELSE
		BEGIN
			PRINT 'Rack full'

			-- GET New Rack name id
			SELECT TOP 1 @rack_name_id = rack_controls.id 
			FROM APCSProDB.rcs.rack_controls
			INNER JOIN APCSProDB.rcs.rack_addresses ON rack_addresses.rack_control_id = rack_controls.id
			WHERE location_id = @location_id
			AND item IS NULL
			AND rack_controls.is_enable = 1
			ORDER BY rack_controls.id

			-- GET New Rack address
			SELECT TOP 1 @rack_address_id = rack_addresses.id
			,@rack_name = rack_controls.name 
			,@rack_address = rack_addresses.[address]
			,@category = rack_categories.pattern 
			,@location = locations.name 
			,@area = locations.address
			FROM APCSProDB.rcs.rack_addresses
			INNER JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
			INNER JOIN APCSProDB.rcs.rack_categories ON rack_controls.category = rack_categories.id
			INNER JOIN APCSProDB.trans.locations ON rack_controls.location_id = locations.id
			WHERE rack_control_id = @rack_name_id
			AND item IS NULL
			ORDER BY rack_addresses.id ASC

			SELECT 'TRUE' AS Is_Pass
			,'Rack available Get Rack address id!!' AS Error_Message_ENG
			,N'Rack available Get Rack address id' AS Error_Message_THA
			,@rack_address_id AS Rack_Address_ID
			,@rack_name AS rack_name
			,@rack_address AS rack_address
			,@category AS category
			,@location AS [location]
			,@area AS area
		END
	END

	-- rack not same product code. find new Rack
	ELSE
	BEGIN
		PRINT 'NOT EXISTS lot not same product code'

		-- Find Rack name id
		SELECT TOP 1 @rack_name_id = rack_controls.id 
		FROM APCSProDB.rcs.rack_controls
		INNER JOIN APCSProDB.rcs.rack_addresses ON rack_addresses.rack_control_id = rack_controls.id
		WHERE location_id = @location_id
		AND item IS NULL
		AND rack_controls.is_enable = 1
		GROUP BY rack_controls.id
		ORDER BY rack_controls.id

		-- Check Rack full
		IF EXISTS(SELECT 1 FROM APCSProDB.rcs.rack_addresses
		WHERE rack_control_id = @rack_name_id
		AND item IS NULL)
		BEGIN
			PRINT 'Rack available Get Rack address'

			SELECT TOP 1 @rack_address_id = rack_addresses.id 
			,@rack_name = rack_controls.name 
			,@rack_address = rack_addresses.[address]
			,@category = rack_categories.pattern 
			,@location = locations.name 
			,@area = locations.address
			FROM APCSProDB.rcs.rack_addresses
			INNER JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
			INNER JOIN APCSProDB.rcs.rack_categories ON rack_controls.category = rack_categories.id
			INNER JOIN APCSProDB.trans.locations ON rack_controls.location_id = locations.id
			WHERE rack_control_id = @rack_name_id
			AND item IS NULL
			ORDER BY rack_addresses.id asc

			SELECT 'TRUE' AS Is_Pass
			,'Rack available Get Rack address id!!' AS Error_Message_ENG
			,N'Rack available Get Rack address id' AS Error_Message_THA
			,@rack_address_id AS Rack_Address_ID
			,@rack_name AS rack_name
			,@rack_address AS rack_address
			,@category AS category
			,@location AS [location]
			,@area AS area
		END
		ELSE
		BEGIN
			PRINT 'Rack FULL'

			SELECT 'FALSE' AS Is_Pass
			,'Rack Full Plase Register New Rack!!' AS Error_Message_ENG
			,N'Rack เต็ม กรุณาลงเทียน Rack ใหม่' AS Error_Message_THA
			,'' AS Rack_Address_ID
			,'' AS rack_name
			,'' AS rack_address
			,'' AS category
			,'' AS [location]
			,'' AS area
		END
	END

END
