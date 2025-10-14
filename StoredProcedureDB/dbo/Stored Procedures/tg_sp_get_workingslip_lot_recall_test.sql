-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create Date,,20220319>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_workingslip_lot_recall_test] 
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

    -- Insert statements for procedure here
	select @lot_std_id = lots.id
	,@Qty_Lot_Std = lots.qty_in 
	,@PDCD = sur.pdcd
	from APCSProDB.trans.lots  
	inner join APCSProDB.trans.surpluses as sur on lots.id = sur.lot_id
	where lot_no = @lotno


	set @RF_MODEL = (select top 500  REVERSE(SUBSTRING(REVERSE(name)
	, CHARINDEX('-',  REVERSE(name)) + 1,LEN(name)))  
	from APCSProDB.method.device_names
	inner join APCSProDB.trans.lots on lots.act_device_name_id = device_names.id
	where lots.id = @lot_std_id)

	select
	ROW_NUMBER() OVER(ORDER BY sur.pcs) AS row_id
	,lot.id as lot_id
	,case when (select lots.id from APCSProDB.trans.lots where lots.lot_no = lot.external_lot_no) is null then ''
		else (select lots.id from APCSProDB.trans.lots where lots.lot_no = lot.external_lot_no) end
		as member_lot_id
	,case when lot.external_lot_no is null then '' else lot.external_lot_no end as member_lot
	--,sur.pcs as qty_member_lot
	,@Qty_Lot_Std as qty_member_lot  --update : 2022/04/28 time : 09.58
	,CAST(pk.short_name as char(10)) as package_name
	,CAST(dv.name as char(20)) as device_name
	,case when CAST(dv.rank as char(7)) is null then CAST('' as char(7)) else CAST(dv.rank as char(7)) end as Rank
	,case when CAST(dv.tp_rank as char(2)) is null then CAST('' as char(2)) else CAST(dv.tp_rank as char(2)) end as TPRank
	,CAST(dv.assy_name as char(20)) as ASSY_Model_Name
	,dv.pcs_per_pack as packing_standard
	,case when SUBSTRING(Trim(lot.lot_no),5,1) = 'D' or SUBSTRING(Trim(lot.lot_no),5,1) = 'F' then  CAST('MX' as char(12))
		else CAST(sur.mark_no as char(12)) end as MNo
	,case when sur.qc_instruction is null then '' else sur.qc_instruction end as tomson_3
	,case when sur.mark_no is null then '' else sur.mark_no end as Mno_Hasuu
	,case when multi_lb.user_model_name is null then dv.name 
		else CAST(multi_lb.user_model_name AS char(20)) end as Customer_Device
	,case when denpyo.ORDER_MODEL_NAME is null 
		then case when @RF_MODEL is null 
			then SUBSTRING(dv.name,0,CHARINDEX ('-',dv.name)) 
		else @RF_MODEL end
	else CAST(denpyo.ORDER_MODEL_NAME AS char(20)) end as R_Fukuoka_Model_Name
	,CAST(dv.ft_name as char(20)) as ft_name
	,@PDCD as pdcd
	,case when transfer_flag = 1 then sur.pcs else CAST('' as char(6)) end as Trans_fer
	from APCSProDB.trans.lots as lot
	inner join APCSProDB.method.device_names as dv on dv.id = lot.act_device_name_id
	inner join APCSProDB.method.packages as pk on pk.id = dv.package_id 
	left join APCSProDB.trans.surpluses as sur on sur.serial_no = lot.external_lot_no
	left join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo on lot.lot_no = denpyo.LOT_NO_1
	left join [APCSProDB].[method].[multi_labels] as multi_lb on dv.name = multi_lb.device_name
	where lot.id = @lot_std_id

END
