---- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_material_ogi_ai_001]
	-- Add the parameters for the stored procedure here
		@LotNo					NVARCHAR(10) 
		 ,@App_Name				NVARCHAR(20)
		 ,@OpNO				    NVARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	BEGIN TRY
			SELECT DISTINCT TOP(1) 'TRUE' AS Status, N'Success !!' AS Error_Message_ENG, N'ค้นหาสำเร็จ !!' AS Error_Message_THA, N'' AS Handling, 
			CASE WHEN (TUBE IS NULL and TRAY IS NULL) THEN 1 ELSE 0 END AS [REEL] 			
			,CASE WHEN pvt.id is null THEN 0
				  WHEN TRAY IS NULL THEN 0 ELSE  1 END AS [TRAY]
			,CASE WHEN pvt.id is null THEN 0
				  WHEN TUBE IS NULL THEN 0 ELSE  1 END AS [TUBE]
			,CASE WHEN pvt.id is null THEN 0 
				WHEN [SILIGA GEL] IS NULL THEN 0 ELSE use_qty END AS [SILIGAGEL] 
			,CASE WHEN pvt.id is null THEN 0 
				WHEN pvt.INDICATOR IS NULL THEN 0 ELSE  use_qty_indicator END AS [INDICATOR]
			,CASE WHEN pvt.id is null THEN 0 
				WHEN pvt.TOMSON IS NULL THEN 0 ELSE 1 END AS [TOMSON]		
			,CASE WHEN pvt.id is null THEN 0
				WHEN pvt.ALUMINUM IS NULL THEN 0 ELSE  use_qty_aluminum END AS [ALUMINUM]	
			,CASE WHEN pvt.id is null THEN 0
				WHEN [AIR BUBBLE] IS NULL THEN 0 ELSE use_qty_air END AS [AIRBUBBLE]
			,CASE WHEN pvt.id is null THEN 0  
				WHEN pvt.[SPACER] IS NULL THEN 0 ELSE use_qty_spacer END AS [SPACER]
			FROM APCSProDB.trans.lots INNER JOIN 
								   [APCSProDB].method.device_slips ON device_slips.device_slip_id = lots.device_slip_id 
								   INNER JOIN [APCSProDB].method.device_versions ON device_versions.device_id = device_slips.device_id 
								   AND [APCSProDB].method.device_slips.is_released = 1 							
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

		    LEFT JOIN (SELECT  ms.id,ms.name,comment,details,p.name as mat_name, CONVERT(int, use_qty) as use_qty
								FROM  [APCSProDB].method.material_sets ms 
								   INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id INNER JOIN
								   [APCSProDB].material.productions p ON ml.material_group_id = p.id LEFT JOIN
								   APCSProDB.method.item_labels il ON il.val = ml.use_qty_unit and il.name = 'material_set_list.use_qty_unit'
				  where (ms.process_id = 317 OR ms.process_id = 18) and details = 'SILIGA GEL'
				) AS m_qty ON m_qty.id = pvt.id

			LEFT JOIN (SELECT ms.id,ms.name,comment,details,p.name as mat_name,tomson_code, CONVERT(int, use_qty) as use_qty_aluminum
								FROM  [APCSProDB].method.material_sets ms 
								   INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id INNER JOIN
								   [APCSProDB].material.productions p ON ml.material_group_id = p.id
				  where (ms.process_id = 317 OR ms.process_id = 18) and details = 'ALUMINUM'
				) AS aluminum_qty ON aluminum_qty.id = pvt.id

			LEFT JOIN (SELECT ms.id,ms.name,comment,details,p.name as mat_name,tomson_code, CONVERT(int, use_qty) as use_qty_air
								FROM  [APCSProDB].method.material_sets ms 
								   INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id INNER JOIN
								   [APCSProDB].material.productions p ON ml.material_group_id = p.id
				  where (ms.process_id = 317 OR ms.process_id = 18) and details = 'AIR BUBBLE'
				) AS air_qty ON air_qty.id = pvt.id

			LEFT JOIN (SELECT ms.id,ms.name,comment,details,p.name as mat_name,tomson_code, CONVERT(int, use_qty) as use_qty_spacer
								FROM  [APCSProDB].method.material_sets ms 
								   INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id INNER JOIN
								   [APCSProDB].material.productions p ON ml.material_group_id = p.id
				  where (ms.process_id = 317 OR ms.process_id = 18) and details = 'SPACER'
				) AS spacer_qty ON aluminum_qty.id = pvt.id

			LEFT JOIN (SELECT  ms.id,ms.name,comment,details,p.name as mat_name, CONVERT(int, use_qty) as use_qty_indicator
			FROM [APCSProDB].method.material_sets ms 
			INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id 
			INNER JOIN [APCSProDB].material.productions p ON ml.material_group_id = p.id 
			LEFT JOIN APCSProDB.method.item_labels il ON il.val = ml.use_qty_unit and il.name = 'material_set_list.use_qty_unit'
			where (ms.process_id = 317 OR ms.process_id = 18) and details = 'INDICATOR'
			) AS indicator_qty ON indicator_qty.id = pvt.id

			LEFT JOIN [APCSProDB].[method].[jobs] AS [job] ON [job].[id] = device_flows.[job_id]
			WHERE device_flows.job_id in (317,412)
			and lot_no = @lotno 

	END TRY
	BEGIN CATCH
			SELECT 'FALSE' AS Status ,'Gat Data Error !!' AS Error_Message_ENG,N'ไม่พบข้อมูล !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
	END CATCH

END
