-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_incoming_label_detail]
	-- Add the parameters for the stored procedure here
	 --@lotno varchar(10) = ''
	 @arrival_packing_no char(13) = ''
	,@stats_print int --autoprint = 1 , reprint_on_web = 2
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


     IF @stats_print = 1
	 BEGIN
		SELECT incom_master.ship_date
		, incom_master.product_family as product_code_building
		, incom_master.arrival_packing_no as barcode_detail
		, incom_master.package_name
		, incom_detail.device_name
		, incom_detail.arrival_amount as qty_shipment
		, incom_detail.reel_count as noc  --noc
		, incom_detail.lot_no
		--QRCODE
		, CONVERT(CHAR(6),[incom_master].[ship_date],6) 
		+ CONVERT(CHAR(5),[incom_master].[product_family],5)
		+ CONVERT(CHAR(10),[incom_master].[package_name],10)
		+ CONVERT(CHAR(15),[incom_master].[destination],15)
 		+ CONVERT(CHAR(3),[incom_master].[storage_division],3)
		+ CONVERT(CHAR(6),[incom_master].[location_no],6)
		+ CONVERT(CHAR(13),[incom_master].[arrival_packing_no],13)
		+ CONVERT(CHAR(15),[incom_master].[special_column],15)
		+ CONVERT(CHAR(15),[incom_master].[special_column],15)
		+ CONVERT(CHAR(3),'001',3)
		+ CONVERT(CHAR(3),'001',3)
		+ CONVERT(CHAR(2),[incom_master].[fraction],2)
		+ CONVERT(CHAR(3),'001',3)
		--START
		--LOT 1
		+ CONVERT(CHAR(3),(CASE WHEN LEN(CAST([incom_detail].[line_no] AS varchar(3))) = 1 THEN '00' + CAST([incom_detail].[line_no] AS varchar(3)) WHEN LEN(CAST([incom_detail].[line_no] AS varchar(3))) = 2 THEN '0' + CAST([incom_detail].[line_no] AS varchar(3)) ELSE CONVERT(CHAR(3),[incom_detail].[line_no],3) END),3)
		+ CONVERT(CHAR(19),[incom_detail].[device_name],19)  
		+ RIGHT(CONCAT('000000000',[incom_detail].[arrival_amount]),9)
		+ RIGHT(CONCAT('00',[incom_detail].[reel_count]),2)
		+ CONVERT(CHAR(15),[incom_detail].[order_no],15) 
		+ CONVERT(CHAR(10),[incom_detail].[lot_no],10)
		--LOT 2
		+ CONVERT(CHAR(3),'000',3)
		+ CONVERT(CHAR(19),'',19)  
		+ RIGHT(CONCAT('000000000',0),9)
		+ RIGHT(CONCAT('00',0),2)
		+ CONVERT(CHAR(15),'',15) 
		+ CONVERT(CHAR(10),'',10)
		--LOT 3
		+ CONVERT(CHAR(3),'000',3)
		+ CONVERT(CHAR(19),'',19)  
		+ RIGHT(CONCAT('000000000',0),9)
		+ RIGHT(CONCAT('00',0),2)
		+ CONVERT(CHAR(15),'',15) 
		+ CONVERT(CHAR(10),'',10)
		--LOT 4
		+ CONVERT(CHAR(3),'000',3)
		+ CONVERT(CHAR(19),'',19)  
		+ RIGHT(CONCAT('000000000',0),9)
		+ RIGHT(CONCAT('00',0),2)
		+ CONVERT(CHAR(15),'',15) 
		+ CONVERT(CHAR(10),'',10)
		--LOT 5
		+ CONVERT(CHAR(3),'000',3)
		+ CONVERT(CHAR(19),'',19)  
		+ RIGHT(CONCAT('000000000',0),9)
		+ RIGHT(CONCAT('00',0),2)
		+ CONVERT(CHAR(15),'',15) 
		+ CONVERT(CHAR(10),'',10)
		--LOT 6
		+ CONVERT(CHAR(3),'000',3)
		+ CONVERT(CHAR(19),'',19)  
		+ RIGHT(CONCAT('000000000',0),9)
		+ RIGHT(CONCAT('00',0),2)
		+ CONVERT(CHAR(15),'',15) 
		+ CONVERT(CHAR(10),'',10)
		--END
		+ CONVERT(CHAR(10),[incom_master].[invoice_no],10)
		+ CONVERT(CHAR(26),'',26) as qrcode_detail
		,case when incom_master.product_code = 'QI000' then 'OVERSEA' else 'JAPAN' end as product_code
		,incom_master.arrival_packing_no
		,incom_master.version
		FROM [APCSProDB].[trans].[incoming_labels] as incom_master
		inner join [APCSProDB].[trans].[incoming_label_details] as incom_detail on [incom_master].[id] = [incom_detail].[incoming_id]
		where incom_detail.lot_no =  substring(@arrival_packing_no,1,10)
	 END
	 ELSE IF @stats_print = 2
	 BEGIN
		SELECT incom_master.ship_date
		, incom_master.product_family as product_code_building
		, incom_master.arrival_packing_no as barcode_detail
		, incom_master.package_name
		, incom_detail.device_name
		, incom_detail.arrival_amount as qty_shipment
		, incom_detail.reel_count as noc  --noc
		, incom_detail.lot_no
		--QRCODE
		, CONVERT(CHAR(6),[incom_master].[ship_date],6) 
		+ CONVERT(CHAR(5),[incom_master].[product_family],5)
		+ CONVERT(CHAR(10),[incom_master].[package_name],10)
		+ CONVERT(CHAR(15),[incom_master].[destination],15)
 		+ CONVERT(CHAR(3),[incom_master].[storage_division],3)
		+ CONVERT(CHAR(6),[incom_master].[location_no],6)
		+ CONVERT(CHAR(13),[incom_master].[arrival_packing_no],13)
		+ CONVERT(CHAR(15),[incom_master].[special_column],15)
		+ CONVERT(CHAR(15),[incom_master].[special_column],15)
		+ CONVERT(CHAR(3),'001',3)
		+ CONVERT(CHAR(3),'001',3)
		+ CONVERT(CHAR(2),[incom_master].[fraction],2)
		+ CONVERT(CHAR(3),'001',3)
		--START
		--LOT 1
		+ CONVERT(CHAR(3),(CASE WHEN LEN(CAST([incom_detail].[line_no] AS varchar(3))) = 1 THEN '00' + CAST([incom_detail].[line_no] AS varchar(3)) WHEN LEN(CAST([incom_detail].[line_no] AS varchar(3))) = 2 THEN '0' + CAST([incom_detail].[line_no] AS varchar(3)) ELSE CONVERT(CHAR(3),[incom_detail].[line_no],3) END),3)
		+ CONVERT(CHAR(19),[incom_detail].[device_name],19)  
		+ RIGHT(CONCAT('000000000',[incom_detail].[arrival_amount]),9)
		+ RIGHT(CONCAT('00',[incom_detail].[reel_count]),2)
		+ CONVERT(CHAR(15),[incom_detail].[order_no],15) 
		+ CONVERT(CHAR(10),[incom_detail].[lot_no],10)
		--LOT 2
		+ CONVERT(CHAR(3),'000',3)
		+ CONVERT(CHAR(19),'',19)  
		+ RIGHT(CONCAT('000000000',0),9)
		+ RIGHT(CONCAT('00',0),2)
		+ CONVERT(CHAR(15),'',15) 
		+ CONVERT(CHAR(10),'',10)
		--LOT 3
		+ CONVERT(CHAR(3),'000',3)
		+ CONVERT(CHAR(19),'',19)  
		+ RIGHT(CONCAT('000000000',0),9)
		+ RIGHT(CONCAT('00',0),2)
		+ CONVERT(CHAR(15),'',15) 
		+ CONVERT(CHAR(10),'',10)
		--LOT 4
		+ CONVERT(CHAR(3),'000',3)
		+ CONVERT(CHAR(19),'',19)  
		+ RIGHT(CONCAT('000000000',0),9)
		+ RIGHT(CONCAT('00',0),2)
		+ CONVERT(CHAR(15),'',15) 
		+ CONVERT(CHAR(10),'',10)
		--LOT 5
		+ CONVERT(CHAR(3),'000',3)
		+ CONVERT(CHAR(19),'',19)  
		+ RIGHT(CONCAT('000000000',0),9)
		+ RIGHT(CONCAT('00',0),2)
		+ CONVERT(CHAR(15),'',15) 
		+ CONVERT(CHAR(10),'',10)
		--LOT 6
		+ CONVERT(CHAR(3),'000',3)
		+ CONVERT(CHAR(19),'',19)  
		+ RIGHT(CONCAT('000000000',0),9)
		+ RIGHT(CONCAT('00',0),2)
		+ CONVERT(CHAR(15),'',15) 
		+ CONVERT(CHAR(10),'',10)
		--END
		+ CONVERT(CHAR(10),[incom_master].[invoice_no],10)
		+ CONVERT(CHAR(26),'',26) as qrcode_detail
		,case when incom_master.product_code = 'QI000' then 'OVERSEA' else 'JAPAN' end as product_code
		,incom_master.arrival_packing_no
		,incom_master.version
		FROM [APCSProDB].[trans].[incoming_labels] as incom_master
		inner join [APCSProDB].[trans].[incoming_label_details] as incom_detail on [incom_master].[id] = [incom_detail].[incoming_id]
		where incom_master.arrival_packing_no = @arrival_packing_no
	 END
	

  
 


END
