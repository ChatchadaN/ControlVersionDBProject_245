
------------------------------ Creater Rule ------------------------------
-- Project Name				: MDM
-- Author Name              : Chatchadaporn N
-- Written Date             : 2024/06/24
-- Procedure Name 	 		: [mdm].[sp_get_DeciceFlow_sblsyl]
-- Filename					: mdm.sp_get_DeciceFlow_sblsyl.sql
-- Database Referd			: APCSProDB
-- Tables Refered			: method.device_slips
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [mdm].[sp_get_DeciceFlow_sblsyl]
(
	  @device				NVARCHAR(MAX)	= NULL
	, @Package				NVARCHAR(MAX)	= NULL
	, @devicetype			NVARCHAR(MAX)	= NULL
	, @assyname				NVARCHAR(MAX)	= NULL
	, @ftname				NVARCHAR(MAX)	= NULL
	, @isreased				NVARCHAR(MAX)	= NULL 
	, @version				NVARCHAR(MAX)	= NULL

)

As
Begin

	SET NOCOUNT ON
	
	SELECT	  DISTINCT  
			  SLIP.device_slip_id	AS [Device_Slips_ID]
			, RTRIM(PACK.name)		AS Package
			, RTRIM(DEVICE.name)	AS [Device]
			, DEVICE.assy_name		AS [AssyName]
			, DEVICE.ft_name		AS [FTname]
			, RTRIM([DEVICE_TYPE].[label_eng]) AS [DeviceType]
			, DEVICE.tp_rank		AS [TPRank]
			, SLIP.version_num		AS [Version]

			, FLOW.is_skipped		AS Is_Skipped
			, FLOW.job_id			
			, PROCESS.id			AS Process_id 

			, PROCESS.name			AS Process_Name 
			, JOBS.name				AS [Operation]
			, FLOW.step_no			AS [Step]
			, FLOW.next_step_no
			, FLOW.recipe
			, FLOW.lead_time		AS [Lead_time]
			, FLOW.lead_time_sum	AS [Lead_time_sum]
			, CASE WHEN FLOW.ng_retest_permitted IS NULL THEN 0 ELSE FLOW.ng_retest_permitted END [ng_retest_permitted]
			, CASE WHEN FLOW.process_minutes IS NULL THEN 0 ELSE FLOW.process_minutes END process_minutes
			, CASE WHEN FLOW.sum_process_minutes IS NULL THEN 0 ELSE FLOW.sum_process_minutes END sum_process_minutes
			, CASE WHEN FLOW.is_sblsyl = 1 THEN 'SBLSYL' ELSE '-' END   [Flow_sblsyl]
			, CASE WHEN FLOWSBLSYL.sbl_upper_limit IS NULL THEN 0 ELSE FLOWSBLSYL.sbl_upper_limit END sbl_upper_limit
			, CASE WHEN FLOWSBLSYL.syl_lower_limit IS NULL THEN 0 ELSE FLOWSBLSYL.syl_lower_limit END syl_lower_limit
			, SLIP.is_released		AS [IsReased]

			, CASE WHEN FLOW.[is_skipped] = 1 THEN '#c7c7c7' ELSE '#ADD8E6'  END as [Color_Label]		
			, FLOW.material_set_id	AS [Material_set]
			, FLOW.jig_set_id		AS [Jig_set]			
			, FLOW.permitted_machine_id 
			, CASE WHEN FLOW.issue_label_type IS NULL THEN 0 ELSE FLOW.issue_label_type END [issue_label_type]
			, FLOW.bincode_set_id
			, [RELEASED].label_eng  AS [released_status]

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
	INNER JOIN APCSProDB.method.item_labels AS [DEVICE_TYPE] WITH (NOLOCK)
	ON [DEVICE_TYPE].name				= 'device_versions.device_type' 
	AND  VER.device_type			=  [DEVICE_TYPE].val
	LEFT JOIN APCSProDB.method.device_flows_sblsyl		FLOWSBLSYL (NOLOCK)
	ON FLOWSBLSYL.device_flow_id	= FLOW.id
	LEFT JOIN [APCSProDB].[method].[item_labels] AS [RELEASED] WITH (NOLOCK)
	ON [RELEASED].[name]			= 'device_slips.is_released'
	AND [SLIP].[is_released]		= [RELEASED].[val]
	
	WHERE FLOW.is_sblsyl = 1
	AND ([DEVICE].[name] = @device OR ISNULL(@device,'') = '')
	AND ([PACK].[name] = @Package OR ISNULL(@Package,'') = '')
	AND ([SLIP].[version_num] = @version OR ISNULL(@version,'') = '')
	AND ([DEVICE].[assy_name] = @assyname OR ISNULL(@assyname,'') = '')
	AND ([DEVICE].[ft_name] = @ftname OR ISNULL(@ftname,'') = '')
	AND ([RELEASED].[label_eng] = @isreased OR ISNULL(@isreased,'')	= '')
	AND ([DEVICE_TYPE].[label_eng] = @devicetype OR ISNULL(@devicetype,'') = '')
	ORDER BY SLIP.device_slip_id ASC

SET NOCOUNT OFF 
END
 