-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_user_app_or_db]
	-- Add the parameters for the stored procedure here
	@emp_num varchar(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [id],[name],[emp_num] 
	FROM (
		SELECT [id],[name],[emp_num] 
		FROM [APCSProDB].[man].[users]
		WHERE [emp_num] in ('009255','009131','010452','010934','009670','007952')
	) as [users]
	WHERE [users].[emp_num] = @emp_num
END
