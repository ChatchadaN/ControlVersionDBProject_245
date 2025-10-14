-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[GET_USER_INFO_BY_USER_CODE_COMPANY_CODE]
	-- Add the parameters for the stored procedure here
	@USER_NO varchar(10),
	@COMPANY_CODE varchar(5)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--SELECT USER_ID, USER_NO, USERNAME, PASSWORD FROM USER_INFO
	select US.id as USER_ID, US.emp_num as USER_NO, US.name as USERNAME, US.password as PASSWORD
	from APCSProDB.man.users as US with(nolock)
	inner join APCSProDB.man.user_organizations as UO with(nolock) on UO.user_id = US.id
	inner join APCSProDB.man.organizations as OG with(nolock) on OG.id = UO.organization_id
	inner join APCSProDB.man.headquarters as HQ with(nolock) on HQ.id = OG.headquarter_id
	inner join APCSProDB.man.factories as FC with(nolock) on FC.id = HQ.factory_id
	WHERE US.emp_num = @USER_NO AND FC.factory_code = @COMPANY_CODE 
	
	return @@ROWCOUNT
END
