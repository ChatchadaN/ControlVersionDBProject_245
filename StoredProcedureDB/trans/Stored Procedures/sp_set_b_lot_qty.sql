-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_b_lot_qty]
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
		APCSProDB.trans.lots.qty_in = prt.THROW_PCS,
		APCSProDB.trans.lots.qty_pass = prt.THROW_PCS
	FROM APCSProDB.trans.lots as l with (ROWLOCK)
	inner join [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] as prt with (NOLOCK) on l.LOT_NO = prt.LOT_NO_2
	--inner join APCSProDB.method.packages on packages.id = lots.act_package_id
	WHERE l.lot_no like '%b%' and isnull(l.qty_in,0) = 0  
	--and APCSProDB.method.packages.is_enabled = 1 
	and l.wip_state in (0,10,20);



	UPDATE
	APCSDB.dbo.LOT1_TABLE
	SET
		APCSDB.dbo.LOT1_TABLE.PRD_PIECE = prt.THROW_PCS
	FROM APCSDB.dbo.LOT1_TABLE as l1 with (NOLOCK) 
	inner join [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] as prt with (NOLOCK) on l1.LOT_NO = prt.LOT_NO_2
	WHERE l1.lot_no like '%b%' and l1.PRD_PIECE = '0';
END
