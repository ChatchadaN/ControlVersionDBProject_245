
------------------------------ Creater Rule ------------------------------
-- Project Name				: MDN
-- Author Name              : Sadanun.B
-- Written Date             : 2021/11/23
-- Procedure Name 	 		: [mdm].[sp_get_DeciceSlip]
-- Filename					: mdm.sp_get_DeciceSlip.sql
-- Database Referd			: APCSProDB
-- Tables Refered			: method.device_slips
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [mdm].[sp_get_DeviceSlips]
(
	@id		INT		= NULL
 
)
As
Begin

	SET NOCOUNT ON

SELECT	  DISTINCT  
		  SLIP.device_slip_id	AS [Device_Slips_ID]
		, FLOW.id				AS device_flow_id 
		, RTRIM(PACK.name)		AS Package
		, RTRIM(DEVICE.name)	AS [Device]
		, RTRIM(DEVICE.ft_name)	AS [FTDevice]
		, DEVICE.tp_rank		AS [TPRank]
		, FLOW.is_skipped		AS Is_Skipped
		, SLIP.version_num		AS [Version]
		, FLOW.job_id			
		, PROCESS.id			AS Process_id 
		, PROCESS.name			AS Process_Name 
		, JOBS.name				AS [Operation]
		, FLOW.step_no			AS [Step]
		, FLOW.recipe
		, CASE WHEN FLOW.[is_skipped] = 1 THEN '#c7c7c7' ELSE '#ADD8E6'  END as [Color_Label]
		, FLOW.lead_time		AS [Lead_time]
		, FLOW.lead_time_sum	AS [Lead_time_sum]
		, FLOW.material_set_id	AS [Material_set]
		, FLOW.jig_set_id		AS [Jig_set]
		, CASE WHEN FLOW.is_sblsyl = 1 THEN 'SBLSYL' ELSE '-' END   [Flow_sblsyl]
		, SLIP.is_released		AS [IsReased]
		, FLOW.permitted_machine_id 

		, FLOW.next_step_no
		, CASE WHEN FLOW.process_minutes IS NULL THEN 0 ELSE FLOW.process_minutes END process_minutes
		, CASE WHEN FLOW.sum_process_minutes IS NULL THEN 0 ELSE FLOW.sum_process_minutes END sum_process_minutes
		, CASE WHEN FLOW.ng_retest_permitted IS NULL THEN 0 ELSE FLOW.ng_retest_permitted END [ng_retest_permitted]
		, CASE WHEN FLOW.issue_label_type IS NULL THEN 0 ELSE FLOW.issue_label_type END [issue_label_type]
		, FLOW.bincode_set_id
		, CASE WHEN FLOWSBLSYL.sbl_upper_limit IS NULL THEN 0 ELSE FLOWSBLSYL.sbl_upper_limit END sbl_upper_limit
		, CASE WHEN FLOWSBLSYL.syl_lower_limit IS NULL THEN 0 ELSE FLOWSBLSYL.syl_lower_limit END syl_lower_limit

FROM   APCSProDB.method.device_slips				SLIP	(NOLOCK)
INNER JOIN APCSProDB.method.device_versions			VER		(NOLOCK)
ON VER.device_id				= SLIP.device_id
INNER JOIN APCSProDB.method.device_names			DEVICE	(NOLOCK)
ON DEVICE.id					= VER.device_name_id
INNER JOIN APCSProDB.method.packages				PACK	(NOLOCK)
ON PACK.id						= DEVICE.package_id
INNER JOIN APCSProDB.method.device_flows			FLOW	(NOLOCK)
ON FLOW.device_slip_id			= SLIP.device_slip_id
INNER JOIN APCSProDB.method.jobs					JOBS	(NOLOCK)
ON FLOW.job_id					=  jobs.id
INNER JOIN APCSProDB.method.processes				PROCESS (NOLOCK)
ON JOBS.process_id				= PROCESS.id 
INNER JOIN APCSProDB.method.item_labels 
ON item_labels.name				= 'device_versions.device_type' 
AND  VER.device_type			=  item_labels.val
LEFT JOIN APCSProDB.method.device_flows_sblsyl		FLOWSBLSYL (NOLOCK)
ON FLOWSBLSYL.device_flow_id	= FLOW.id

WHERE	SLIP.device_slip_id		= @id
ORDER BY FLOW.step_no ASC

SET NOCOUNT OFF 
END
 