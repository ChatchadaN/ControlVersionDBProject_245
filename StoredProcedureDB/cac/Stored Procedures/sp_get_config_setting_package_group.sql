-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_config_setting_package_group]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT [config_package_groups].[id]
		, [config_package_groups].[name]
		, [package_groups].[name] AS [name_pro]
		, [config_package_groups].[floor]
		, [config_package_groups].[is_enable]
	 FROM [APCSProDWH].[cac].[config_package_groups]
	 INNER JOIN [APCSProDB].[method].[package_groups] ON [config_package_groups].[package_groups_id] = [package_groups].[id];
END
