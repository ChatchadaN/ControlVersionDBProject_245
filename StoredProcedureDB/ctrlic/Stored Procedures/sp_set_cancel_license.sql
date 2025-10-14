-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ctrlic].[sp_set_cancel_license] 
	-- Add the parameters for the stored procedure here
	@license_id AS INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   DELETE FROM [APCSProDB].[ctrlic].[license] 
   WHERE [license].[lic_id] = @license_id
END
