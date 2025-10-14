-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_man_user_application_list_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [operations].[id]
	, [operations].[name]
	, [operations].[parameter_1] AS app_route
	, '' AS app_image
	FROM [APCSProDB].[man].[operations]
	WHERE [operations].[app_name] = 'ROHM_APP'
	AND [operations].[function_name] = 'Name'
END
