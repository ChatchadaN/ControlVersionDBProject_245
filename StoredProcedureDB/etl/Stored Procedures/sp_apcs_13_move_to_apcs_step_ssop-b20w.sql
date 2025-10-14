


-- =============================================
-- Author:		<K.Kuroda>
-- Create date: <10th Dec 2018>
-- Description:	<Move trans.lots to APCS's step>
-- =============================================
Create PROCEDURE [etl].[sp_apcs_13_move_to_apcs_step_ssop-b20w] 
as



update [APCSProDB].[trans].[lots]  
set step_no = t1.dest_step_no 
	,act_job_id = t1.dest_job_id 
	,act_process_id = t1.dest_process_id
from [APCSProDB].[trans].[lots] as lt 
	inner join (
			SELECT lots.id as lot_id,lots.lot_no,lots.step_no
					,[jobs].[name] as PRO_FLOW,L3.[OPE_NAME] as APCS_FLOW
					, item_labels1.label_eng as PRO_STATE
					,df.step_no as dest_step_no
					,j.process_id as dest_process_id 
					,j.id as dest_job_id 
			  FROM [APCSProDB].[trans].[lots]  
			  inner join OPENDATASOURCE('SQLNCLI', 'Data Source = 172.16.0.102;User ID=dbxuser;').[APCSDB].[dbo].[LOT1_TABLE] as L1 on lots.lot_no = L1.[LOT_NO]
			  inner join OPENDATASOURCE('SQLNCLI', 'Data Source = 172.16.0.102;User ID=dbxuser;').[APCSDB].[dbo].[LOT1_DATA] as L2 on lots.lot_no = L2.[LOT_NO] and L1.[OPE_SEQ] = L2.[OPE_SEQ]
			  inner join OPENDATASOURCE('SQLNCLI', 'Data Source = 172.16.0.102;User ID=dbxuser;').[APCSDB].[dbo].[LAYER_TABLE] as L3 on L3.[LAY_NO] = L2.[LAY_NO]
			  inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [lots].[act_job_id]
			  inner join [APCSProDB].[method].[packages] on [packages].[id] = [lots].[act_package_id]
			  inner join [APCSProDB].[trans].[item_labels] as [item_labels1] on [item_labels1].[name] = 'lots.wip_state' and [item_labels1].[val] = [lots].[wip_state] 
			  inner join [APCSProDB].[method].[device_flows] as df 
				on df.device_slip_id = lots.device_slip_id 
			  inner join [APCSProDB].[method].[jobs] as j 
				on j.id = df.job_id 
					and j.name = l3.[ope_name]
			  where [item_labels1].[val] in ('20') and [APCSProDB].[method].[packages].[is_enabled] = 1 
				and L3.[OPE_NAME] != [APCSProDB].[method].[jobs].[name] and [APCSProDB].[method].[packages].[name] = 'SSOP-B20W'
			  and L3.[LAY_NO] != '0101' and [is_imported] = 1 and lots.step_no < df.step_no
			) as t1 /* similar to sp_temp_check_flow */
		on t1.lot_id = lt.id 


RETURN 0;



