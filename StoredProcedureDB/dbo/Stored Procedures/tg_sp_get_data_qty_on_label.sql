-- =============================================
-- Author:		<Author,,Name : AOMSIN>
-- Create date: <Create Date,2021/10/04,>
-- Description:	<Description,GET DATA QTY ON LABEL FORSLIP,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_qty_on_label]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT  
	lb_rec.lot_no as LotNo
	,CONVERT(int,lb_rec.qty) as Good_Product_QTY
	,pk.name as Type_Name
	,dn.name as ROHM_Model_Name
	,dn.pcs_per_pack as Packing_Standerd_QTY
	FROM APCSProDB.trans.label_issue_records AS lb_rec
	INNER JOIN APCSProDB.trans.lots AS lot ON lot.lot_no = lb_rec.lot_no
	INNER JOIN APCSProDB.method.packages AS pk ON lot.act_package_id = pk.id
	INNER JOIN APCSProDB.method.device_names AS dn ON lot.act_device_name_id = dn.id
	WHERE lb_rec.lot_no = @lotno
	AND lb_rec.type_of_label = 1

	

END
