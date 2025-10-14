
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_employee]
	-- Add the parameters for the stored procedure here
	@emp_code varchar(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 002 ##########
	EXEC [APIStoredProVersionDB].[man].[sp_get_employee_002]
		@emp_code = @emp_code
	-- ########## VERSION 002 ##########

END
