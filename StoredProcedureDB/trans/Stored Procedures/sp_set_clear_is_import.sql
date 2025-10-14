-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_clear_is_import]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE [APCSProDB].[trans].[lots]
		SET [is_imported] = null
	WHERE [lots].[id] in (select [lots].[id]
	from [APCSProDB].[trans].[lots]
	inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
	inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
	inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
	inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]
	where [packages].[is_enabled] = 1
	and [lots].[is_imported] = 1)
END
