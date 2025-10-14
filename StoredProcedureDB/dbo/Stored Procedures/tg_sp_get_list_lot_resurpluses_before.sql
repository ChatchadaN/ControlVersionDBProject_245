-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_list_lot_resurpluses_before]
	-- Add the parameters for the stored procedure here
	 @lot_id int = 0
	,@function_status int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF @lot_id != 0
	BEGIN
		IF @function_status = 23  --23 is rework
		BEGIN 
			print 'function_status = 23'
			select 
			 ROW_NUMBER() OVER(ORDER BY new_lot.created_at ASC) AS seq
			,new_lot.id as lot_id  --new_lot_id
			,new_lot.lot_no as lotno  --new_lot
			,old_lot.id as old_lot_id
			,old_lot.lot_no as old_lot
			,new_lot.qty_in as pcs
			--,new_lot.wip_state   
			,item.label_eng as status_hasuu --status_lot
			,new_lot.created_at
			,CAST(FORMAT(lot_cb.created_by,'000000') as char(6)) as emp_no
			,new_lot.production_category
			from APCSProDB.trans.lot_combine as lot_cb
			inner join APCSProDB.trans.lots as new_lot on lot_cb.lot_id = new_lot.id
			inner join APCSProDB.trans.lots as old_lot on lot_cb.member_lot_id = old_lot.id
			inner join APCSProDB.trans.item_labels as item on new_lot.wip_state = item.val
			and item.name = 'lots.wip_state'
			where member_lot_id = @lot_id
			and new_lot.production_category = 23

		END
		ELSE
		BEGIN
			print 'function_status else'
			select 
			 ROW_NUMBER() OVER(ORDER BY created_at ASC) AS seq
			,lot_id 
			,serial_no as lotno
			,pcs
			,item.label_eng as status_hasuu
			,created_at
			,CAST(FORMAT(created_by,'000000') as char(6)) as emp_no
			from APCSProDB.trans.surpluses 
			left join APCSProDB.trans.item_labels as item on surpluses.in_stock = item.val and item.name = 'surpluse_records.in_stock'
			where original_lot_id = @lot_id 
			order by created_at asc
		END
	END
END
