-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_method_device_slip_allversion]
	-- Add the parameters for the stored procedure here
	@LOTS_ID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	----# old query
	--DECLARE @DEVICE_NAME_ID INT,
	--		@PACKAGE_ID INT

	--select 
	--@DEVICE_NAME_ID = [device_versions].device_name_id	
	--,@PACKAGE_ID = packages.id	
	--from [APCSProDB].[method].device_slips
	--inner join [APCSProDB].trans.lots on lots.device_slip_id = device_slips.device_slip_id
	--inner join [APCSProDB].[method].[device_versions] on device_slips.device_id = [device_versions].device_id
	--inner join [APCSProDB].[method].device_names on device_names.id = [device_versions].device_name_id
	--inner join [APCSProDB].method.packages on packages.id = device_names.package_id
	--where lots.id = @LOTS_ID
 --   -- Insert statements for procedure here
	
	--SELECT 
	--  DISTINCT [device_slips].device_slip_id,[device_names].[name] + 'V.' + CONVERT(varchar(3)
	--  ,[device_slips].[version_num]) + ' ' + [item_labels].[label_eng] as device_version 
	--FROM [APCSProDB].[method].[device_slips] 
	--inner join [APCSProDB].[trans].[lots] on [lots].[device_slip_id] = [device_slips].device_slip_id
	--inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id] 
	--inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
	--inner join [APCSProDB].[method].[item_labels] on [item_labels].[name] = 'device_versions.device_type' and [item_labels].[val] = [device_versions].[device_type]
	--where [device_names].package_id = @PACKAGE_ID and [device_slips].device_id = @DEVICE_NAME_ID
	--order by device_version 

	----# new query
	SELECT [device_slips].[device_slip_id]
		, [device_slips].[device_version] 
		--, [device_slips].[is_released]
	FROM [APCSProDB].[trans].[lots]
	CROSS APPLY (
		SELECT [device_slips].*
		FROM (
			SELECT [device_versions].[device_name_id]
				, [device_versions].[device_type]
			FROM [APCSProDB].[method].[device_slips]
			INNER JOIN [APCSProDB].[method].[device_versions] ON [device_slips].[device_id] = [device_versions].[device_id]
			WHERE [device_slips].[device_slip_id] = [lots].[device_slip_id]	
		) AS [device_table]
		CROSS APPLY (
			SELECT [device_slips].[device_slip_id]
				, [device_names].[name] + 'V.' + CONVERT(VARCHAR(3),[device_slips].[version_num]) + ' ' + [item_labels].[label_eng] AS [device_version]
				, [device_slips].[is_released]
			FROM [APCSProDB].[method].[device_slips]
			INNER JOIN [APCSProDB].[method].[device_versions] ON [device_slips].[device_id] = [device_versions].[device_id]
			INNER JOIN [APCSProDB].[method].[device_names] ON [device_versions].[device_name_id] = [device_names].[id]
			INNER JOIN [APCSProDB].[method].[item_labels] ON [item_labels].[name] = 'device_versions.device_type' 
				AND [item_labels].[val] = [device_versions].[device_type]
			WHERE [device_versions].[device_name_id] = [device_table].[device_name_id] 
				AND [device_versions].[device_type] = [device_table].[device_type]
				AND [device_slips].[is_released] = 1
		) AS [device_slips]
	) AS [device_slips]
	WHERE [lots].[id] = @LOTS_ID;
END
