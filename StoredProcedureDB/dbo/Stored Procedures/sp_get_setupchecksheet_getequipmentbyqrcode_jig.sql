-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_setupchecksheet_getequipmentbyqrcode_jig]
	-- Add the parameters for the stored procedure here
	@QRName varchar(10)							
AS																					
BEGIN																				
	-- SET NOCOUNT ON added to prevent extra result sets from						
	-- interfering with SELECT statements.											
	SET NOCOUNT ON;																	
																					
    -- Insert statements for procedure here		

	SELECT [jigs].[id] 
		, [machine_jigs].[machine_id]
		, [categories].[name] AS [Type]
		, [productions].[name] AS [SubType]
		, [jigs].[barcode] AS [QRCode]	
		, [jigs].[qrcodebyuser] AS [Name]
	FROM [APCSProDB].[trans].[jigs]
	INNER JOIN [APCSProDB].[jig].[productions] ON [jigs].[jig_production_id] = [productions].[id]
	INNER JOIN [APCSProDB].[jig].[categories] ON [productions].[category_id] = [categories].[id]
	LEFT JOIN [APCSProDB].[trans].[machine_jigs] ON [jigs].[id] = [machine_jigs].[jig_id]
	WHERE [barcode] = @QRName

END
