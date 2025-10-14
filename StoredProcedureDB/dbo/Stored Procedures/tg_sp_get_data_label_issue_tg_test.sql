-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_label_issue_tg_test]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Lotno_Allocat_Count Int = 0
	DECLARE @lotno_allocat_temp_count int = 0

	SELECT @Lotno_Allocat_Count = COUNT(*) FROM APCSProDB.method.allocat where LotNo = @lotno
	SELECT @lotno_allocat_temp_count = COUNT(*) FROM APCSProDB.method.allocat_temp where LotNo = @lotno

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[tg_sp_get_data_label_issue_tg_test] @lotno = ''' + @lotno + ''''


    -- Insert statements for procedure here

	IF @Lotno_Allocat_Count != 0
	BEGIN
		SELECT tranlot.lot_no as Lotno,
		device_names.name as ROHM_Model_Name,
		device_names.assy_name as ASSY_Model_Name,
		packages.name as Package,
		case when device_names.rank = ' ' then '-' else device_names.rank end as ranks, 
		device_names.tp_rank,
		tranlot.qty_pass as QtyPass_Standard,
		case when device_names.pcs_per_pack = 0 then '0'
			else (tranlot.qty_pass)%(device_names.pcs_per_pack) end as Totalhasuu,
		device_names.pcs_per_pack as Standerd_QTY, 
		case when device_names.pcs_per_pack = 0 then '0'
			 when ([device_names].[pcs_per_pack]) * (tranlot.[qty_pass]/([device_names].[pcs_per_pack])) = 0 then '0'
			 else ([device_names].[pcs_per_pack]) * (tranlot.[qty_pass]/([device_names].[pcs_per_pack])) end as  Qty_Full_Reel_All,
					tranlot.wip_state
		,'TRUE' As Status
		,case when denpyo.ORDER_MODEL_NAME is null then ' '
		else CAST(denpyo.ORDER_MODEL_NAME AS char(20)) end as R_Fukuoka_Model_Name
		,denpyo.MNO2 as Mno_STD
		FROM [APCSProDB].[trans].[lots]  as tranlot
		INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = tranlot.[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] as device_names  ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] as packages ON [device_names].[package_id]  = [packages].[id]
		INNER JOIN [APCSProDB].[method].[allocat] as allocat ON tranlot.lot_no = allocat.LotNo 
		left join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo on tranlot.lot_no = denpyo.LOT_NO_1
		WHERE tranlot.[lot_no] = @lotno
	END
	ELSE
	BEGIN
		IF @lotno_allocat_temp_count = 0
		BEGIN
			SELECT 'FALSE' AS Status ,'SEARCH DATA ERROR !!' AS Error_Message_ENG,N'ไม่พบข้อมูลของ lotno :' + @lotno   AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			,'Null' as Lotno,'Null' as Package,'Null' as ROHM_Model_Name,'0' as QtyPass_Standard,'0' as Totalhasuu,'0' as Standerd_QTY
			,'0' as Qty_Full_Reel_All
			RETURN
		END
		ELSE
		BEGIN
			SELECT tranlot.lot_no as Lotno,
			device_names.name as ROHM_Model_Name,
			device_names.assy_name as ASSY_Model_Name,
			packages.name as Package,
			case when device_names.rank = ' ' then '-' else device_names.rank end as ranks, 
			device_names.tp_rank,
			tranlot.qty_pass as QtyPass_Standard,
			case when device_names.pcs_per_pack = 0 then '0'
				else (tranlot.qty_pass)%(device_names.pcs_per_pack) end as Totalhasuu,
			device_names.pcs_per_pack as Standerd_QTY, 
			case when device_names.pcs_per_pack = 0 then '0'
				 when ([device_names].[pcs_per_pack]) * (tranlot.[qty_pass]/([device_names].[pcs_per_pack])) = 0 then '0'
				 else ([device_names].[pcs_per_pack]) * (tranlot.[qty_pass]/([device_names].[pcs_per_pack])) end as  Qty_Full_Reel_All,
						tranlot.wip_state
			,'TRUE' As Status
			,case when denpyo.ORDER_MODEL_NAME is null then ' '
			else CAST(denpyo.ORDER_MODEL_NAME AS char(20)) end as R_Fukuoka_Model_Name
			,denpyo.MNO2 as Mno_STD
			FROM [APCSProDB].[trans].[lots]  as tranlot
			INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = tranlot.[device_slip_id]
			INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
			INNER JOIN [APCSProDB].[method].[device_names] as device_names  ON [device_names].[id] = [device_versions].[device_name_id]
			INNER JOIN [APCSProDB].[method].[packages] as packages ON [device_names].[package_id]  = [packages].[id]
			INNER JOIN [APCSProDB].[method].[allocat_temp] as allocat ON tranlot.lot_no = allocat.LotNo 
			left join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo on tranlot.lot_no = denpyo.LOT_NO_1
			WHERE tranlot.[lot_no] = @lotno
		END
		
	END

END
