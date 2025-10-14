
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

CREATE PROCEDURE [mdm].[sp_get_DeviceSlipsAll]
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

	--SET NOCOUNT ON

	SET NOCOUNT ON;

	SELECT
		[SLIP].[device_slip_id] AS [SlipsID],
		RTRIM([PACK].[name]) AS [Package],
		[DEVICE].[id] AS [device_id],
		RTRIM([DEVICE].[name]) AS [Device],
		RTRIM([DEVICE].[assy_name]) AS [AssyName],
		[DEVICE].[ft_name] AS [FTname],
		RTRIM([DEVICE_TYPE].[label_eng]) AS [DeviceType],
		[DEVICE].[tp_rank] AS [TPRank],
		[SLIP].[version_num] AS [Version],
		[RELEASED].[label_eng] AS [IsReased],
		ISNULL([DEVICE].pcs_per_pack,0) AS [pcs_per_pack],
		ISNULL([DEVICE].is_incoming,0) AS [IsIncoming]

		, [SLIP].tp_code
		, [SLIP].os_program_name
		, [SLIP].sub_rank
		, [SLIP].temporary_char
		, [SLIP].comments
		, [SLIP].normal_leadtime_minutes
		, [SLIP].lead_time_sum
		, [SLIP].is_inherited
		, [SLIP].is_sblsyl_approved
		, [SLIP].valid_from
		, [SLIP].valid_until

	FROM [APCSProDB].[method].[device_slips] AS [SLIP] WITH (NOLOCK)
	INNER JOIN [APCSProDB].[method].[device_versions] AS [VER] WITH (NOLOCK)
		ON [SLIP].[device_id] = [VER].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] AS [DEVICE] WITH (NOLOCK)
		ON [VER].[device_name_id] = [DEVICE].[id]
	INNER JOIN [APCSProDB].[method].[packages] AS [PACK] WITH (NOLOCK)
		ON [DEVICE].[package_id] = [PACK].[id]
	LEFT JOIN [APCSProDB].[method].[item_labels] AS [DEVICE_TYPE] WITH (NOLOCK)
		ON [DEVICE_TYPE].[name] = 'device_versions.device_type'
		AND [VER].[device_type] = [DEVICE_TYPE].[val] 
	LEFT JOIN [APCSProDB].[method].[item_labels] AS [RELEASED] WITH (NOLOCK)
		ON [RELEASED].[name] = 'device_slips.is_released'
		AND [SLIP].[is_released] = [RELEASED].[val]
	WHERE ([DEVICE].[name] = @device OR ISNULL(@device,'') = '')
		AND ([PACK].[name] = @Package OR ISNULL(@Package,'') = '')
		AND ([SLIP].[version_num] = @version OR ISNULL(@version,'') = '')
		AND ([DEVICE].[assy_name] = @assyname OR ISNULL(@assyname,'') = '')
		AND ([DEVICE].[ft_name] = @ftname OR ISNULL(@ftname,'') = '')
		AND ([RELEASED].[label_eng] = @isreased OR ISNULL(@isreased,'')	= '')
		AND ([DEVICE_TYPE].[label_eng] = @devicetype OR ISNULL(@devicetype,'') = '')
	ORDER BY [SLIP].[device_slip_id]
END
 