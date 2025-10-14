-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_Material_v2]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10) = ''
    ,@Assy_Name char(20) = '',
	@Process_Name Char(50) = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @checkmat_name char(50);
    -- Insert statements for procedure here
	
	
		BEGIN TRY
			---NEW
			SELECT DISTINCT device_slips.device_slip_id,device_slips.device_id,packages.name AS Package,device_names.name AS device
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
			,CASE WHEN [REMARK1] IS NULL THEN ' ' ELSE [REMARK1] END AS [REMARK1]
			,CASE WHEN [REMARK2] IS NULL THEN ' ' ELSE [REMARK2] END AS [REMARK2]
			,'TRUE' AS [STATUS]
			,CASE WHEN device_names.is_incoming IS NULL THEN 0 ELSE device_names.is_incoming END AS is_incoming
			,tomson_box.tomson_code
			FROM APCSProDB.trans.lots INNER JOIN 
								   [APCSProDB].method.device_slips ON device_slips.device_slip_id = lots.device_slip_id INNER JOIN
								   [APCSProDB].method.device_versions ON device_versions.device_id = device_slips.device_id 
								   AND [APCSProDB].method.device_slips.is_released = 1 
							
								   AND device_versions.device_type = 6 --- comment ถ้าใช้เลข Lot ในการเรียก Store แล้ว
								   INNER JOIN
								   [APCSProDB].method.device_names ON [APCSProDB].method.device_names.id = [APCSProDB].method.device_versions.device_name_id INNER JOIN
								   [APCSProDB].method.packages ON [APCSProDB].method.device_names.package_id = [APCSProDB].method.packages.id INNER JOIN					   
								   [APCSProDB].method.device_flows ON [APCSProDB].method.device_slips.device_slip_id = [APCSProDB].method.device_flows.device_slip_id
			LEFT JOIN  
			(SELECT  ms.id,ms.name,comment,details,p.name as mat_name
			FROM      			   [APCSProDB].method.material_sets ms 
								   INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id INNER JOIN
								   [APCSProDB].material.productions p ON ml.material_group_id = p.id 
				  where ms.process_id = 317 
				) mat

			PIVOT ( 
				max(mat_name)
				FOR details
				IN (
				[TOMSON],[AIR BUBBLE],[ALUMINUM],[INDICATOR],[SILIGA GEL],[SPACER]
				)
			) as pvt ON [APCSProDB].method.device_flows.material_set_id = pvt.id

			LEFT JOIN (SELECT  ms.id,ms.name,comment,details,p.name as mat_name, CONVERT(VARCHAR(10), CONVERT(int, use_qty)) + ' '+ il.label_eng as use_qty
								FROM  [APCSProDB].method.material_sets ms 
								   INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id INNER JOIN
								   [APCSProDB].material.productions p ON ml.material_group_id = p.id LEFT JOIN
								   APCSProDB.method.item_labels il ON il.val = ml.use_qty_unit and il.name = 'material_set_list.use_qty_unit'
				  where ms.process_id = 317 and details = 'SILIGA GEL'
				) AS m_qty ON m_qty.id = pvt.id

			LEFT JOIN (SELECT ms.id,ms.name,comment,details,p.name as mat_name,tomson_code
								FROM  [APCSProDB].method.material_sets ms 
								   INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id INNER JOIN
								   [APCSProDB].material.productions p ON ml.material_group_id = p.id
				  where ms.process_id = 317 and details = 'TOMSON'
				) AS tomson_box ON tomson_box.id = pvt.id

			LEFT JOIN StoredProcedureDB.dbo.IS_PACKING_MAT as pack_mat on device_names.name = pack_mat.ROHM_Model_Name
			LEFT JOIN [APCSProDB].[method].[jobs] AS [job] ON [job].[id] = device_flows.[job_id]

			WHERE device_flows.job_id = 317 
			--and lot_no = @lot_no --- uncomment ถ้าใช้เลข Lot ในการเรียก Store แล้ว
			and device_names.assy_name = @Assy_Name --- comment ถ้าใช้เลข Lot ในการเรียก Store แล้ว
			ORDER BY packages.name,device_names.name
		END TRY
	BEGIN CATCH
			SELECT 'FALSE' AS Status ,'Gat Data Error !!' AS Error_Message_ENG,N'ไม่พบข้อมูล !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
	END CATCH
END


--SELECT lots.lot_no,lots.device_slip_id,jobs.id,p.name,dn.is_incoming,ml.tomson_code,ib.idx,ib.remark,ib.reel_count
--FROM APCSProDB.trans.lots INNER JOIN 
--								   [APCSProDB].method.device_slips ds ON ds.device_slip_id = lots.device_slip_id INNER JOIN
--								   [APCSProDB].method.device_versions dv ON dv.device_id = ds.device_id 
--								   AND ds.is_released = 1 

--								   INNER JOIN
--								   [APCSProDB].method.device_names dn ON dn.id = dv.device_name_id INNER JOIN
--								   [APCSProDB].method.packages pk ON dn.package_id = pk.id INNER JOIN					   
--								   [APCSProDB].method.device_flows df ON ds.device_slip_id = df.device_slip_id
--								   LEFT JOIN [APCSProDB].[method].[jobs] ON jobs.[id] = df.[job_id] 
--								   LEFT JOIN [APCSProDB].method.material_sets ms ON ms.id = df.material_set_id
--								   INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id 
--						           INNER JOIN [APCSProDB].material.productions p ON ml.material_group_id = p.id
--								   INNER JOIN [APCSProDB].method.incoming_boxs ib ON ib.tomson_code = ml.tomson_code

--WHERE lots.lot_no = '2128A6608V' and jobs.id = 317 and p.details = 'TOMSON'