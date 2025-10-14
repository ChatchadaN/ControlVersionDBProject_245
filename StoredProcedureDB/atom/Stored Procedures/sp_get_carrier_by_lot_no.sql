-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_carrier_by_lot_no]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	SELECT [lots].[lot_no] AS [LotNo]
		, IIF([lots].[carrier_no] IS NULL OR [lots].[carrier_no] = '','-',[lots].[carrier_no]) AS [LoadCarrier]
		, IIF([lots].[next_carrier_no] IS NULL OR [lots].[next_carrier_no] = '','-',[lots].[next_carrier_no]) AS [UnloadCarrier]
		, IIF([lots].[e_slip_id] IS NULL OR [lots].[e_slip_id] = '','-',[lots].[e_slip_id]) AS [EslipCardID]
	FROM [APCSProDB].[trans].[lots]
	WHERE [lots].[lot_no] = @lot_no;
END
