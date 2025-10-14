-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_setupchecksheet_getbomoption]
	-- Add the parameters for the stored procedure here
	@BomId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	SELECT OptionType.Name
		 , OptionType.OptionName
		 , FTBomOption.Quantity
		 , FTBomOption.Setting
		 , optioncategory.OptionCategory


	FROM [DBx].[BOM].[FTBomOption]
	INNER JOIN [DBx].[EQP].[OptionType] ON FTBomOption.OptionTypeID = OptionType.ID
	FULL JOIN [DBx].[dbo].[optioncategory] ON OptionType.Name = optioncategory.SubType

	WHERE FTBomID = @BomId
	  AND Name NOT LIKE 'PA%' --Can't check now becuz of Can replaced by many conditions like 60V 3A can replaced by 120V 4A
	  --AND Name NOT LIKE 'CD%'
	
END
