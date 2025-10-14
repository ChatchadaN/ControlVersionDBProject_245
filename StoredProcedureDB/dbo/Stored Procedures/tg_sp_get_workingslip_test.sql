-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,Aomsin DSI>
-- Description:	<Description,,Test>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_workingslip_test] 
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @lot_std_id int = 0
	DECLARE @PDCD char(5)
	DECLARE @RF_MODEL char(20) 
	DECLARE @Qty_Lot_Std int = 0
	DECLARE @Qty_Hasuu int = 0

	select @lot_std_id = id,@Qty_Lot_Std = qty_pass from APCSProDB.trans.lots where lot_no = @lotno
	 
	
	select @PDCD = pdcd
	,@Qty_Hasuu = pcs 
	from APCSProDB.trans.surpluses where serial_no = @lotno

    -- Insert statements for procedure here

	--SET
	SET @RF_MODEL = (select top(1) R_Fukuoka_Model_Name
		from (select 
		case when denpyo.ORDER_MODEL_NAME is null then ' '
		else CAST(denpyo.ORDER_MODEL_NAME AS char(20)) end as R_Fukuoka_Model_Name
		from APCSProDB.trans.lot_combine as cb
		inner join APCSProDB.trans.lots as lot on cb.member_lot_id = lot.id
		inner join APCSProDB.method.device_names as dv on lot.act_device_name_id = dv.id
		inner join APCSProDB.method.packages as pk on dv.package_id = pk.id
		left join APCSProDB.trans.surpluses as sur on cb.member_lot_id = sur.lot_id
		inner join APCSProDB.trans.label_issue_records as lb_his on lb_his.lot_no = @lotno
		left join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo on lot.lot_no = denpyo.LOT_NO_1
		left join [APCSProDB].[method].[multi_labels] as multi_lb on dv.name = multi_lb.device_name
		where cb.lot_id = @lot_std_id and lb_his.type_of_label = '1') as t1
	where R_Fukuoka_Model_Name is not null and R_Fukuoka_Model_Name != ' ')

	select @Qty_Hasuu as qty_hasuu

	--GET
	select 
	ROW_NUMBER() OVER(ORDER BY sur.pcs) AS row_id  
	,cb.lot_id
	,member_lot_id
	,lot.lot_no as member_lot
	--,case when @Qty_Hasuu = 0 then @Qty_Lot_Std else sur.pcs end as qty_member_lot --lot normal
	,case when transfer_flag = 1 then transfer_pcs else sur.pcs end as qty_member_lot
	,CAST(pk.short_name as char(10)) as package_name
	,CAST(dv.name as char(20)) as device_name
	,case when CAST(dv.rank as char(7)) is null then CAST('' as char(7)) else CAST(dv.rank as char(7)) end as Rank
	,case when CAST(dv.tp_rank as char(2)) is null then CAST('' as char(2)) else CAST(dv.tp_rank as char(2)) end as TPRank
	,CAST(dv.assy_name as char(20)) as ASSY_Model_Name
	,dv.pcs_per_pack as packing_standard
	,case when SUBSTRING(Trim(lot.lot_no),5,1) = 'D' or SUBSTRING(Trim(lot.lot_no),5,1) = 'F' then  CAST('MX' as char(12))
	else CAST(lb_his.mno_hasuu as char(12)) end as MNo
	,lb_his.tomson_3 as tomson_3
	,case when SUBSTRING(Trim(lot.lot_no),5,1) = 'D' or SUBSTRING(Trim(lot.lot_no),5,1) = 'F' then  CAST('MX' as char(12))
		  when SUBSTRING(Trim(lot.lot_no),5,1) = 'B' then CAST(sur.mark_no as char(12))
		  else CAST(denpyo.MNO2 as char(12)) end as Mno_Hasuu
	,case when multi_lb.user_model_name is null then dv.name 
		else CAST(multi_lb.user_model_name AS char(20)) end as Customer_Device
	,case when denpyo.ORDER_MODEL_NAME is null 
		then case when @RF_MODEL is null 
			then SUBSTRING(dv.name,0,CHARINDEX ('-',dv.name)) 
		else @RF_MODEL end
	else CAST(denpyo.ORDER_MODEL_NAME AS char(20)) end as R_Fukuoka_Model_Name
	,CAST(dv.ft_name as char(20)) as ft_name
	,@PDCD as pdcd
	--,case when @Qty_Hasuu <> 0 then CAST('' as char(6)) else CAST((sur.pcs - @Qty_Lot_Std) as char(6)) end as Trans_fer
	,case when transfer_flag = 1 then sur.pcs else CAST('' as char(6)) end as Trans_fer
	from APCSProDB.trans.lot_combine as cb
	inner join APCSProDB.trans.lots as lot on cb.member_lot_id = lot.id
	inner join APCSProDB.method.device_names as dv on lot.act_device_name_id = dv.id
	inner join APCSProDB.method.packages as pk on dv.package_id = pk.id
	left join APCSProDB.trans.surpluses as sur on cb.member_lot_id = sur.lot_id
	inner join APCSProDB.trans.label_issue_records as lb_his on lb_his.lot_no = @lotno
	left join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo on lot.lot_no = denpyo.LOT_NO_1
	left join [APCSProDB].[method].[multi_labels] as multi_lb on dv.name = multi_lb.device_name
	where cb.lot_id = @lot_std_id and lb_his.type_of_label = '1'

	

END
