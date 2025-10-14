
-- =============================================
-- Author:		<Database Admin,,NutchanaT k.>
-- Create date: <14/07/2025,,>
-- Description:	<List Employee,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_employee_list]
	-- Add the parameters for the stored procedure here
	@emp_code varchar(6)= Null,
	@hq_id int = Null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[man].[sp_get_employee_list_001]
		@emp_code = @emp_code,
		@hq_id = @hq_id
	-- ########## VERSION 001 ##########

END
