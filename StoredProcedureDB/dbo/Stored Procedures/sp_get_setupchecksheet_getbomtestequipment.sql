-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_setupchecksheet_getbomtestequipment]
	-- Add the parameters for the stored procedure here
	@FTBomID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	SELECT TestEquipment.Name
		 --, EquipmentType.ID AS TypeId
		 , EquipmentType.Name As TypeName
		 , TestEquipment.IsAdaptor
		 , TestEquipment.IsLoadboard
	
	FROM DBx.BOM.FTBomTestEquipment
	INNER JOIN DBx.BOM.TestEquipment ON FTBomTestEquipment.TestEquipmentID = TestEquipment.ID
	INNER JOIN DBx.EQP.EquipmentType ON TestEquipment.EquipmentTypeID = EquipmentType.ID
	
	WHERE FTBomTestEquipment.FTBomID = @FTBomID AND TestEquipment.Name != 'NO USED'
END
