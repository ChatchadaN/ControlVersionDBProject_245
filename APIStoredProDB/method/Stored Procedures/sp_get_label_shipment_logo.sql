-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [method].[sp_get_label_shipment_logo] 
@value int = 0	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    
	EXEC APIStoredProVersionDB.method.sp_get_label_shipment_logo_ver_001
	@value = @value
END
