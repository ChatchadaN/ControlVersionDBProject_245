-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_pc_request] 
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @pc_state int = 0
    -- Insert statements for procedure here
	DECLARE @datetime DATETIME
	DECLARE @year_now int = 0
	SET @datetime = GETDATE()
	SELECT @year_now = (FORMAT(@datetime,'yy') - 3)

	select sur.serial_no as lot_no
	,sur.pcs as Hasuu_qty
	,pk.name as package_name
	,dn.name as device_name 
	,dn.pcs_per_pack as packing_standard_qty 
	--,dn.rank as rank_val --close 2023/03/20 time : 08.30
	,case when dn.rank is null then '' else dn.rank end as rank_val  --add condition 2023/03/20 time : 08.30
	,dn.tp_rank as tp_rank
	,case when sur.qc_instruction is null then '' else sur.qc_instruction end as qc_instruction
	,Fukuoka.R_Fukuoka_Model_Name as R_Fukuoka_Model_Name
	,sur.mark_no as Mno_Hasuu
	,case when sur.pdcd = '' then '' else sur.pdcd end as pdcd
	,case when sur.pdcd = 'QI000' then 'B' 
		  when sur.pdcd = 'QI001' then 'C' 
			else ' ' end as out_out_flag
	,TRIM(pk_g.name) as package_group
	,pk.pcs_per_tube_or_tray  --add data 2023/02/24 time : 10.30
	from APCSProDB.trans.surpluses as sur
	inner join APCSProDB.trans.lots as lot on sur.serial_no = lot.lot_no
	inner join [APCSProDB].[method].[device_names] as dn  ON lot.act_device_name_id = dn.id
	inner join [APCSProDB].[method].[packages] as pk ON lot.act_package_id = pk.id
	inner join [APCSProDB].[method].[package_groups] as pk_g on pk.package_group_id = pk_g.id
	--LEFT join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo on sur.serial_no = denpyo.LOT_NO_2 --close 2023/02/24 time : 10.30
	left join APCSProDB.method.allocat_temp as allocat on lot.lot_no = allocat.LotNo  --Edit query 2023/02/24 time : 10.30 
	left join (
		select ROHM_Model_Name
			, ASSY_Model_Name
			, R_Fukuoka_Model_Name
		from APCSProDB.method.allocat_temp
		group by ROHM_Model_Name
			, ASSY_Model_Name
			, R_Fukuoka_Model_Name
	) as Fukuoka on trim(dn.name) = trim(Fukuoka.ROHM_Model_Name)
		and trim(dn.assy_name) = trim(Fukuoka.ASSY_Model_Name)
	where sur.serial_no = @lotno 
	-- Add Condition is_ability = 1 สำหรับงาน hasuu long standing (เกิน 3 ปี) re-test กลับมาใช้งานได้ create date time : 2022/06/24 time 09.42
	and (SUBSTRING(sur.serial_no,1,2) >= @year_now or sur.is_ability = 1)  --add condition 2022/05/26 time : 12.55

END
