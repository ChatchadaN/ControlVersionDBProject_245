-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_slipmaterialset_ogi]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT DISTINCT device_slips.device_slip_id,packages.name AS Package
	,device_names.name AS Device, device_names.assy_name, pvt.id AS Mat_id,device_slips.version_num AS slip_ver
	,CASE WHEN pvt.id is null THEN 'NOT REGISTERED' ELSE '' END AS STATUS
	,CASE WHEN pvt.id is null THEN '' ELSE ISNULL(TOMSON,'NO USE') END AS TOMSON_BOX
	,CASE WHEN (tb.reel_count IS NULL OR tb.reel_count = '') THEN '' ELSE CONCAT( tb.reel_count , ' reel') END AS reel_count
	,CASE WHEN pvt.id is null THEN ''
		WHEN [AIR BUBBLE] IS NULL THEN 'NO USE'
		WHEN CHARINDEX('(',[AIR BUBBLE]) > 0 THEN 'USE ' + SUBSTRING([AIR BUBBLE],CHARINDEX('(',[AIR BUBBLE]),LEN([AIR BUBBLE]) +1) 
		ELSE 'USE' END AS [AIR_BUBBLE]
	,CASE WHEN pvt.id is null THEN '' 
		WHEN [SILIGA GEL] IS NULL THEN 'NO USE' ELSE  'USE ' + ISNULL(m_qty.use_qty,'')  END AS [SILIGA_GEL] 
	,CASE WHEN pvt.id is null THEN '' 
		WHEN INDICATOR IS NULL THEN 'NO USE' ELSE  'USE' END AS INDICATOR
	,CASE WHEN pvt.id is null THEN ''  
		WHEN [SPACER] IS NULL THEN 'NO USE'
		WHEN CHARINDEX('(',[SPACER]) > 0 THEN 'USE ' + SUBSTRING([SPACER],CHARINDEX('(',[SPACER]),LEN([SPACER]) +1) 
		ELSE 'USE' END AS [SPACER]
	,CASE WHEN pvt.id is null THEN ''
		WHEN ALUMINUM IS NULL THEN 'NO USE' ELSE  'USE' END AS ALUMINUM
	,il.label_eng AS slip_type
	,CASE WHEN (device_names.is_incoming IS NULL OR device_names.is_incoming = '') THEN '' ELSE 'INCOMING' END AS is_incoming
	,CASE WHEN pvt.id is null THEN ''
		WHEN TUBE IS NULL THEN 'NO USE' ELSE  'USE' END AS TUBE
	,CASE WHEN pvt.id is null THEN ''
		WHEN TRAY IS NULL THEN 'NO USE' ELSE  'USE ' + ISNULL(tray_qty.use_qty,'')  END AS TRAY
	FROM 
	[APCSProDB].method.device_names INNER JOIN
						   [APCSProDB].method.packages ON [APCSProDB].method.device_names.package_id = [APCSProDB].method.packages.id INNER JOIN
						   [APCSProDB].method.device_versions ON [APCSProDB].method.device_names.id = [APCSProDB].method.device_versions.device_name_id INNER JOIN
						   [APCSProDB].method.device_slips ON [APCSProDB].method.device_versions.device_id = [APCSProDB].method.device_slips.device_id 
						   --AND method.device_versions.version_num = method.device_slips.version_num 
						   AND [APCSProDB].method.device_slips.is_released = 1

						   --AND [APCSProDB].method.device_versions.device_type = 6
						   INNER JOIN
						   [APCSProDB].method.device_flows ON [APCSProDB].method.device_slips.device_slip_id = [APCSProDB].method.device_flows.device_slip_id
	LEFT JOIN  
	(SELECT ms.id,ms.name,comment,details,p.name as mat_name
	FROM      			   [APCSProDB].method.material_sets ms 
						   INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id INNER JOIN
						   [APCSProDB].material.productions p ON ml.material_group_id = p.id 
		  where (ms.process_id = 317 OR ms.process_id = 18)
		) mat

	PIVOT ( 
		max(mat_name)
		FOR details
		IN (
		[TOMSON],[AIR BUBBLE],[ALUMINUM],[INDICATOR],[SILIGA GEL],[SPACER],[TUBE],[TRAY]
		)
	) as pvt ON [APCSProDB].method.device_flows.material_set_id = pvt.id

	LEFT JOIN (SELECT  ms.id,ms.name,comment,details,p.name as mat_name, CONVERT(VARCHAR(10), CONVERT(int, use_qty)) + ' '+ il.label_eng as use_qty
						FROM  [APCSProDB].method.material_sets ms 
						   INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id INNER JOIN
						   [APCSProDB].material.productions p ON ml.material_group_id = p.id LEFT JOIN
						   APCSProDB.method.item_labels il ON il.val = ml.use_qty_unit and il.name = 'material_set_list.use_qty_unit'
		  where (ms.process_id = 317 OR ms.process_id = 18) and details = 'SILIGA GEL'
		) AS m_qty ON m_qty.id = pvt.id
	LEFT JOIN (SELECT  ms.id,ms.name,comment,details,p.name as mat_name, CONVERT(VARCHAR(10), CONVERT(int, use_qty)) + ' '+ il.label_eng as use_qty
						FROM  [APCSProDB].method.material_sets ms 
						   INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id INNER JOIN
						   [APCSProDB].material.productions p ON ml.material_group_id = p.id LEFT JOIN
						   APCSProDB.method.item_labels il ON il.val = ml.use_qty_unit and il.name = 'material_set_list.use_qty_unit'
		  where (ms.process_id = 317 OR ms.process_id = 18) and details = 'TRAY'
		) AS tray_qty ON tray_qty.id = pvt.id
	LEFT JOIN APCSProDB.method.item_labels il ON il.val = device_versions.device_type AND il.name = 'device_versions.device_type'
	LEFT JOIN (SELECT msl.id,msl.tomson_code,ib.reel_count FROM APCSProDB.method.material_set_list msl
				LEFT JOIN APCSProDB.method.incoming_boxs ib ON ib.tomson_code = msl.tomson_code AND ib.idx = 1
				WHERE msl.tomson_code IS NOT NULL) AS tb ON tb.id = pvt.id
	WHERE device_flows.job_id = 317
	ORDER BY packages.name,device_names.name
END
