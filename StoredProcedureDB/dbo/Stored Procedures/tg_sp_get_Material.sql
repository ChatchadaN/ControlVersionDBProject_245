-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_Material]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10) = ''
    ,@Assy_Name char(20) = ''
	,@Process_Name Char(50) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @checkmat_name char(50);
	DECLARE @device_name VARCHAR(50);
    -- Insert statements for procedure here


		BEGIN TRY
			--Update Query 2021/09/08
			---NEW
			SELECT DISTINCT TOP(1) device_slips.device_slip_id,device_slips.device_id,packages.name AS Package,device_names.name AS device
			--, device_names.assy_name
			,device_versions.device_type,device_flows.job_id,job.name AS job_deviceflow
			, pvt.id AS material_set_id,pvt.name AS materialSet,job.id AS process_id
			--,device_slips.version_num AS slip_ver
			,CASE WHEN pvt.id is null THEN ''
				WHEN pvt.ALUMINUM IS NULL THEN 'NO USE' ELSE  'USE' END AS ALUMINUM
			,CASE WHEN pvt.id is null THEN '' 
				WHEN pvt.INDICATOR IS NULL THEN 'NO USE' ELSE  'USE' END AS INDICATOR
			,CASE WHEN pvt.id is null THEN '' ELSE ISNULL(TOMSON,'NO USE') END AS TOMSON
			,CASE WHEN pvt.id is null THEN '' 
				WHEN [SILIGA GEL] IS NULL THEN 'NO USE' ELSE  'USE ' + ISNULL(use_qty,'')  END AS [SILIGAGEL] 
			,CASE WHEN pvt.id is null THEN ''
				WHEN [AIR BUBBLE] IS NULL THEN 'NO USE'
				WHEN CHARINDEX('(',[AIR BUBBLE]) > 0 THEN 'USE ' + SUBSTRING([AIR BUBBLE],CHARINDEX('(',[AIR BUBBLE]),LEN([AIR BUBBLE]) +1) 
				ELSE 'USE' END AS [AIRBUBBLE]

			,CASE WHEN pvt.id is null THEN ''  
				WHEN pvt.[SPACER] IS NULL THEN 'NO USE'
				WHEN CHARINDEX('(',pvt.[SPACER]) > 0 THEN 'USE ' + SUBSTRING(pvt.[SPACER],CHARINDEX('(',pvt.[SPACER]),LEN(pvt.[SPACER]) +1) 
				ELSE 'USE' END AS [SPACER]
			,'' AS [REMARK1]-- updata by AUN 2024/03/16
			,'' AS [REMARK2]
			--,CASE WHEN [REMARK1] IS NULL THEN ' ' ELSE [REMARK1] END AS [REMARK1]
			--,CASE WHEN [REMARK2] IS NULL THEN ' ' ELSE [REMARK2] END AS [REMARK2]
			,'TRUE' AS [STATUS]
			,CASE WHEN device_names.is_incoming IS NULL THEN 0 ELSE device_names.is_incoming END AS is_incoming
			,tomson_box.tomson_code
			--Add Data Tray Tube Create : 2021/10/26
			,CASE WHEN pvt.id is null THEN ''
				  WHEN TUBE IS NULL THEN 'NO USE' ELSE  'USE' END AS TUBE
			,CASE WHEN pvt.id is null THEN ''
				  WHEN TRAY IS NULL THEN 'NO USE' ELSE  'USE ' END AS TRAY
			--,REPLACE(ISNULL(tray_qty.use_qty_tray,''),' set','') AS count_qty_set_tray
			--,CAST( (device_names.pcs_per_pack / REPLACE(ISNULL(tray_qty.use_qty_tray,''),' set','')) as int) as std_set_tray_qty
			,CASE WHEN tray_qty.use_qty_tray is null THEN 0 
				  ELSE CAST((device_names.pcs_per_pack / REPLACE(ISNULL(tray_qty.use_qty_tray,''),' set','')) as int) END as std_set_tray_qty
			,pcs_per_pack  --add 2022/08/22 time : 14.36
			,CASE WHEN (TUBE IS NULL and TRAY IS NULL) THEN 'USE' ELSE 'NO USE' END AS REEL --add 2024/05/31 time : 10.45 by Aomsin
			,CASE WHEN package_groups.name = 'SMALL' THEN 'YES' ELSE 'NO' END AS IS_SMALL --add 2024/05/31 time : 10.45 by Aomsin
			FROM APCSProDB.trans.lots INNER JOIN 
								   [APCSProDB].method.device_slips ON device_slips.device_slip_id = lots.device_slip_id 
								   INNER JOIN [APCSProDB].method.device_versions ON device_versions.device_id = device_slips.device_id 
								   AND [APCSProDB].method.device_slips.is_released = 1 
							
								   --AND device_versions.device_type = 6 --- comment ถ้าใช้เลข Lot ในการเรียก Store แล้ว
								   INNER JOIN [APCSProDB].method.device_names ON [APCSProDB].method.device_names.id = [APCSProDB].method.device_versions.device_name_id 
								   INNER JOIN [APCSProDB].method.packages ON [APCSProDB].method.device_names.package_id = [APCSProDB].method.packages.id 
								   INNER JOIN [APCSProDB].method.package_groups ON [APCSProDB].method.packages.package_group_id = [APCSProDB].method.package_groups.id 
								   INNER JOIN [APCSProDB].method.device_flows ON [APCSProDB].method.device_slips.device_slip_id = [APCSProDB].method.device_flows.device_slip_id
			LEFT JOIN  
			(SELECT  ms.id,ms.name,comment,details,p.name as mat_name
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

			LEFT JOIN (SELECT ms.id,ms.name,comment,details,p.name as mat_name,tomson_code
								FROM  [APCSProDB].method.material_sets ms 
								   INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id INNER JOIN
								   [APCSProDB].material.productions p ON ml.material_group_id = p.id
				  where (ms.process_id = 317 OR ms.process_id = 18) and details = 'TOMSON'
				) AS tomson_box ON tomson_box.id = pvt.id

			--Add Data Tray Tube Create : 2021/10/26
			LEFT JOIN (SELECT  ms.id,ms.name,comment,details,p.name as mat_name, CONVERT(VARCHAR(10), CONVERT(int, use_qty)) + ' '+ il.label_eng as use_qty_tray 
			FROM [APCSProDB].method.material_sets ms 
			INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id 
			INNER JOIN [APCSProDB].material.productions p ON ml.material_group_id = p.id 
			LEFT JOIN APCSProDB.method.item_labels il ON il.val = ml.use_qty_unit and il.name = 'material_set_list.use_qty_unit'
			where (ms.process_id = 317 OR ms.process_id = 18) and details = 'TRAY'
			) AS tray_qty ON tray_qty.id = pvt.id

			--LEFT JOIN StoredProcedureDB.dbo.IS_PACKING_MAT as pack_mat on device_names.name = pack_mat.ROHM_Model_Name -- updata by AUN 2024/03/16
			LEFT JOIN [APCSProDB].[method].[jobs] AS [job] ON [job].[id] = device_flows.[job_id]

			WHERE device_flows.job_id in (317,412)
			and lot_no = @lot_no --- uncomment ถ้าใช้เลข Lot ในการเรียก Store แล้ว 2021/11/02 by aun
			--and device_names.assy_name = @Assy_Name --and device_names.name = @device_name -- comment ถ้าใช้เลข Lot ในการเรียก Store แล้ว
			--and pvt.id IS NOT NULL --- comment ถ้าใช้เลข Lot ในการเรียก Store แล้ว
			ORDER BY packages.name,device_names.name

	END TRY
	BEGIN CATCH
			SELECT 'FALSE' AS Status ,'Gat Data Error !!' AS Error_Message_ENG,N'ไม่พบข้อมูล !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
	END CATCH


	 

END
