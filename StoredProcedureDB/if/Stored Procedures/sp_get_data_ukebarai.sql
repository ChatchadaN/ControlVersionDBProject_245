-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_get_data_ukebarai]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	SELECT [ukebarais].[id]
		, CAST(' ' AS CHAR(1)) --[Temp1] 
			+ CAST([ukebarais].[lot_no] AS CHAR(10)) --[LotNo] -- #data 
			+ CAST(FORMAT([ukebarais].[process_no],'00000') AS CHAR(5)) --[Process_No] -- #data 
			+ CAST(3 AS CHAR(1)) --[Pass_Flag] 
			+ CAST([ukebarais].[date] AS CHAR(6)) --[Date] -- #data
			+ CAST([ukebarais].[time] AS CHAR(4)) --[Time] -- #data
			+ CAST('00000' AS CHAR(5)) --[Rtn_Process_No] 
			+ CAST(FORMAT([ukebarais].[good_qty],'00000') AS CHAR(5)) --[Good_Qty] -- #data 
			+ CAST(FORMAT([ukebarais].[ng_qty],'00000') AS CHAR(5)) --[NG_Qty] -- #data 
			+ CAST('   ' AS CHAR(3)) --[Cause_of_NG1] 
			+ CAST('00000' AS CHAR(5)) --[NG_Qty1] 
			+ CAST('   ' AS CHAR(3)) --[Cause_of_NG2] 
			+ CAST('00000' AS CHAR(5)) --[NG_Qty2] 
			+ CAST('   ' AS CHAR(3)) --[Cause_of_NG3] 
			+ CAST('00000' AS CHAR(5)) --[NG_Qty3] 
			+ CAST('   ' AS CHAR(3)) --[Cause_of_NG4] 
			+ CAST('00000' AS CHAR(5)) --[NG_Qty4] 
			+ CAST(99999 AS CHAR(5)) --[OPNo] 
			+ CAST('         ' AS CHAR(9)) --[Temp2] 
			+ CAST('PWCU0030------' AS CHAR(14)) --[Program_No] 
			+ CAST('          ' AS CHAR(10)) --[Temp3] 
			+ CAST(0 AS CHAR(5)) --[Temp4] 
			+ CAST(FORMAT([ukebarais].[shipment_qty],'00000') AS CHAR(5)) --[Shipment_Qty] -- #data
			+ CAST('    ' AS CHAR(4)) --[Temp5] 
			+ CAST(99 AS CHAR(2)) --[Terminal_ID]
		AS [text_data]
	FROM [APCSProDWH].[dbo].[ukebarais]
	ORDER BY [ukebarais].[date] ASC, [ukebarais].[time] ASC;
END
