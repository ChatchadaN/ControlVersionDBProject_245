-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [ctrlic].[sp_get_getmylicense]
	-- Add the parameters for the stored procedure here
	@id	AS INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		SELECT [users].[id] AS [users_id]
		 , [users].[emp_num] 
		 , [users].[name] 
		 , [users].[full_name] 
		 , [license].[lic_id]
		 , [license].[lic_name] AS [license_name]		 
		 , [user_lic].[start_date]
		 , [user_lic].[stop_date]
		 , [user_lic].[is_active]
		FROM [APCSProDB].[man].[users]
		LEFT JOIN [APCSProDB].[ctrlic].[user_lic] ON [users].[id] = [user_lic].[user_id]
		LEFT JOIN [APCSProDB].[ctrlic].[license] ON [user_lic].[lic_id] = [license].[lic_id]
		WHERE [users].id = @id

END
