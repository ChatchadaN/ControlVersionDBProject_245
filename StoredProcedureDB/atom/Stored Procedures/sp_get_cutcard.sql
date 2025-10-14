-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_cutcard]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	

    -- Insert statements for procedure here
	SELECT TOP 1 [CHIGIRI_QR1] AS [qrcode]
		,[TP_RANK_1] as [rank]
		,[MNO1] as [markno]
		,[LOT_NO_2] as [lotno]
		,[FT_MODEL_NAME_1] as [ftname]
	FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
	WHERE ([LOT_NO_1]= @lot_no
		OR [LOT_NO_2] = @lot_no
		OR [LOT_NO_3] = @lot_no
		OR [LOT_NO_4] = @lot_no
		OR [LOT_NO_5] = @lot_no
		OR [LOT_NO_6] = @lot_no
		OR [LOT_NO_7] = @lot_no
		OR [LOT_NO_8] = @lot_no
		OR [LOT_NO_9] = @lot_no
		OR [LOT_NO_10] = @lot_no
		OR [LOT_NO_11] = @lot_no
		OR [LOT_NO_12] = @lot_no)
	
END
