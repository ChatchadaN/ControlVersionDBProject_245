-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_f_lot_qty_bak]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE
		APCSProDB.trans.lots
	SET
		APCSProDB.trans.lots.qty_in = [LCQW_UNION_WORK_DENPYO_PRINT].THROW_PCS,
		APCSProDB.trans.lots.qty_pass = [LCQW_UNION_WORK_DENPYO_PRINT].THROW_PCS
	FROM APCSProDB.trans.lots
	inner join [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] on lots.LOT_NO = [LCQW_UNION_WORK_DENPYO_PRINT].LOT_NO_2
	inner join APCSProDB.method.packages on packages.id = lots.act_package_id
	WHERE APCSProDB.trans.lots.lot_no like '%f%' and APCSProDB.trans.lots.qty_in = '0' 
	--and APCSProDB.method.packages.is_enabled = 1 
	and wip_state in (0,10,20);

	UPDATE
	APCSDB.dbo.LOT1_TABLE
	SET
		APCSDB.dbo.LOT1_TABLE.PRD_PIECE = [LCQW_UNION_WORK_DENPYO_PRINT].THROW_PCS
	FROM APCSDB.dbo.LOT1_TABLE
	inner join [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] on LOT1_TABLE.LOT_NO = [LCQW_UNION_WORK_DENPYO_PRINT].LOT_NO_2
	WHERE APCSDB.dbo.LOT1_TABLE.lot_no like '%f%' and APCSDB.dbo.LOT1_TABLE.PRD_PIECE = '0';
END
