-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [ctrlic].[sp_set_addlicense]
	-- Add the parameters for the stored procedure here
	@license_type	AS VARCHAR(50)
	, @license_name AS VARCHAR(MAX)
	, @license_expired	AS INT
	, @lic_status AS INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	INSERT INTO [APCSProDB].[ctrlic].[license]
    (lic_type, lic_objective, lic_code, lic_name, lic_expire, lic_status, add_date, add_user)
    VALUES(@license_type, '-', NULL, @license_name, @license_expired, @lic_status,GETDATE(), 1)
END
