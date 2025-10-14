-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ctrlic].[sp_set_cancel_mclicense] 
	-- Add the parameters for the stored procedure here
	@model_ref_id AS INT
	, @lic_id AS INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DELETE FROM [APCSProDB].[ctrlic].[model_lic] 
	WHERE model_ref_id = @model_ref_id AND lic_id = @lic_id
END
