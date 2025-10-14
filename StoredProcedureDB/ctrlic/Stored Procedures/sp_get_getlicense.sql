-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [ctrlic].[sp_get_getlicense]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		SELECT [license].[lic_id] AS [license_id]
		 , [ref_value].[ref_desc] AS [license_type]
		 , [license].[lic_name] AS [license_name]
		 , [license].[lic_expire] AS [license_expire]
		 , [license].[lic_status] AS [lic_status]
		FROM [APCSProDB].[ctrlic].[license]
		LEFT JOIN [APCSProDB].[ctrlic].[ref_value] ON [license].[lic_type] = [ref_value].[ref_id]
		order by [license].[lic_id] 
END
