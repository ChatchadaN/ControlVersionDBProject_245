-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_method_device_slip_version]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [device_slips].*
	, [device_names].[assy_name] + ' ' + [device_names].[tp_rank] + ' V.' + CONVERT(varchar(3)
	, [device_slips].[version_num]) + ' ' + [item_labels].[label_eng] as device_version 
	FROM [APCSProDB].[method].[device_slips] 
	inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id] 
	inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
	inner join [APCSProDB].[method].[item_labels] on [item_labels].[name] = 'device_versions.device_type' and [item_labels].[val] = [device_versions].[device_type]
	order by device_version 
END
