-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_user_identification]
	-- Add the parameters for the stored procedure here
	@emp_num varchar(10)
	,@permission_name varchar(20) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[man].[sp_get_user_identification_001]
		@emp_num = @emp_num,
		@permission_name = @permission_name
	-- ########## VERSION 001 ##########
END
