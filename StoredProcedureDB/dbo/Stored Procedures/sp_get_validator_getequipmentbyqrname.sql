-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_validator_getequipmentbyqrname]
	-- Add the parameters for the stored procedure here
	@qrName varchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Equipment.ID
		 , EquipmentTypeID
		 , EquipmentType.Name AS EquipmentTypeName
		 , FixAsset
		 , SubType AS EquipmentName
		 , Equipment.Name
		 , ControlNo
		 , SpecialCtrl
		 , StatusID
		 , Location
		 , Register
		 , RegisteredDate
		 , ProcessID
		 , QRName

	FROM DBx.EQP.Equipment
	JOIN DBx.EQP.EquipmentType ON Equipment.EquipmentTypeID = EquipmentType.ID

	WHERE QRName IN (SELECT value
					 FROM string_split(@qrName, ','))
END
