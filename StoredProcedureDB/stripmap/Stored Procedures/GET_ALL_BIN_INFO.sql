-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [stripmap].[GET_ALL_BIN_INFO]
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
	
	select 
		BD.id as BIN_ID,
		BD.custom_display_color as DEFAULT_COLOR,
		BD.bin_description as BIN_DEF,
		BD.die_quality as STATUS,
		BD.custom_display_color as CUSTOM_COLOR
	from APCSProDB.mc.bin_definitions as BD with(nolock)

	return @@ROWCOUNT
END

