
CREATE PROCEDURE [trans].[get_history_lot_label_compare] 
	 @lot_no varchar(10)
AS
BEGIN
	select [lot_no]
		, [item_no]
		, [qrcode_1]
		, [qrcode_2]
		, CASE 
			WHEN [status] = 1 THEN 'PASS'
			WHEN [status] = 2 THEN 'DUPLICATE'
			ELSE 'FAIL'
		END AS [status]
	from [AppDB_app_244].[trans].[compare_data_center] 
	where [lot_no] = @lot_no;
END