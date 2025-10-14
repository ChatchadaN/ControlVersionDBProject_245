------------------------------ Creater Rule ------------------------------
-- Project Name				: MDN
-- Author Name              : Sadanun.B
-- Written Date             : 2021/11/23
-- Procedure Name 	 		: [mdm].[sp_get_DeviceSlipsAll]
-- Filename					: mdm.sp_get_DeviceSlipsAll.sql
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: method.device_slips
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [mdm].[sp_get_filter]
(	 
	  @package			varchar(MAX) = '%'
	, @device			varchar(MAX) = '%'
	, @version			varchar(MAX) = '%'
	, @assyname			varchar(MAX) = '%'  
	, @isreased			varchar(MAX) = '%'  
	, @devicetype		varchar(MAX) = '%' 
	, @ftname			varchar(MAX) = '%' 
	, @filter			int = 1 
	
	--   1: Package 2: assyname	3: version 4: Device 5 : IsReased 6 : DeviceType 7 : FTName
)
						
AS
BEGIN
	 
	--SET NOCOUNT ON;	
     

	-- DECLARE @Reased INT = 0


	--IF(@filter = 1)
	--BEGIN

	--SET @Reased = (SELECT item_labels.val FROM APCSProDB.method.item_labels 
	--				WHERE name = 'device_slips.is_released'
	--				AND label_eng = @isreased)

	--	SELECT DISTINCT [packages].[name] as [filter_name]
	--	FROM   APCSProDB.method.device_slips				 	(NOLOCK)
	--	INNER JOIN APCSProDB.method.device_versions			 	(NOLOCK)
	--	ON device_versions.device_id		= device_slips.device_id
	--	INNER JOIN APCSProDB.method.device_names			 	(NOLOCK)
	--	ON device_names.id					= device_versions.device_name_id
	--	INNER JOIN APCSProDB.method.packages				 	(NOLOCK)
	--	ON packages.id						= device_names.package_id
	--	INNER JOIN APCSProDB.method.item_labels 
	--	ON item_labels.name					= 'device_versions.device_type' 
	--	AND  device_versions.device_type	=  item_labels.val
	--	--WHERE device_names.name				LIKE @device
	--	--AND   packages.name					LIKE @package
	--	--AND   device_names.assy_name		LIKE @assyname
	--	--AND   device_slips.version_num		LIKE @version
	--	--AND   (device_slips.is_released		LIKE @Reased OR @Reased IS NULL )
	--	ORDER BY [packages].[name]
	--END
	--ELSE IF(@filter = 2)
	--BEGIN
	--SET @Reased = (SELECT item_labels.val FROM APCSProDB.method.item_labels 
	--				WHERE name = 'device_slips.is_released'
	--				AND label_eng = @isreased)

	--	SELECT DISTINCT device_names.assy_name as [filter_name]
	--	FROM   APCSProDB.method.device_slips				 	(NOLOCK)
	--	INNER JOIN APCSProDB.method.device_versions			 	(NOLOCK)
	--	ON device_versions.device_id		= device_slips.device_id
	--	INNER JOIN APCSProDB.method.device_names			 	(NOLOCK)
	--	ON device_names.id					= device_versions.device_name_id
	--	INNER JOIN APCSProDB.method.packages				 	(NOLOCK)
	--	ON packages.id						= device_names.package_id
	--	INNER JOIN APCSProDB.method.item_labels 
	--	ON item_labels.name					= 'device_versions.device_type' 
	--	AND  device_versions.device_type	=  item_labels.val
	--	--WHERE device_names.name				LIKE @device
	--	--AND   packages.name					LIKE @package
	--	--AND   device_names.assy_name		LIKE @assyname
	--	--AND   device_slips.version_num		LIKE @version
	--	--AND   (device_slips.is_released		LIKE @Reased OR @Reased IS NULL )
	--	ORDER BY [device_names].assy_name
	--END
	--ELSE IF(@filter = 3)
	--	BEGIN

	--	SET @Reased = (SELECT item_labels.val FROM APCSProDB.method.item_labels 
	--				WHERE name = 'device_slips.is_released'
	--				AND label_eng = @isreased)

	--	SELECT DISTINCT device_slips.version_num as [filter_name]
	--	FROM   APCSProDB.method.device_slips				 	(NOLOCK)
	--	INNER JOIN APCSProDB.method.device_versions			 	(NOLOCK)
	--	ON device_versions.device_id	= device_slips.device_id
	--	INNER JOIN APCSProDB.method.device_names			 	(NOLOCK)
	--	ON device_names.id				= device_versions.device_name_id
	--	INNER JOIN APCSProDB.method.packages				 	(NOLOCK)
	--	ON packages.id					= device_names.package_id
	--	INNER JOIN APCSProDB.method.item_labels 
	--	ON item_labels.name				= 'device_versions.device_type' 
	--	AND  device_versions.device_type	=  item_labels.val
	--	--WHERE device_names.name				LIKE @device
	--	--AND   packages.name					LIKE @package
	--	--AND   device_names.assy_name		LIKE @assyname
	--	--AND   device_slips.version_num		LIKE @version
	--	--AND   (device_slips.is_released		LIKE @Reased OR @Reased IS NULL )
	--	ORDER BY device_slips.version_num
	--END
	--ELSE IF(@filter = 4)
	--BEGIN
 
	--SET @Reased = (SELECT item_labels.val FROM APCSProDB.method.item_labels 
	--				WHERE name = 'device_slips.is_released'
	--				AND label_eng = @isreased )
 

	--	SELECT DISTINCT [device_names].[name] as [filter_name]
	--	FROM   APCSProDB.method.device_slips				 	(NOLOCK)
	--	INNER JOIN APCSProDB.method.device_versions			 	(NOLOCK)
	--	ON device_versions.device_id	= device_slips.device_id
	--	INNER JOIN APCSProDB.method.device_names			 	(NOLOCK)
	--	ON device_names.id				= device_versions.device_name_id
	--	INNER JOIN APCSProDB.method.packages				 	(NOLOCK)
	--	ON packages.id					= device_names.package_id
	--	INNER JOIN APCSProDB.method.item_labels 
	--	ON item_labels.name				= 'device_versions.device_type' 
	--	AND  device_versions.device_type	=  item_labels.val
	--	--WHERE device_names.name				LIKE @device
	--	--AND   packages.name					LIKE @package
	--	--AND   device_names.assy_name		LIKE @assyname
	--	--AND   device_slips.version_num		LIKE @version
	--	--AND   (device_slips.is_released		LIKE @Reased OR @Reased IS NULL )
	--	ORDER BY [device_names].[name]
	--END
	--ELSE IF(@filter = 5)
	--	BEGIN
		
	--SET @Reased = (SELECT item_labels.val FROM APCSProDB.method.item_labels 
	--				WHERE name = 'device_slips.is_released'
	--				AND (label_eng = @isreased AND @isreased IS NOT NULL ))

	--	CREATE TABLE #TEMP		(Is_released INT,filter_name NVARCHAR(MAX))
	--	INSERT INTO #TEMP		(Is_released)
	--	SELECT DISTINCT device_slips.is_released as [filter_name]
	--	FROM   APCSProDB.method.device_slips				 	(NOLOCK)
	--	INNER JOIN APCSProDB.method.device_versions			 	(NOLOCK)
	--	ON device_versions.device_id	= device_slips.device_id
	--	INNER JOIN APCSProDB.method.device_names			 	(NOLOCK)
	--	ON device_names.id				= device_versions.device_name_id
	--	INNER JOIN APCSProDB.method.packages				 	(NOLOCK)
	--	ON packages.id					= device_names.package_id
	--	INNER JOIN APCSProDB.method.item_labels 
	--	ON item_labels.name				= 'device_versions.device_type' 
	--	AND  device_versions.device_type	=  item_labels.val
	--	WHERE device_names.name				LIKE @device
	--	AND   packages.name					LIKE @package
	--	AND   device_names.assy_name		LIKE @assyname
	--	AND   device_slips.version_num		LIKE @version
	--	AND   (device_slips.is_released		LIKE @Reased OR @Reased IS NULL )
	--	ORDER BY device_slips.is_released
		
	--	UPDATE #TEMP
	--	SET filter_name = item_labels.label_eng
	--	FROM #TEMP
	--	INNER JOIN  APCSProDB.method.item_labels 
	--	ON Is_released = item_labels.val
	--	WHERE name = 'device_slips.is_released'

	--	SELECT filter_name FROM #TEMP 

	--	DROP TABLE #TEMP


	--END
 --ELSE IF(@filter = 6)
	--	BEGIN
		
	--SET @Reased = (SELECT item_labels.val FROM APCSProDB.method.item_labels 
	--				WHERE name = 'device_slips.is_released'
	--				AND label_eng = @isreased )
 

	--	SELECT DISTINCT item_labels.label_eng as [filter_name]
	--	FROM   APCSProDB.method.device_slips				 	(NOLOCK)
	--	INNER JOIN APCSProDB.method.device_versions			 	(NOLOCK)
	--	ON device_versions.device_id	= device_slips.device_id
	--	INNER JOIN APCSProDB.method.device_names			 	(NOLOCK)
	--	ON device_names.id				= device_versions.device_name_id
	--	INNER JOIN APCSProDB.method.packages				 	(NOLOCK)
	--	ON packages.id					= device_names.package_id
	--	INNER JOIN APCSProDB.method.item_labels 
	--	ON item_labels.name				= 'device_versions.device_type' 
	--	AND  device_versions.device_type	=  item_labels.val
	--	--WHERE device_names.name				LIKE @device
	--	--AND   packages.name					LIKE @package
	--	--AND   device_names.assy_name		LIKE @assyname
	--	--AND   device_slips.version_num		LIKE @version
	--	--AND   (device_slips.is_released		LIKE @Reased OR @Reased IS NULL )
	--	ORDER BY item_labels.label_eng

	--END
	SET NOCOUNT ON;	

	IF(@filter = 1)
	BEGIN
		SELECT DISTINCT packages.name as filter_name
		FROM APCSProDB.method.device_slips WITH (NOLOCK)
		INNER JOIN APCSProDB.method.device_versions WITH (NOLOCK)
			ON device_versions.device_id = device_slips.device_id
		INNER JOIN APCSProDB.method.device_names WITH (NOLOCK)
			ON device_names.id = device_versions.device_name_id
		INNER JOIN APCSProDB.method.packages WITH (NOLOCK)
			ON packages.id = device_names.package_id
		ORDER BY packages.name
	END
	ELSE IF(@filter = 2)
	BEGIN
		SELECT DISTINCT device_names.assy_name as filter_name
		FROM APCSProDB.method.device_slips WITH (NOLOCK)
		INNER JOIN APCSProDB.method.device_versions WITH (NOLOCK)
			ON device_versions.device_id = device_slips.device_id
		INNER JOIN APCSProDB.method.device_names WITH (NOLOCK)
			ON device_names.id = device_versions.device_name_id
		ORDER BY device_names.assy_name
	END
	ELSE IF(@filter = 3)
	BEGIN
		SELECT DISTINCT device_slips.version_num as filter_name
		FROM APCSProDB.method.device_slips WITH (NOLOCK)
		INNER JOIN APCSProDB.method.device_versions WITH (NOLOCK)
			ON device_versions.device_id = device_slips.device_id
		INNER JOIN APCSProDB.method.device_names WITH (NOLOCK)
			ON device_names.id = device_versions.device_name_id
		INNER JOIN APCSProDB.method.packages WITH (NOLOCK)
			ON packages.id = device_names.package_id
		ORDER BY device_slips.version_num
	END
	ELSE IF(@filter = 4)
	BEGIN
		SELECT DISTINCT device_names.name as filter_name
		FROM APCSProDB.method.device_slips WITH (NOLOCK)
		INNER JOIN APCSProDB.method.device_versions WITH (NOLOCK)
			ON device_versions.device_id = device_slips.device_id
		INNER JOIN APCSProDB.method.device_names WITH (NOLOCK)
			ON device_names.id = device_versions.device_name_id
		INNER JOIN APCSProDB.method.packages WITH (NOLOCK)
			ON packages.id = device_names.package_id
		ORDER BY device_names.name
	END
	ELSE IF(@filter = 5)
	BEGIN
		SELECT DISTINCT item_labels2.label_eng as filter_name
		FROM APCSProDB.method.device_slips WITH (NOLOCK)
		INNER JOIN APCSProDB.method.device_versions WITH (NOLOCK)
			ON device_versions.device_id = device_slips.device_id
		INNER JOIN APCSProDB.method.device_names WITH (NOLOCK)
			ON device_names.id = device_versions.device_name_id
		INNER JOIN APCSProDB.method.packages WITH (NOLOCK)
			ON packages.id = device_names.package_id
		LEFT JOIN APCSProDB.method.item_labels WITH (NOLOCK)
			ON item_labels.name = 'device_versions.device_type' 
			AND  device_versions.device_type = item_labels.val
		INNER JOIN APCSProDB.method.item_labels AS item_labels2  WITH (NOLOCK)
			ON device_slips.is_released = item_labels2.val
			AND	item_labels2.name = 'device_slips.is_released'
		WHERE device_names.name LIKE @device
			AND packages.name LIKE @package
			AND device_names.assy_name LIKE @assyname
			AND device_slips.version_num LIKE @version
			AND item_labels.label_eng LIKE @devicetype
			AND item_labels2.label_eng LIKE @isreased
		ORDER BY item_labels2.label_eng
	END
	ELSE IF(@filter = 6)
	BEGIN
		SELECT DISTINCT item_labels.label_eng as filter_name
		FROM APCSProDB.method.device_slips WITH (NOLOCK)
		INNER JOIN APCSProDB.method.device_versions WITH (NOLOCK)
			ON device_versions.device_id = device_slips.device_id
		INNER JOIN APCSProDB.method.device_names WITH (NOLOCK)
			ON device_names.id = device_versions.device_name_id
		INNER JOIN APCSProDB.method.packages WITH (NOLOCK)
			ON packages.id = device_names.package_id
		INNER JOIN APCSProDB.method.item_labels 
			ON item_labels.name = 'device_versions.device_type' 
			AND  device_versions.device_type = item_labels.val
		ORDER BY item_labels.label_eng
	END
	ELSE IF(@filter = 7)
	BEGIN
		SELECT DISTINCT device_names.ft_name as filter_name
		FROM APCSProDB.method.device_slips WITH (NOLOCK)
		INNER JOIN APCSProDB.method.device_versions WITH (NOLOCK)
			ON device_versions.device_id = device_slips.device_id
		INNER JOIN APCSProDB.method.device_names WITH (NOLOCK)
			ON device_names.id = device_versions.device_name_id
		WHERE device_names.ft_name IS NOT NULL
		ORDER BY device_names.ft_name
	END
END
