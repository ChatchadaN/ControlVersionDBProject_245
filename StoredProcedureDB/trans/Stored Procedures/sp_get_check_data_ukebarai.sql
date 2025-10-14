-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_check_data_ukebarai]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT 'DBxLotNo : ' + CAST(DBxLotNo as varchar)  as DBxLotNo
		, 'DBxMCNo : ' + CAST(IIF(DBxMCNo IS NULL,'NULL',DBxMCNo) as varchar) as DBxMCNo
		, 'Good_Qty : ' + CAST(IIF(Good_Qty IS NULL,'NULL',Good_Qty) as varchar) as Good_Qty
		, 'NG_Qty : ' + CAST(IIF(NG_Qty IS NULL,'NULL',NG_Qty) as varchar) as NG_Qty
		, 'DBxProcessID : ' + CAST(IIF(DBxProcessID IS NULL,'NULL',DBxProcessID) as varchar) as DBxProcessID
		, 'DBxLotStartTime : ' + IIF(CONVERT(varchar,DBxLotStartTime,120) IS NULL,'NULL',CONVERT(varchar,DBxLotStartTime,120)) as DBxLotStartTime
		, 'DBxLotEndTime : ' + IIF(CONVERT(varchar,DBxLotEndTime,120) IS NULL,'NULL',CONVERT(varchar,DBxLotEndTime,120)) as DBxLotEndTime 
	FROM dbx.dbo.UkebaraiData
	WHERE (DBxLotEndTime IS NOT NULL) AND (CONVERT(int, Good_Qty) < 0)
		--AND (CONVERT(int, NG_Qty) < 0 or NG_Qty IS NULL)
		AND (NG_Qty like '%-%' or NG_Qty IS NULL)
	ORDER BY DBxLotEndTime
END