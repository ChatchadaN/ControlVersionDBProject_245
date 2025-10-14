-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE sp_get_ukebarai_export_error
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT     Cause_of_NG1, Cause_of_NG2, Cause_of_NG3, Cause_of_NG4, DBxLotEndTime, DBxLotNo, DBxLotStartTime, DBxMCNo, DBxProcessID, Date, 
				Good_Qty, LotNo, NG_Qty, NG_Qty1, NG_Qty2, NG_Qty3, NG_Qty4, OPNo, Pass_Flag, Process_No, Program_No, Rtn_Process_No, Shipment_Qty, 
				Temp1, Temp2, Temp3, Temp4, Temp5, Terminal_ID, Time
	FROM         [Dbx].[dbo].[UkebaraiData]
	WHERE     (DBxLotEndTime IS NOT NULL) AND (CONVERT(int, Good_Qty) > 0)
	and NG_Qty is null
	ORDER BY DBxLotEndTime ASC
END
