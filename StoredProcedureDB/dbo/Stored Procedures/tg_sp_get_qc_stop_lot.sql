-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_qc_stop_lot]
	-- Add the parameters for the stored procedure here
	@LotNo Varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- # check G lot Shipment 
	---- # 2024-03-14 8.26
	--IF EXISTS (
	--	SELECT [lots].[lot_no]
	--		, [lots].[wip_state]
	--		, [packages].[name]
	--		, [lot2].[lot_no]
	--		, [lot2].[wip_state]
	--	FROM [APCSProDB].[trans].[lots]
	--	INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
	--	INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
	--	INNER JOIN [APCSProDB].[trans].[lots] [lot2] ON CONCAT( SUBSTRING( [lots].[lot_no], 1, 4 ), 'G', SUBSTRING( [lots].[lot_no], 6, 5 ) ) = [lot2].[lot_no]
	--	WHERE [lots].[wip_state] IN (0,10,20)
	--		AND [lot2].[wip_state] IN (0,10,20)
	--		AND [packages].[id] = 544 --# 544:SSOP-C38W
	--		AND [lots].[lot_no] = @LotNo
	--) AND (@LotNo IS NOT NULL AND @LotNo != '')
	--BEGIN
	--	SELECT 'FALSE' AS [Status]
	--		, 'Lot ' + @LotNo + ' wait for Lot ' + CONCAT( SUBSTRING(@LotNo, 1, 4), 'G', SUBSTRING(@LotNo, 6, 5) ) + N' Shipment first !!' AS [Error_Message_ENG]
	--		, N'Lot ' + @LotNo + N' นี้ต้องรอ Lot ' + CONCAT( SUBSTRING(@LotNo, 1, 4), 'G', SUBSTRING(@LotNo, 6, 5) ) + N' Shipment ก่อน !!' AS [Error_Message_THA] 
	--		, N' กรุณาติดต่อ System' AS [Handling];
	--	RETURN;
	--END

    -- Insert statements for procedure here
	IF (@LotNo IS NOT NULL AND @LotNo != '')
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