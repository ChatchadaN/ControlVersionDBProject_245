-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_setupchecksheet_getpcmain]
	-- Add the parameters for the stored procedure here
	@FullMCNo varchar(30)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	IF(@FullMCNo LIKE 'FT%')
	BEGIN
		SELECT FTPCType.ID
			 , FTPCType.PCType
			 , FTPCType.PCMain

		FROM [DBx].[EQP].[FTMachine] 
		INNER JOIN [DBx].[EQP].[Equipment]	ON FTMachine.MachineID = Equipment.ID 
		INNER JOIN [DBx].[EQP].[FTPCType]	ON FTMachine.PCType = FTPCType.PCType

		WHERE Equipment.Name = @FullMCNo
	END	

	ELSE IF(@FullMCNo LIKE 'MAP%')
	BEGIN
		SELECT FTPCType.ID
			 , FTPCType.PCType
			 , FTPCType.PCMain

		FROM [DBx].[EQP].[MAPMachine] 
		INNER JOIN [DBx].[EQP].[Equipment]	ON MAPMachine.MachineID = Equipment.ID 
		INNER JOIN [DBx].[EQP].[FTPCType]	ON MAPMachine.PCType = FTPCType.PCType

		WHERE Equipment.Name = @FullMCNo
	END

	ELSE IF(@FullMCNo LIKE 'FL%')
	BEGIN
		SELECT ID
		     , SpecialCtrl AS PCType
			 , SubType AS PCMain

		FROM [DBx].[EQP].[Equipment]

		WHERE Equipment.Name = @FullMCNo
	END	

	ELSE IF(@FullMCNo LIKE 'TP%')
	BEGIN
		SELECT ID
		     , SubType AS PCType
			 --, SpecialCtrl AS PCMain
			 , TPMachineType AS PCMain

		FROM [DBx].[EQP].[Equipment]
		INNER JOIN [DBx].[EQP].[TPMachine]	ON TPMachine.MachineID = Equipment.ID

		WHERE Equipment.Name = @FullMCNo
	END	
END
