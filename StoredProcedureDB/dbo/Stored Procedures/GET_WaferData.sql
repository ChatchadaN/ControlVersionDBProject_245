-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GET_WaferData]
	-- Add the parameters for the stored procedure here
	@WaferLot as varchar(24)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @LocalWaferLot varchar(24)
	SET @LocalWaferLot = @WaferLot

    -- Insert statements for procedure here
	SELECT LOT_NO_1, THROW_DATE_1, FORM_NAME_1, ASSY_MODEL_NAME_1, ROHM_CHIP_MODEL_NAME, THROW_PCS, BOX_NO_1, BOX_NO_2, BOX_NO_3, BOX_NO_4
		, PERETTO_NO_1, PERETTO_NO_2, PERETTO_NO_3, PERETTO_NO_4, PERETTO_NO_5, PERETTO_NO_6, PERETTO_NO_7, PERETTO_NO_8
		, MANU_COND_QUALITY_MATERIAL, HASU_LOT 
	FROM APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT 
	WHERE (PERETTO_NO_1 LIKE @LocalWaferLot + '%') OR (PERETTO_NO_2 LIKE @LocalWaferLot + '%') OR (PERETTO_NO_3 LIKE @LocalWaferLot + '%') OR (PERETTO_NO_4 LIKE @LocalWaferLot + '%') 
		OR (PERETTO_NO_5 LIKE @LocalWaferLot + '%') OR (PERETTO_NO_6 LIKE @LocalWaferLot + '%') OR (PERETTO_NO_7 LIKE @LocalWaferLot + '%') OR (PERETTO_NO_8 LIKE @LocalWaferLot + '%') 
	ORDER BY LOT_NO_1
END
