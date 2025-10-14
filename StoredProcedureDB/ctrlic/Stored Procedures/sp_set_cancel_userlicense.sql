-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ctrlic].[sp_set_cancel_userlicense] 
	-- Add the parameters for the stored procedure here
	@user_id AS INT
	, @lic_id AS INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DELETE FROM [APCSProDB].[ctrlic].[user_lic] 
	WHERE user_id = @user_id and lic_id = @lic_id
END
