-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_label_issue_tg]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
AS
BEGIN
	
	--change store # 2023/09/18 time : 14.23 by Aomsin #
	EXEC [StoredProcedureDB].[dbo].[tg_sp_get_data_label_issue_tg_ver_003] @lotno = @lotno

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	--SET NOCOUNT ON;
	--DECLARE @Lotno_Allocat_Count Int = 0
	--DECLARE @lotno_allocat_temp_count int = 0

	--SELECT @Lotno_Allocat_Count = COUNT(*) FROM APCSProDB.method.allocat where LotNo = @lotno
	--SELECT @lotno_allocat_temp_count = COUNT(*) FROM APCSProDB.method.allocat_temp where LotNo = @lotno

	------update parameter lotno data : 2021/12/09 time : 11.42
	--INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	--([record_at]
 --     , [record_class]
 --     , [login_name]
 --     , [hostname]
 --     , [appname]
 --     , [command_text]
	--  , [lot_no])
	--SELECT GETDATE()
	--	,'4'
	--	,ORIGINAL_LOGIN()
	--	,HOST_NAME()
	--	,APP_NAME()
	--	,'EXEC [dbo].[tg_sp_get_data_label_issue_tg] @lotno = ''' + @lotno + ''''
	--	,@lotno

 --   -- Insert statements for procedure here

	--IF @Lotno_Allocat_Count != 0
	--BEGIN
	--		SELECT tranlot.lot_no as Lotno,
	--			device_names.name as ROHM_Model_Name,
	--			device_names.assy_name as ASSY_Model_Name,
	--			packages.name as Package,
	--			case when device_names.rank = ' ' then '-' else device_names.rank end as ranks, 
	--			device_names.tp_rank,
	--				tranlot.qty_pass as QtyPass_Standard,
	--			case when device_names.pcs_per_pack = 0 then '0'
	--		else (tranlot.qty_pass)%(device_names.pcs_per_pack) end as Totalhasuu,
	--			device_names.pcs_per_pack as Standerd_QTY, 
	--			case when device_names.pcs_per_pack = 0 then '0'
	--				when ([device_names].[pcs_per_pack]) * (tranlot.[qty_pass]/([device_names].[pcs_per_pack])) = 0 then '0'
	--		 else ([device_names].[pcs_per_pack]) * (tranlot.[qty_pass]/([device_names].[pcs_per_pack])) end as  Qty_Full_Reel_All
	--		,tranlot.wip_state
	--		,'TRUE' As Status
	--		,case when denpyo.ORDER_MODEL_NAME is null then ' '
	--			  else CAST(denpyo.ORDER_MODEL_NAME AS char(20)) end as R_Fukuoka_Model_Name
	--		,denpyo.MNO2 as Mno_STD
	--		--,case when (tranlot.qty_pass > device_names.pcs_per_pack or tranlot.qty_pass = device_names.pcs_per_pack) 
	--		--		then '0' else tranlot.quality_state end as quality_state
	--		,tranlot.quality_state as quality_state   --edit condition 2023/09/15 time : 15.19 by aomsin
	--		,[item_labels].[label_eng] AS [quality_state_name]
	--		FROM [APCSProDB].[trans].[lots]  as tranlot
	--		INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = tranlot.[device_slip_id]
	--		INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	--		INNER JOIN [APCSProDB].[method].[device_names] as device_names  ON [device_names].[id] = [device_versions].[device_name_id]
	--		INNER JOIN [APCSProDB].[method].[packages] as packages ON [device_names].[package_id]  = [packages].[id]
	--		INNER JOIN [APCSProDB].[method].[allocat] as allocat ON tranlot.lot_no = allocat.LotNo 
	--		left join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo on tranlot.lot_no = denpyo.LOT_NO_1
	--		left join APCSProDB.trans.item_labels ON item_labels.name = 'lots.quality_state'
	--			and tranlot.quality_state = item_labels.val
	--		WHERE tranlot.[lot_no] = @lotno
	--END
	--ELSE
	--BEGIN
	--	--check conditon allocat_temp data : 2021/12/06 Time :13.08
	--	IF @lotno_allocat_temp_count = 0
	--	BEGIN
	--		SELECT 'FALSE' AS Status ,'SEARCH DATA ERROR !!' AS Error_Message_ENG,N'ไม่พบข้อมูลของ lotno :' + @lotno   AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
	--		,'Null' as Lotno,'Null' as Package,'Null' as ROHM_Model_Name,'0' as QtyPass_Standard,'0' as Totalhasuu,'0' as Standerd_QTY
	--		,'0' as Qty_Full_Reel_All
	--		,'0' as wip_state
	--		,'0' as quality_state
	--		,'Null' as quality_state_name
	--		RETURN
	--	END
	--	ELSE
	--	BEGIN
	--		SELECT tranlot.lot_no as Lotno,
	--		device_names.name as ROHM_Model_Name,
	--		device_names.assy_name as ASSY_Model_Name,
	--		packages.name as Package,
	--		case when device_names.rank = ' ' then '-' else device_names.rank end as ranks, 
	--		device_names.tp_rank,
	--		tranlot.qty_pass as QtyPass_Standard,
	--		case when device_names.pcs_per_pack = 0 then '0'
	--			else (tranlot.qty_pass)%(device_names.pcs_per_pack) end as Totalhasuu,
	--		device_names.pcs_per_pack as Standerd_QTY, 
	--		case when device_names.pcs_per_pack = 0 then '0'
	--			 when ([device_names].[pcs_per_pack]) * (tranlot.[qty_pass]/([device_names].[pcs_per_pack])) = 0 then '0'
	--			 else ([device_names].[pcs_per_pack]) * (tranlot.[qty_pass]/([device_names].[pcs_per_pack])) end as  Qty_Full_Reel_All
	--		,tranlot.wip_state
	--		,'TRUE' As Status
	--		,case when denpyo.ORDER_MODEL_NAME is null then ' '
	--		else CAST(denpyo.ORDER_MODEL_NAME AS char(20)) end as R_Fukuoka_Model_Name
	--		,denpyo.MNO2 as Mno_STD
	--		--,tranlot.quality_state
	--		--,case when (tranlot.qty_pass > device_names.pcs_per_pack or tranlot.qty_pass = device_names.pcs_per_pack) 
	--		--		then '0' else tranlot.quality_state end as quality_state
	--		,tranlot.quality_state as quality_state  --edit condition 2023/09/15 time : 15.19 by aomsin
	--		,[item_labels].[label_eng] AS [quality_state_name]
	--		FROM [APCSProDB].[trans].[lots]  as tranlot
	--		INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = tranlot.[device_slip_id]
	--		INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	--		INNER JOIN [APCSProDB].[method].[device_names] as device_names  ON [device_names].[id] = [device_versions].[device_name_id]
	--		INNER JOIN [APCSProDB].[method].[packages] as packages ON [device_names].[package_id]  = [packages].[id]
	--		INNER JOIN [APCSProDB].[method].[allocat_temp] as allocat ON tranlot.lot_no = allocat.LotNo 
	--		left join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo on tranlot.lot_no = denpyo.LOT_NO_1
	--		left join APCSProDB.trans.item_labels ON item_labels.name = 'lots.quality_state'
	--			and tranlot.quality_state = item_labels.val
	--		WHERE tranlot.[lot_no] = @lotno
	--	END
	--END

END
