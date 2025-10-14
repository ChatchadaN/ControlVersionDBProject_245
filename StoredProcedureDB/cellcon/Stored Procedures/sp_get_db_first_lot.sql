-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE cellcon.sp_get_db_first_lot
	-- Add the parameters for the stored procedure here
	@LotNo varchar(10),
	@WaferLotNo varchar(15)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
-- Parameter 
--     1.WaferLotNo
--     2.LotNo

declare @orderNo varchar(15)
declare @waferTotal int
declare @firstLotNo varchar(10)
declare @carrier varchar(15)


--หา OrderNo ใน denpyo
set @orderNo = (select ORDER_NO from APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT where LOT_NO_1 = @LotNo )

--หาจำนวนแผ่นของ WaferLot ทั้งหมด
set @waferTotal =  (select SUM(cast(WF_NUM_1 as int)) from APCSDB.dbo.LCQW_STOCK_OUT_DETAILS_PRINT where ORDER_NO_1 = @orderNo and FAB_WF_LOT_NO_4 = @WaferLotNo)

--ค้นหา LotNoแรกของ Magazine
select TOP(1) @firstLotNo = LOT_NO from  APCSDB.dbo.LCQW_STOCK_OUT_DETAILS_PRINT where ORDER_NO_1 = @orderNo and FAB_WF_LOT_NO_4 = @WaferLotNo order by LOT_NO asc

--ค้นหา Carrier ของลอตแรก
select @carrier = carrier_no from  APCSProDB.trans.lots where lot_no = @firstLotNo 

select @firstLotNo as FirstLotNo,@carrier as FirstLotCarrierNo,@waferTotal as TotalWafer ,@orderNo as OrderNo 
END
