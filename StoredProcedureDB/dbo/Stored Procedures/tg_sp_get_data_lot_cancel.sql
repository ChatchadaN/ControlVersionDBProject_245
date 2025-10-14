-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_lot_cancel]
	-- Add the parameters for the stored procedure here
	@lot_standard varchar(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @CHECK_WIP_SATATE int = 0
	DECLARE @Lot_id int = 0
	DECLARE @Count_Rows int = 0

    -- Insert statements for procedure here
	select @Lot_id = id
	,@CHECK_WIP_SATATE = wip_state 
	from APCSProDB.trans.lots where lot_no = @lot_standard
	
	select @Count_Rows = COUNT(lot_id) from APCSProDB.trans.lot_combine where lot_id = @Lot_id

	--Add Condition 2022/06/07 Time : 10.14
	if not exists (select id from APCSProDB.trans.lots where lot_no = @lot_standard)
	BEGIN
		select @lot_standard as lotno
			,'nodata' as wip_state
			,'nodata' as wip_state_value
			,'nodata' as status_lotcombine
	END
	ELSE BEGIN
		select Trim(lot.lot_no) as lotno
		,lot.wip_state as wip_state
		,item.label_eng as wip_state_value
		,case when @Count_Rows = 0 then 'FALSE' else 'TRUE' end as status_lotcombine
		from APCSProDB.trans.lots as lot
		inner join APCSProDB.trans.item_labels as item on lot.wip_state = item.val
		where item.name = 'lots.wip_state' and lot.lot_no = @lot_standard
	END
	
	SELECT 'TRUE' AS Status ,'Search data success !!' AS Error_Message_ENG,N'ค้นหาข้อมูลสำเร็จ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
	RETURN
		
END
