-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [ctrlic].[sp_set_update_licensestatus]
	-- Add the parameters for the stored procedure here
	@state AS INT --0 = disable ,1 = enable
	, @license_id AS INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN
	 IF(@state = 1)
	 BEGIN
		UPDATE [APCSProDB].[ctrlic].[license]
		SET lic_status = '0', edit_date = GETDATE(), edit_user = 1 
		WHERE[license].[lic_id] =  @license_id
	 END
	 ELSE IF(@state = 0)
	 BEGIN
		UPDATE [APCSProDB].[ctrlic].[license]
		SET lic_status = '1', edit_date = GETDATE(), edit_user = 1 
		WHERE[license].[lic_id] =  @license_id
	 END
	END
		
END
