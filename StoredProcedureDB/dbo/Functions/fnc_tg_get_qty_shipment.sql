CREATE FUNCTION [dbo].[fnc_tg_get_qty_shipment](
	@lot_no varchar(10)
)
    RETURNS @table_qty table (
		lot_no varchar(10)
		, qty_shipment int
		, qty_sum_ng int
	)
AS
BEGIN
  
	insert into @table_qty (lot_no, qty_shipment, qty_sum_ng)
	select TRIM(lots.lot_no) as lot_no
		, qty_out as qty_shipment
		, label_rec.qty_sum_ng as qty_sum_ng
	from APCSProDB.trans.lots
	cross apply(
		select SUM(CAST(qty as int)) as qty_sum_ng
		from APCSProDB.trans.label_issue_records 
		where lot_no = lots.lot_no
			and type_of_label = 0
	) as label_rec
	where lots.lot_no = @lot_no

	return;
END;