-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_validator_ftsetupreport]
	-- Add the parameters for the stored procedure here
	@mcNo varchar(15)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @pcType varchar(50), @pcMain varchar(50)
	DECLARE @TestBoxAType varchar(15), @TestBoxBType varchar(15)

    -- Insert statements for procedure here
	IF(@mcNo LIKE 'FT%')
	BEGIN
		SELECT @pcType = FTPCType.PCType
			 , @pcMain = FTPCType.PCMain

		FROM [DBx].[EQP].[FTMachine] 
		INNER JOIN [DBx].[EQP].[Equipment]	ON FTMachine.MachineID = Equipment.ID 
		INNER JOIN [DBx].[EQP].[FTPCType]	ON FTMachine.PCType = FTPCType.PCType

		WHERE Equipment.Name = @mcNo
	END	

	ELSE IF(@mcNo LIKE 'MAP%')
	BEGIN
		SELECT @pcType = FTPCType.PCType
			 , @pcMain = FTPCType.PCMain

		FROM [DBx].[EQP].[MAPMachine] 
		INNER JOIN [DBx].[EQP].[Equipment]	ON MAPMachine.MachineID = Equipment.ID 
		INNER JOIN [DBx].[EQP].[FTPCType]	ON MAPMachine.PCType = FTPCType.PCType

		WHERE Equipment.Name = @mcNo

	END

	SELECT mc.id		AS MachineId
		 , setup.MCNo	AS MachineName
		 , pkg.id		AS PackageId
		 , setup.PackageName
		 , setup.DeviceName
		 , setup.ProgramName
		 , setup.TesterType
		 , setup.TestFlow
		 , @pcType		AS PCType
		 , @pcMain		AS PCMain
		 , setup.TesterNoAQRcode
		 , setup.TesterNoA
		 , setup.TesterNoBQRcode
		 , setup.TesterNoB
		 , setup.TestBoxAQRcode
		 , setup.TestBoxA
		 , ISNULL((SELECT EquipmentType.Name
		    FROM DBx.EQP.Equipment
			JOIN DBx.EQP.EquipmentType ON Equipment.EquipmentTypeID = EquipmentType.ID
			WHERE Equipment.QRName = setup.TestBoxAQRcode),'') AS TestBoxAType

		 , setup.TestBoxBQRcode
		 , setup.TestBoxB
		 , ISNULL((SELECT EquipmentType.Name
		    FROM DBx.EQP.Equipment
			JOIN DBx.EQP.EquipmentType ON Equipment.EquipmentTypeID = EquipmentType.ID
			WHERE Equipment.QRName = setup.TestBoxBQRcode),'') AS TestBoxBType

		 , setup.AdaptorAQRcode
		 , setup.AdaptorA
		 , setup.AdaptorBQRcode
		 , setup.AdaptorB
		 , setup.DutcardAQRcode
		 , setup.DutcardA
		 , setup.DutcardBQRcode
		 , setup.DutcardB
		 , setup.BridgecableAQRcode
		 , setup.BridgecableA
		 , setup.BridgecableBQRcode
		 , setup.BridgecableB
		 , setup.OptionType1QRcode
		 , setup.OptionType1
		 , setup.OptionType2QRcode
		 , setup.OptionType2
		 , setup.OptionType3QRcode
		 , setup.OptionType3
		 , setup.OptionType4QRcode
		 , setup.OptionType4
		 , setup.OptionType5QRcode
		 , setup.OptionType5
		 , setup.OptionType6QRcode
		 , setup.OptionType6
		 , setup.OptionType7QRcode
		 , setup.OptionType7
		 , setup.QRCodesocketChannel1
		 , setup.QRCodesocket1
		 , setup.QRCodesocketChannel2
		 , setup.QRCodesocket2
		 , setup.QRCodesocketChannel3
		 , setup.QRCodesocket3
		 , setup.QRCodesocketChannel4
		 , setup.QRCodesocket4
		 , setup.SetupStatus

	FROM DBx.dbo.FTSetupReport				AS setup
	INNER JOIN APCSProDB.mc.machines		AS mc		ON setup.MCNo = mc.name
	INNER JOIN APCSProDB.method.packages	AS pkg		ON setup.PackageName = pkg.name
	WHERE MCNo = @mcNo
END
