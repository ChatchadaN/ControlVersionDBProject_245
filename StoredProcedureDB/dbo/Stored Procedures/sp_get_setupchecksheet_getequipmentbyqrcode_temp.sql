-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_setupchecksheet_getequipmentbyqrcode_temp]
	-- Add the parameters for the stored procedure here
	@QRName varchar(9), @strINCondition varchar(15)									
AS																					
BEGIN																				
	-- SET NOCOUNT ON added to prevent extra result sets from						
	-- interfering with SELECT statements.											
	SET NOCOUNT ON;																	
																					
    -- Insert statements for procedure here		

	SELECT A.ID									--BOX As Integer = 1
		 , B.id AS machineId					--BOARD As Integer = 2
		 , EquipmentTypeID						--CARD_SET As Integer = 3
		 , FixAsset								--PROBE As Integer = 4
		 , SubType								--ADAPTOR As Integer = 5
		 , A.Name								--BRIDGE_CABLE As Integer = 6
		 , ControlNo							--TESTER As Integer = 7
		 , SpecialCtrl							--MACHINE As Integer = 8
		 , StatusID								--OPTION As Integer = 9
		 , Location								--MEASUREMENT As Integer = 10
		 , Register								--TESTCARD As Integer = 11
		 , RegisteredDate						--KANAGATA As Integer = 12
		 , ProcessID							--DUTCARD As Integer = 13
		 , QRName								--OTHER As Integer = 14
		 , (SELECT CONCAT(SubType, REPLACE(SpecialCtrl, '-', ''))) As ConnectedType
		 --, C.Name AS BomTesterType
		 , D.Name AS TesterType
												
	FROM [DBx].[EQP].[Equipment] AS A
	LEFT JOIN [APCSProDB].[mc].[machines] AS B ON A.Name = B.name
	LEFT JOIN DBX.BOM.BomTesterType AS C ON (SELECT CONCAT(SubType, REPLACE(SpecialCtrl, '-', ''))) = C.Name
	LEFT JOIN DBX.dbo.TesterType AS D ON C.TesterTypeID = D.ID

	WHERE QRName = @QRName 
	  AND EquipmentTypeID IN (SELECT value					
							  FROM STRING_SPLIT(@strINCondition, ','))
END
