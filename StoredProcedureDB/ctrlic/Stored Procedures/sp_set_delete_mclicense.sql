-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [ctrlic].[sp_set_delete_mclicense]
	-- Add the parameters for the stored procedure here
	@lic_id AS INT	
	, @model_ref_id AS INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	INSERT INTO [APCSProDB].[ctrlic].[model_lic]
    (model_ref_id, lic_id)
    VALUES(@model_ref_id ,@lic_id)
END
