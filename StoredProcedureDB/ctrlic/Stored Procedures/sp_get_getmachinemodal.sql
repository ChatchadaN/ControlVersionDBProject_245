-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [ctrlic].[sp_get_getmachinemodal]
	-- Add the parameters for the stored procedure here
	@lic_id	AS INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		SELECT [model_lic].[model_ref_id]
		 , [model_lic].[lic_id]
		 , [models].[name]
		FROM [APCSProDB].[ctrlic].[model_lic] 
		LEFT JOIN [APCSProDB].[mc].[models] ON [model_lic].[model_ref_id] = [models].[id]
		WHERE [model_lic].[lic_id] = @lic_id

END
