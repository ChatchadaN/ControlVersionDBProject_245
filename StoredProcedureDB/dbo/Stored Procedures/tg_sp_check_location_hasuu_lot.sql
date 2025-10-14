-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,2021/11/03,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_check_location_hasuu_lot]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
	,@check_state int = 0 --1 คือ check location , 2 คือ get ข้อมูลมาโชว์
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @location_id char(10);
	
    -- Insert statements for procedure here
	select @location_id = CAST(location_id as char(10)) from APCSProDB.trans.surpluses where serial_no = @lotno

	IF @check_state = 1 
	BEGIN
		IF @location_id = 0 or @location_id is null
		BEGIN
			SELECT 'TRUE' AS Status --not location
			RETURN
		END
		ELSE 
		BEGIN
			SELECT 'FALSE' AS Status --is location
			
		RETURN
		END
	END
	ELSE IF @check_state = 2 --if location = FALSE ให้โชว์ข้อมูลของ Loacation ที่มีอยู่ปัจจุบัน (มี location อยู่แล้ว)
	BEGIN
		select serial_no
		,pcs
		,ISNULL(loca.name,'') as RackName
		,ISNULL(loca.address,'') as AddressName
		,location_id  --add 2024/12/15 time : 00.07 by Aomsin
		from APCSProDB.trans.surpluses as sur
		left join APCSProDB.trans.locations as loca on sur.location_id = loca.id
		where serial_no = @lotno
	END
	

END
