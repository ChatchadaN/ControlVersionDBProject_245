-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [stripmap].[GET_FACTORY_INFO]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--SELECT A.BIN_ID, A.DEFAULT_COLOR, A.STATUS, A.BIN_DEF, B.CUSTOM_COLOR
    --FROM BIN_CODE_INFO AS A  with (NOLOCK) LEFT JOIN BIN_USER_COLOR_INFO AS B  with (NOLOCK) ON A.BIN_ID = B.BIN_ID
    --AND B.USER_ID = @USER_ID
	
	select FA.id as COMPANY_CODE, FA.name as COMPANY_NAME from APCSProDB.man.factories as FA with(nolock) 

	return @@ROWCOUNT
END

