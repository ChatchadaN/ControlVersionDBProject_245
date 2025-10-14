-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_DB_Wafer_Carrier]
	-- Add the parameters for the stored procedure here
	 @inputWaferLot varchar(15),
	 @inputLotNo varchar(10),
	 @inputWaferCount int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @orderNo varchar(15)
	declare @waferTotal int
	declare @firstLotNo varchar(10)
	declare @carrier varchar(15)

	--set @inputWaferLot = '1HK8Y-2363A'
	--set @inputWaferCount = 5
	--set @inputLotNo = '2218A2177V'

	--หา OrderNo ใน denpyo
	set @orderNo = (select ORDER_NO from APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT where LOT_NO_1 = @inputLotNo )
	--select @orderNo as orderNo

	--หาจำนวนแผ่นของ WaferLot ทั้งหมด
	--( select COUNT(*) from (  select trim(SUBSTRING(QR_CODE_2,70,12)) as waferNo  , LOT_NO_1 from  APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT  where ORDER_NO = @orderNo ) as  tableA where  tableA.waferNo = @inputWaferLot )
	set  @waferTotal = (select SUM(cast(WF_NUM_1 as int)) from  APCSDB.dbo.LCQW_STOCK_OUT_DETAILS_PRINT where ORDER_NO_1 = @orderNo and FAB_WF_LOT_NO_4 = @inputWaferLot)

	IF(@waferTotal is null or @waferTotal = 0 ) 
	BEGIN
		SELECT 'FALSE' as Is_Pass , N'LotNo:' + @inputLotNo + N' และ WaferLotNo:' + @inputWaferLot + N' ไม่ถูกต้องกรุณาตรวจสอบด้วยครับ'   as Error_Message_THA
		RETURN
	END

	IF (@inputWaferCount != @waferTotal)
	BEGIN
		SELECT 'FALSE' as Is_Pass , N'จำนวนแผ่น Wafer ใน Magazine ไม่ตรงกับจำนวนที่ Input เข้า Cellcon กรุณาตรวจสอบ'  as Error_Message_THA,@waferTotal as wafertotal
		RETURN
	END

	--ค้นหา LotNoแรกของ Magazine
	set @firstLotNo = (select TOP(1) tableA.Lot_NO_1 from (select trim(SUBSTRING(QR_CODE_2,70,12)) as waferNo  , LOT_NO_1 from  APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT  where ORDER_NO = @orderNo ) as tableA where tableA.waferNo =  @inputWaferLot order by tableA.LOT_NO_1 asc)

	if(@inputLotNo = @firstLotNo) --ค้นหาลอตแรก
	BEGIN
		select @carrier = carrier_no from  APCSProDB.trans.lots where lot_no = @firstLotNo 
		if(@carrier is null or @carrier = '')
			BEGIN
				SELECT 'FALSE' as Is_Pass , N'LotNo ' + @inputLotNo +N'ไม่ได้ input Carrier จาก DC กรุณาติดต่อ System....'   as Error_Message_THA
				RETURN
			END	
		ELSE
			BEGIN
				SELECT 'TRUE' as Is_Pass ,'Scan'  as Error_Message_THA,@carrier as carrier_no
				RETURN
			END
		END
	ELSE
	BEGIN
		select @carrier = carrier_no from  APCSProDB.trans.lots where lot_no = @inputLotNo 
		if(@carrier is null or @carrier = '')
			BEGIN
				SELECT 'FALSE' as Is_Pass ,N'LotNo ' + @inputLotNo +N'ไม่ได้ input Carrier จาก DC กรุณาติดต่อ System'  as Error_Message_THA
				RETURN
			END	
		ELSE
			BEGIN
				SELECT 'TRUE' as Is_Pass , 'No Scan'  as Error_Message_THA ,@carrier as carrier_no
				RETURN
			END
	END
END
