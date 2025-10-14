-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [stripmap].[GET_USER_INFO_BY_USER_ID]
	-- Add the parameters for the stored procedure here
	@USER_ID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--SELECT USER_ID, USER_NO, USERNAME, PASSWORD FROM USER_INFO  
	--WHERE USER_ID = @USER_ID
	
	select US.id as USER_ID, US.emp_num as USER_NO, US.name as USERNAME, US.password as PASSWORD
	from APCSProDB.man.users as US with(nolock)
	where US.id = @USER_ID

	return @@ROWCOUNT
END

