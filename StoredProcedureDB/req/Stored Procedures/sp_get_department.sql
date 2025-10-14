-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [req].[sp_get_department]
	-- Add the parameters for the stored procedure here
	@emp_num NVARCHAR(7)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [u].[emp_num] AS [username]
		, [u].[password]
		, [u_master].[Staffname2] AS [name]
		, [u_master].[Name_Thai] AS [full_name]
		, [u_master].[Department]
	FROM APCSProDB.man.users AS [u]
	INNER JOIN [TECDB].[TEC_Infomation].[dbo].[vew_UserLogin] AS [u_master] 
		ON [u].[emp_num] COLLATE SQL_Latin1_General_CP1_CI_AS = [u_master].[staffCode] COLLATE SQL_Latin1_General_CP1_CI_AS
	WHERE [u].[emp_num] = @emp_num;
END
