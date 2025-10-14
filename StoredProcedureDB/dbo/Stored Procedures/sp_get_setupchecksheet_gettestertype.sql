-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_setupchecksheet_gettestertype]
	-- Add the parameters for the stored procedure here
	@qrCode varchar(9)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT A.*, 
	     (SELECT CONCAT(SubType, REPLACE(SpecialCtrl, '-', ''))) As ConnectedType, 
		  B.Name AS BomTesterType, 
		  C.Name AS TesterType

	FROM DBx.EQP.Equipment AS A
	LEFT JOIN DBX.BOM.BomTesterType AS B ON (SELECT CONCAT(SubType, REPLACE(SpecialCtrl, '-', ''))) = B.Name
	LEFT JOIN DBX.dbo.TesterType AS C ON B.TesterTypeID = C.ID

	WHERE EquipmentTypeID = 7 AND QRName = @qrCode
END
