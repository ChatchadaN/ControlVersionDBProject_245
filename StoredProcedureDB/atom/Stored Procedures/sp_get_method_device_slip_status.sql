-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_method_device_slip_status]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [packages].[name] as Package
		,[device_names].[name] as DeviceName
		,[device_names].[assy_name] as AssyName
		,[device_names].[ft_name] as FTName
		,[device_slips].[version_num] as [Version]
		,[device_versions].[version_num] as MaxVersion
		,[item_labels].[label_eng] as [Status]
	FROM [APCSProDB].[method].[device_slips]
	inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
	inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
	inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]
	left join [APCSProDB].[method].[item_labels] on [item_labels].[name] = 'device_slips.is_released' and [item_labels].[val] = [device_slips].[is_released]
	where [packages].[is_enabled] = 1
	order by Package, DeviceName, AssyName, FTName, [Version]
END
