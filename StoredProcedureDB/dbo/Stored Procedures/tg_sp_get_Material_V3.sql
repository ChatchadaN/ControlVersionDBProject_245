-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_Material_V3]
	-- Add the parameters for the stored procedure here
	--@Device_Name char(20)
	@Assy_Name char(20) = ''
	,@Process_Name Char(50) = ''
	--,@Mat_Detail nvarchar(255)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @checkmat_name char(50);
    -- Insert statements for procedure here
	
	
		BEGIN TRY
		--NEW 2021/09/08
		--ใช้งานปัจจุบันคือตัวนี้
		--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			---NEW
			SELECT [device_slip_id]
					,[device_id]
					,[Package]
					,[device]
					,[device_type]
					,[job_id]
					,[job_deviceflow]
					,[material_set_id]
					,[materialSet]
					,[process_id]
					,CASE WHEN [ALUMINUM] = ' ' OR [ALUMINUM] IS NULL THEN 'NO USE' ELSE 'USE'  END AS [ALUMINUM]
					,CASE WHEN [INDICATOR] = ' ' OR [INDICATOR] IS NULL THEN 'NO USE' ELSE 'USE' END AS [INDICATOR]
					,CASE WHEN [TOMSON] = ' ' OR [TOMSON] IS NULL THEN 'NO USE' ELSE [TOMSON] END AS [TOMSON]
					,CASE WHEN [SILIGAGEL] = ' ' OR [SILIGAGEL] IS NULL THEN 'NO USE' ELSE [SILIGAGEL] END AS [SILIGAGEL]
					,CASE WHEN [AIRBUBBLE] = ' ' OR [AIRBUBBLE] IS NULL THEN 'NO USE' ELSE 'USE ' + SUBSTRING([AIRBUBBLE],CHARINDEX('(',[AIRBUBBLE]),LEN([AIRBUBBLE]) + 1) END AS [AIRBUBBLE]
					,CASE WHEN [SPACER] = ' ' OR [SPACER] IS NULL THEN 'NO USE' ELSE 'USE ' + SUBSTRING([SPACER],CHARINDEX('(',[SPACER]),LEN([SPACER]) + 1) END AS [SPACER]
					,CASE WHEN [REMARK1] IS NULL THEN ' ' ELSE [REMARK1] END AS [REMARK1]
					,CASE WHEN [REMARK2] IS NULL THEN ' ' ELSE [REMARK2] END AS [REMARK2]
					,'TRUE' AS [STATUS]
			FROM ( SELECT [ds].[device_slip_id]
						,[ds].[device_id]
						,[pk].[name] AS [Package]
						,[dn].[name] AS [device]
						,[d_vs].[device_type]
						,[job_id]
						,[job].[name] AS [job_deviceflow]
						,[dv_f].[material_set_id]
						,[mat_set].[name] AS [materialSet]
						,[mat_set].[process_id]
						,[REMARK1]
						,[REMARK2] 
					FROM [APCSProDB].[method].[device_names] AS [dn]
					INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [dn].[package_id] = [pk].[id]
					INNER JOIN [APCSProDB].[method].[device_versions] AS [d_vs] ON [dn].[id] = [d_vs].[device_name_id]
					INNER JOIN [APCSProDB].[method].[device_slips] AS [ds] ON [d_vs].[device_id] = [ds].[device_id]
 						AND [d_vs].[version_num] = [ds].[version_num]
 						AND [ds].[is_released] = 1 
 						AND [d_vs].[device_type] = 6
					INNER JOIN [APCSProDB].[method].[device_flows] AS [dv_f] ON [ds].[device_slip_id] = [dv_f].[device_slip_id]
 					INNER JOIN [APCSProDB].[method].[jobs] AS [job] ON [job].[id] = [dv_f].[job_id]
					LEFT JOIN [APCSProDB].[method].[material_sets] AS [mat_set] ON [mat_set].[id] = [dv_f].[material_set_id]
 						AND [mat_set].[process_id] = [dv_f].[job_id]
					LEFT JOIN StoredProcedureDB.dbo.IS_PACKING_MAT as pack_mat on dn.name = pack_mat.ROHM_Model_Name
					WHERE [ds].[is_released] = 1
						AND [dn].[assy_name] = @Assy_Name
						AND [job].[name] = @Process_Name
			) AS Table1
			LEFT JOIN (
				SELECT id, mat_name as [ALUMINUM]
				FROM (SELECT [mat_set_list].id
						,material_group_id
						,CAST(pd.name as nvarchar(50)) as mat_name
						,pd.details 
					FROM [APCSProDB].[method].[material_set_list]  AS [mat_set_list]
					INNER JOIN [APCSProDB].[material].[productions] AS [pd] ON [pd].[id] = [mat_set_list].[material_group_id]
					WHERE pd.details = 'ALUMINUM'
				) As table_alum
			) as [ALUMINUM_table] ON [ALUMINUM_table].[id] = [Table1].[material_set_id]
			LEFT JOIN (
				SELECT id, mat_name as [INDICATOR]
				FROM (SELECT [mat_set_list].id
						,material_group_id
						,CAST(pd.name as nvarchar(50)) as mat_name
						,pd.details 
					FROM [APCSProDB].[method].[material_set_list]  AS [mat_set_list]
					INNER JOIN [APCSProDB].[material].[productions] AS [pd] ON [pd].[id] = [mat_set_list].[material_group_id]
					WHERE pd.details = 'INDICATOR'
				) As table_ind
			) as [INDICATOR_table] ON [INDICATOR_table].[id] = [Table1].[material_set_id]
			LEFT JOIN (
				SELECT id, mat_name as [TOMSON]
				FROM (SELECT [mat_set_list].id
						,material_group_id
						,CAST(pd.name as nvarchar(50)) as mat_name
						,pd.details 
					FROM [APCSProDB].[method].[material_set_list]  AS [mat_set_list]
					INNER JOIN [APCSProDB].[material].[productions] AS [pd] ON [pd].[id] = [mat_set_list].[material_group_id]
					WHERE pd.details = 'TOMSON'
				) As table_tom
			) as [TOMSON_table] ON [TOMSON_table].[id] = [Table1].[material_set_id]
			LEFT JOIN (
				SELECT id, mat_name + ' ' +  CAST(CONVERT(int,qty) as varchar(1)) + ' ' + UPPER(unit) as [SILIGAGEL]
				FROM (SELECT [mat_set_list].id
						,material_group_id
						,CAST(pd.name as nvarchar(50)) as mat_name
						,pd.details 
						,mat_set_list.use_qty as qty
						,ib.label_eng as unit
					FROM [APCSProDB].[method].[material_set_list]  AS [mat_set_list]
					INNER JOIN [APCSProDB].[material].[productions] AS [pd] ON [pd].[id] = [mat_set_list].[material_group_id]
					LEFT JOIN APCSProDB.method.item_labels as ib on mat_set_list.use_qty_unit = ib.val 
						AND ib.name = 'material_set_list.use_qty_unit'
						AND ib.val  = '11'
					WHERE pd.details = 'SILIGA GEL'
				) As table_sil
			) as [SILIGAGEL_table] ON [SILIGAGEL_table].[id] = [Table1].[material_set_id]
			LEFT JOIN (
				SELECT id, mat_name as [AIRBUBBLE]
				FROM (SELECT [mat_set_list].id
						,material_group_id
						,CAST(pd.name as nvarchar(50)) as mat_name
						,pd.details 
					FROM [APCSProDB].[method].[material_set_list]  AS [mat_set_list]
					INNER JOIN [APCSProDB].[material].[productions] AS [pd] ON [pd].[id] = [mat_set_list].[material_group_id]
					WHERE pd.details = 'AIR BUBBLE'
				) As table_tom
			) as [AIRBUBBLE_table] ON [AIRBUBBLE_table].[id] = [Table1].[material_set_id]
			LEFT JOIN (
				SELECT id, mat_name as [SPACER]
				FROM (SELECT [mat_set_list].id
						,material_group_id
						,CAST(pd.name as nvarchar(50)) as mat_name
						,pd.details 
					FROM [APCSProDB].[method].[material_set_list]  AS [mat_set_list]
					INNER JOIN [APCSProDB].[material].[productions] AS [pd] ON [pd].[id] = [mat_set_list].[material_group_id]
					WHERE pd.details = 'SPACER'
				) As table_tom
			) as [SPACER_table] ON [SPACER_table].[id] = [Table1].[material_set_id]
			---NEW


			--/////////////// Auto Updata Slip Type A ////////////////////////////
			--เช็คว่า Slip Type A ของ device นี้เป็นค่าว่างไหม และ Slip Type D ของ device นี้ต้องไม่เป็นค่าว่าง
			IF( SELECT TOP (1) dv_f.material_set_id FROM [APCSProDB].[method].[device_names] AS [dn]
					INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [dn].[package_id] = [pk].[id]
					INNER JOIN [APCSProDB].[method].[device_versions] AS [d_vs] ON [dn].[id] = [d_vs].[device_name_id]
					INNER JOIN [APCSProDB].[method].[device_slips] AS [ds] ON [d_vs].[device_id] = [ds].[device_id]
 						AND [d_vs].[version_num] = [ds].[version_num]
 						AND [ds].[is_released] = 1 
 						AND [d_vs].[device_type] = 0
					INNER JOIN [APCSProDB].[method].[device_flows] AS [dv_f] ON [ds].[device_slip_id] = [dv_f].[device_slip_id]
			WHERE TRIM(dn.assy_name) = TRIM(@Assy_Name) and dv_f.job_id = 317) IS NULL AND
			(SELECT TOP (1) dv_f.material_set_id FROM [APCSProDB].[method].[device_names] AS [dn]
								INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [dn].[package_id] = [pk].[id]
								INNER JOIN [APCSProDB].[method].[device_versions] AS [d_vs] ON [dn].[id] = [d_vs].[device_name_id]
								INNER JOIN [APCSProDB].[method].[device_slips] AS [ds] ON [d_vs].[device_id] = [ds].[device_id]
 									AND [d_vs].[version_num] = [ds].[version_num]
 									AND [ds].[is_released] = 1 
 									AND [d_vs].[device_type] = 6
								INNER JOIN [APCSProDB].[method].[device_flows] AS [dv_f] ON [ds].[device_slip_id] = [dv_f].[device_slip_id]
			WHERE TRIM(dn.assy_name) = TRIM(@Assy_Name) and dv_f.job_id = 317) IS NOT NULL

			BEGIN
			--เก็บค่า material_set_id ของ Slip Type D ไปอัพเดทให้กับ Slip Type A 
				DECLARE @mat_id AS INT 
					SET @mat_id = (SELECT TOP (1) dv_f.material_set_id FROM [APCSProDB].[method].[device_names] AS [dn]
									INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [dn].[package_id] = [pk].[id]
									INNER JOIN [APCSProDB].[method].[device_versions] AS [d_vs] ON [dn].[id] = [d_vs].[device_name_id]
									INNER JOIN [APCSProDB].[method].[device_slips] AS [ds] ON [d_vs].[device_id] = [ds].[device_id]
 										AND [d_vs].[version_num] = [ds].[version_num]
 										AND [ds].[is_released] = 1 
 										AND [d_vs].[device_type] = 6
									INNER JOIN [APCSProDB].[method].[device_flows] AS [dv_f] ON [ds].[device_slip_id] = [dv_f].[device_slip_id]
					WHERE TRIM(dn.assy_name) = TRIM(@Assy_Name) and dv_f.job_id = 317)


					UPDATE APCSProDB.method.device_flows
						SET APCSProDB.method.device_flows.material_set_id = @mat_id

					FROM [APCSProDB].[method].[device_names] AS [dn]
												INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [dn].[package_id] = [pk].[id]
												INNER JOIN [APCSProDB].[method].[device_versions] AS [d_vs] ON [dn].[id] = [d_vs].[device_name_id]
												INNER JOIN [APCSProDB].[method].[device_slips] AS [ds] ON [d_vs].[device_id] = [ds].[device_id]
 													--AND [d_vs].[version_num] = [ds].[version_num]
 													AND [ds].[is_released] = 1 
 													AND [d_vs].[device_type] = 0
												INNER JOIN [APCSProDB].[method].[device_flows] AS [dv_f] ON [ds].[device_slip_id] = [dv_f].[device_slip_id]
					WHERE TRIM(dn.assy_name) = TRIM(@Assy_Name) and dv_f.job_id = 317

			END 
			--/////////////////////////////////////////////////////////////////////////


		--	SELECT [device_slip_id]
		--	,[device_id]
		--	,[Package]
		--	,[device]
		--	,[device_type]
		--	,[job_id]
		--	,[job_deviceflow]
		--	,[material_set_id]
		--	,[materialSet]
		--	,[process_id]
		--	--,[material_group_id]
		--	 --,[mat_name]
		--	,[ALUMINUM]
		--	,[INDICATOR]
		--	,[SILIGA GEL]
		--	,[AIR BUBBLE]
		--	,[SPACER]
		--	--,case when [ALUMINUM]  = ' ' or [ALUMINUM] is null then 'NO USE' else 'USE'  end as ALUMINUM
		--	--,case when [INDICATOR]  = ' ' or [INDICATOR] is null then 'NO USE' else 'USE'  end as INDICATOR
		--	--,case when [TOMSON]  = ' ' then ' ' else [TOMSON]  end as TOMSON
		--	--,case when [SILIGA GEL]  = ' ' or [SILIGA GEL] is null then 'NO USE' else CONCAT([SILIGA GEL],' ' + CAST(CONVERT(int,qty) as varchar(1)) + ' ' + unit)  end as SILIGAGEL
		--		--,case when [SILIGA GEL]  = ' ' or [SILIGA GEL] is null then 'NO USE' else [SILIGA GEL] end as SILIGAGEL
		--	--,case when [AIR BUBBLE]  = ' ' or [AIR BUBBLE] is null then 'NO USE' else 'USE'  end as AIRBUBBLE
		--	--,case when [SPACER]  = ' ' or [SPACER] is null then 'NO USE' else 'USE'  end as SPACER
		--	,REMARK1
		--	,REMARK2
		--		--,ISNULL([SPACER],'NO USE') as SPACER
		--	,case when @checkmat_name = 'NULL' then 'FALSE' else 'TURE' end as STATUS
		--FROM (	SELECT ds.device_slip_id 
		--			,ds.device_id
		--			,pk.name as Package
		--			,dn.name as device
		--			,d_vs.device_type
		--			,job_id
		--			,job.name as job_deviceflow
		--			,dv_f.material_set_id
		--			,mat_set.name as materialSet
		--			,mat_set.process_id
		--			--,mat_set_list.material_group_id
		--			,CAST(pd.name as nvarchar(50)) as mat_name
		--			,pd.details 
		--			--,mat_set_list.use_qty as qty
		--			--,ib.label_eng as unit
		--			,pack_mat.REMARK1 
		--			,pack_mat.REMARK2
		--		FROM  APCSProDB.method.device_names as dn
 	--			INNER JOIN APCSProDB.method.packages as pk ON dn.package_id = pk.id 
 	--			INNER JOIN APCSProDB.method.device_versions as d_vs ON dn.id = d_vs.device_name_id 
 	--			INNER JOIN APCSProDB.method.device_slips as ds ON d_vs.device_id = ds.device_id 
 	--				AND d_vs.version_num = ds.version_num 
 	--				AND ds.is_released = 1 
 	--				AND d_vs.device_type = 6 
 	--			INNER JOIN APCSProDB.method.device_flows as dv_f ON ds.device_slip_id = dv_f.device_slip_id
 	--			INNER JOIN APCSProDB.method.jobs as job ON job.id = dv_f.job_id
 	--			LEFT JOIN APCSProDB.method.material_sets as mat_set ON mat_set.id = dv_f.material_set_id 
 	--				AND mat_set.process_id = dv_f.job_id
 	--			INNER JOIN APCSProDB.method.material_set_list as mat_set_list ON mat_set_list.id = mat_set.id
 	--			INNER JOIN APCSProDB.material.productions as pd ON pd.id = mat_set_list.material_group_id
		--		--LEFT JOIN APCSProDB.method.item_labels as ib on mat_set_list.use_qty_unit = ib.val --and ib.name = 'material_set_list.use_qty_unit' --and ib.val  = '11'
		--		LEFT JOIN StoredProcedureDB.dbo.IS_PACKING_MAT as pack_mat on dn.name = pack_mat.ROHM_Model_Name
		--		WHERE (ds.is_released = 1) 
		--			AND dn.assy_name = @Assy_Name
		--			AND job.name = @Process_Name
		--		--AND pd.details = 'REEL' 
		--		--ORDER BY ds.device_slip_id
		--) As Table1
		--PIVOT
		--(
		--	max([mat_name])
		--	FOR details In([ALUMINUM],[INDICATOR],[TOMSON],[SILIGA GEL],[AIR BUBBLE],[SPACER])
		--) As Pivot1
	END TRY
	BEGIN CATCH
			SELECT 'FALSE' AS Status ,'Gat Data Error !!' AS Error_Message_ENG,N'ไม่พบข้อมูล !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
	END CATCH


	 

END
