-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_qc_stop_lot_ver_001]
	-- Add the parameters for the stored procedure here
	@LotNo Varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	IF @LotNo IS NOT NULL AND @LotNo != ''
		BEGIN
			IF(EXISTS (SELECT 1 FROM [StoredProcedureDB].[dbo].[IS_ALL_STOP_LOT] WHERE LotNo = @LotNo))
				BEGIN
					IF(EXISTS (SELECT 1 FROM [StoredProcedureDB].[dbo].[IS_ALL_STOP_LOT] WHERE LotNo = @LotNo AND [FIN_FLAG] = ''))
						BEGIN
							SELECT 'FALSE' AS Status ,'QC STOP LOT !!' AS Error_Message_ENG,N'Lot ' + @LotNo + N' โดน Stop อยู่ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
						END
					ELSE
						BEGIN
							SELECT 'TRUE' AS Status ,'QC NO STOP LOT !!' AS Error_Message_ENG,N'Lot ' + @LotNo + N' ไม่ได้ Stop อยู่ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
						END
				END
			ELSE
				BEGIN
					SELECT 'TRUE' AS Status ,'QC NO STOP LOT !!' AS Error_Message_ENG,N'Lot ' + @LotNo + N' ไม่ได้ Stop อยู่ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				END
		END
	ELSE
		BEGIN
			SELECT 'FALSE' AS Status ,'LOT IS NULL !!' AS Error_Message_ENG,N'ไม่ได้ส่ง Lot มา !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		END
END