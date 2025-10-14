-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_search_Mno_Standard] 
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select   mixhist.LotNo
			,denpyo.MNO2 as mno_standard
	from DBxDW.TGOG.MIX_HIST as mixhist
	inner join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo on denpyo.LOT_NO_1 = @lotno
	where mixhist.LotNo = @lotno

END
