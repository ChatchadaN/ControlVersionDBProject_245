CREATE FUNCTION [atom].[fnc_tg_sp_get_Material](
	@lot_no varchar(10)
)
    RETURNS @table table (
		device_slip_id int
		, device_id int
		, Package varchar(20)
		, device  varchar(20)
		, device_type int
		, job_id int
		, job_deviceflow varchar(30)
		, material_set_id int
		, materialSet varchar(20)
		, process_id int
		, ALUMINUM nvarchar(20)
		, INDICATOR nvarchar(20)
		, TOMSON nvarchar(20)
		, SILIGAGEL nvarchar(20)
		, AIRBUBBLE nvarchar(20)
		, SPACER nvarchar(20)
		--, REMARK1 nvarchar(50)
		--, REMARK2 nvarchar(50)
		, STATUS nvarchar(20)
		, is_incoming int
		, tomson_code nvarchar(20)
		, TUBE nvarchar(20)
		, TRAY nvarchar(20)
	)
AS
BEGIN
    insert into @table
	(
		device_slip_id 
		, device_id 
		, Package 
		, device  
		, device_type 
		, job_id 
		, job_deviceflow 
		, material_set_id 
		, materialSet 
		, process_id 
		, ALUMINUM 
		, INDICATOR 
		, TOMSON 
		, SILIGAGEL 
		, AIRBUBBLE 
		, SPACER 
		--, REMARK1 
		--, REMARK2 
		, STATUS 
		, is_incoming 
		, tomson_code 
		, TUBE 
		, TRAY
	)
	SELECT DISTINCT TOP(1) device_slips.device_slip_id
		, device_slips.device_id
		, packages.name AS Package
		, device_names.name AS device
		--, device_names.assy_name
		, device_versions.device_type
		, device_flows.job_id,job.name AS job_deviceflow
		, pvt.id AS material_set_id
		, pvt.name AS materialSet
		, job.id AS process_id
		--, device_slips.version_num AS slip_ver
		, CASE WHEN pvt.id is null THEN ''
			WHEN pvt.ALUMINUM IS NULL THEN 'NO USE' ELSE  'USE' END AS ALUMINUM
		, CASE WHEN pvt.id is null THEN '' 
			WHEN pvt.INDICATOR IS NULL THEN 'NO USE' ELSE  'USE' END AS INDICATOR
		, CASE WHEN pvt.id is null THEN '' ELSE ISNULL(TOMSON,'NO USE') END AS TOMSON
		, CASE WHEN pvt.id is null THEN '' 
		WHEN [SILIGA GEL] IS NULL THEN 'NO USE' ELSE  N'USE ' + ISNULL(use_qty,'')  END AS [SILIGAGEL] 
		, CASE WHEN pvt.id is null THEN ''
			WHEN [AIR BUBBLE] IS NULL THEN 'NO USE'
			WHEN CHARINDEX('(',[AIR BUBBLE]) > 0 THEN N'USE ' + SUBSTRING([AIR BUBBLE],CHARINDEX('(',[AIR BUBBLE]),LEN([AIR BUBBLE]) +1) 
		ELSE 'USE' END AS [AIRBUBBLE]
		,CASE WHEN pvt.id is null THEN ''  
			WHEN pvt.[SPACER] IS NULL THEN 'NO USE'
			WHEN CHARINDEX('(',pvt.[SPACER]) > 0 THEN N'USE ' + SUBSTRING(pvt.[SPACER],CHARINDEX('(',pvt.[SPACER]),LEN(pvt.[SPACER]) +1) 
			ELSE 'USE' END AS [SPACER]
		--, CASE WHEN [REMARK1] IS NULL THEN ' ' ELSE [REMARK1] END AS [REMARK1]
		--, CASE WHEN [REMARK2] IS NULL THEN ' ' ELSE [REMARK2] END AS [REMARK2]
		, 'TRUE' AS [STATUS]
		, CASE WHEN device_names.is_incoming IS NULL THEN 0 ELSE device_names.is_incoming END AS is_incoming
		, tomson_box.tomson_code
		--Add Data Tray Tube Create : 2021/10/26
		, CASE WHEN pvt.id is null THEN ''
				WHEN TUBE IS NULL THEN 'NO USE' ELSE  'USE' END AS TUBE
		, CASE WHEN pvt.id is null THEN ''
				WHEN TRAY IS NULL THEN 'NO USE' ELSE  'USE ' END AS TRAY
	FROM APCSProDB.trans.lots 
	INNER JOIN [APCSProDB].method.device_slips ON device_slips.device_slip_id = lots.device_slip_id 
	INNER JOIN [APCSProDB].method.device_versions ON device_versions.device_id = device_slips.device_id 
		AND [APCSProDB].method.device_slips.is_released = 1 
		--AND device_versions.device_type = 6 --- comment ถ้าใช้เลข Lot ในการเรียก Store แล้ว
	INNER JOIN [APCSProDB].method.device_names ON [APCSProDB].method.device_names.id = [APCSProDB].method.device_versions.device_name_id 
	INNER JOIN [APCSProDB].method.packages ON [APCSProDB].method.device_names.package_id = [APCSProDB].method.packages.id
	INNER JOIN [APCSProDB].method.device_flows ON [APCSProDB].method.device_slips.device_slip_id = [APCSProDB].method.device_flows.device_slip_id
	LEFT JOIN (
		SELECT ms.id,ms.name,comment,details,p.name as mat_name
		FROM [APCSProDB].method.material_sets ms 
		INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id
		INNER JOIN [APCSProDB].material.productions p ON ml.material_group_id = p.id 
		where (ms.process_id = 317 OR ms.process_id = 18)
	) mat
	PIVOT ( 
		max(mat_name)
		FOR details
		IN (
			[TOMSON],[AIR BUBBLE],[ALUMINUM],[INDICATOR],[SILIGA GEL],[SPACER],[TUBE],[TRAY]
		)
	) as pvt ON [APCSProDB].method.device_flows.material_set_id = pvt.id
	LEFT JOIN (
		SELECT  ms.id,ms.name,comment,details,p.name as mat_name, CONVERT(VARCHAR(10), CONVERT(int, use_qty)) + ' '+ il.label_eng as use_qty
		FROM [APCSProDB].method.material_sets ms 
		INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id
		INNER JOIN [APCSProDB].material.productions p ON ml.material_group_id = p.id
		LEFT JOIN APCSProDB.method.item_labels il ON il.val = ml.use_qty_unit and il.name = 'material_set_list.use_qty_unit'
		where (ms.process_id = 317 OR ms.process_id = 18) and details = 'SILIGA GEL'
	) AS m_qty ON m_qty.id = pvt.id
	LEFT JOIN (
		SELECT ms.id,ms.name,comment,details,p.name as mat_name,tomson_code
		FROM [APCSProDB].method.material_sets ms 
		INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id
		INNER JOIN [APCSProDB].material.productions p ON ml.material_group_id = p.id
		where (ms.process_id = 317 OR ms.process_id = 18) and details = 'TOMSON'
	) AS tomson_box ON tomson_box.id = pvt.id
	--Add Data Tray Tube Create : 2021/10/26
	LEFT JOIN (
		SELECT  ms.id,ms.name,comment,details,p.name as mat_name, CONVERT(VARCHAR(10), CONVERT(int, use_qty)) + ' '+ il.label_eng as use_qty_tray 
		FROM [APCSProDB].method.material_sets ms 
		INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id 
		INNER JOIN [APCSProDB].material.productions p ON ml.material_group_id = p.id 
		LEFT JOIN APCSProDB.method.item_labels il ON il.val = ml.use_qty_unit and il.name = 'material_set_list.use_qty_unit'
		where (ms.process_id = 317 OR ms.process_id = 18) and details = 'TRAY'
	) AS tray_qty ON tray_qty.id = pvt.id

	--LEFT JOIN StoredProcedureDB.dbo.IS_PACKING_MAT as pack_mat on device_names.name = pack_mat.ROHM_Model_Name
	LEFT JOIN [APCSProDB].[method].[jobs] AS [job] ON [job].[id] = device_flows.[job_id]

	WHERE device_flows.job_id = 317 
		and lot_no = @lot_no --- uncomment ถ้าใช้เลข Lot ในการเรียก Store แล้ว 2021/11/02 by aun
		--and device_names.assy_name = @Assy_Name --and device_names.name = @device_name -- comment ถ้าใช้เลข Lot ในการเรียก Store แล้ว
		--and pvt.id IS NOT NULL --- comment ถ้าใช้เลข Lot ในการเรียก Store แล้ว
	ORDER BY packages.name,device_names.name

    return;
END;