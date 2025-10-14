-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_setupchecksheet_getftmachine]
	-- Add the parameters for the stored procedure here
	@EquipmentName varchar(15)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	SELECT Equipment.Name As EquipmentMCNo, Equipment.SubType, Machine.MCNo, FTPCType.PCMain, FTPCType.PCType , FTPCType.PCMain

	FROM DBx.EQP.Equipment
	INNER JOIN DBx.EQP.Machine			ON Machine.ID = Equipment.ID
	INNER JOIN DBx.EQP.FTMachine		ON FTMachine.MachineID = Machine.ID  
	INNER JOIN DBx.dbo.PMMachineType	ON PMMachineType.ID = Machine.PMMachineTypeID  
	INNER JOIN DBx.EQP.FTPCType			ON FTPCType.ID = FTMachine.PDMachineTypeID  

	WHERE Equipment.Name = @EquipmentName
END
