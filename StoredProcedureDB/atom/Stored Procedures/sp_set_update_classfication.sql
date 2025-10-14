-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_update_classfication]
	-- Add the parameters for the stored procedure here
	@id INT


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		DELETE [APCSProDB].[inv].[Inventory_classfications] 
        WHERE [id] = @id

		DELETE [APCSProDB].[inv].[class_locations]
		WHERE class_id =  @id
	END
END
