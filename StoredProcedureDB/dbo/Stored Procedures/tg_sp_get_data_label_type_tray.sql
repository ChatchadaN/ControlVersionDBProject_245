-- =============================================
-- Author:		<Author,,Vanatjaya S. 009131 and Kittithat P. 009670>
-- Create date: <Create Date,2021/09/29,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_label_type_tray]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
	,@type_label int = 0
	,@tomson_num int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @type_label = 5
	BEGIN
		DECLARE @pc_code int = 0
		select @pc_code = case when pc_instruction_code is null then 0 else pc_instruction_code end from APCSProDB.trans.lots where lot_no = @lotno

		IF @pc_code = 11
		BEGIN
				SELECT [recorded_at]
				, [operated_by]
				, [type_of_label]
				, [label_rec].[lot_no]
				, [customer_device]
				, [rohm_model_name] 
				, FORMAT(CONVERT(int,qty),'#,0') as [qty]
				, [barcode_lotno]
				, [tomson_box]
				, [tomson_3]
				, [box_type]
				, [barcode_bottom]
				, [mno_std]
				, [std_qty_before]
				, [mno_hasuu]
				, [hasuu_qty_before]
				, [no_reel]
				, [qrcode_detail]
				, [type_label_laterat]
				, [mno_std_laterat]
				, [mno_hasuu_laterat]
				, [barcode_device_detail]
				, [op_no]
				, [op_name]
				, [seq]
				, [ip_address]
				, [msl_label] as MSL_LAVEL
				, [floor_life]
				, [ppbt]
				, [re_comment]
				, [version]
				, [is_logo]
				, [mc_name]
				, [barcode_1_mod]
				, [barcode_2_mod]
				, ISNULL(NULLIF(seal, ' '), ' ') as seal
				, [create_at]
				, [create_by]
				, [update_at]
				, [update_by]
				, ISNULL(NULLIF(sur.pdcd, ' '), ' ') as PDCD
				, dn.assy_name as Assy_Name
				, case 
					when symbo_lot.lot_no is null then 
						case 
							when symbo_device.lot_no is null then 0
							else 1
						end
					else 
						case 
							when symbo_lot.device_name is null then 0
							else 1
						end
				end as [is_symbol]
				,case when type_of_label = 21 then '1' else '0' end as check_hasuu 
			FROM APCSProDB.trans.label_issue_records as label_rec WITH (NOLOCK)
			left join APCSProDB.trans.lots as lot WITH (NOLOCK) on label_rec.lot_no = lot.lot_no
			left join APCSProDB.trans.surpluses as sur WITH (NOLOCK) on lot.lot_no = sur.serial_no
			left join APCSProDB.method.device_names as dn  WITH (NOLOCK) on lot.act_device_name_id = dn.id
			left join [DBxDW].[dbo].[device_condition_symbol] as symbo_lot on symbo_lot.lot_no = label_rec.lot_no
			left join [DBxDW].[dbo].[device_condition_symbol] as symbo_device on symbo_lot.lot_no is null 
				and symbo_device.device_name = label_rec.rohm_model_name
				and symbo_device.lot_no = 'ALL'
			where label_rec.lot_no = @lotno 
			and type_of_label in (5,21)
			--and no_reel = @tomson_num
			order by no_reel asc
		END
		ELSE
		BEGIN
				SELECT [recorded_at]
				, [operated_by]
				, [type_of_label]
				, [label_rec].[lot_no]
				, [customer_device]
				, [rohm_model_name] 
				, FORMAT(CONVERT(int,qty),'#,0') as [qty]
				, [barcode_lotno]
				, [tomson_box]
				, [tomson_3]
				, [box_type]
				, [barcode_bottom]
				, [mno_std]
				, [std_qty_before]
				, [mno_hasuu]
				, [hasuu_qty_before]
				, [no_reel]
				, [qrcode_detail]
				, [type_label_laterat]
				, [mno_std_laterat]
				, [mno_hasuu_laterat]
				, [barcode_device_detail]
				, [op_no]
				, [op_name]
				, [seq]
				, [ip_address]
				, [msl_label] as MSL_LAVEL
				, [floor_life]
				, [ppbt]
				, [re_comment]
				, [version]
				, [is_logo]
				, [mc_name]
				, [barcode_1_mod]
				, [barcode_2_mod]
				, ISNULL(NULLIF(seal, ' '), ' ') as seal
				, [create_at]
				, [create_by]
				, [update_at]
				, [update_by]
				, ISNULL(NULLIF(sur.pdcd, ' '), ' ') as PDCD
				, dn.assy_name as Assy_Name
				, case 
					when symbo_lot.lot_no is null then 
						case 
							when symbo_device.lot_no is null then 0
							else 1
						end
					else 
						case 
							when symbo_lot.device_name is null then 0
							else 1
						end
				end as [is_symbol]
				,'0' as check_hasuu
			FROM APCSProDB.trans.label_issue_records as label_rec WITH (NOLOCK)
			left join APCSProDB.trans.lots as lot WITH (NOLOCK) on label_rec.lot_no = lot.lot_no
			left join APCSProDB.trans.surpluses as sur WITH (NOLOCK) on lot.lot_no = sur.serial_no
			left join APCSProDB.method.device_names as dn  WITH (NOLOCK) on lot.act_device_name_id = dn.id
			left join [DBxDW].[dbo].[device_condition_symbol] as symbo_lot on symbo_lot.lot_no = label_rec.lot_no
			left join [DBxDW].[dbo].[device_condition_symbol] as symbo_device on symbo_lot.lot_no is null 
				and symbo_device.device_name = label_rec.rohm_model_name
				and symbo_device.lot_no = 'ALL'
			where label_rec.lot_no = @lotno and type_of_label = @type_label and no_reel = @tomson_num
			order by type_of_label desc,no_reel asc
		END
		
	END
	ELSE IF @type_label = 6
	BEGIN
		IF @tomson_num = 0  --Add Condition : 2022/07/20 Time : 08.31
		BEGIN
			DECLARE @count_qty_set_tray int = 0
			DECLARE @Standard_pack int = 0
			DECLARE @Standard_Tray int = 0

			SELECT @count_qty_set_tray = REPLACE(ISNULL(tray_qty.use_qty_tray,''),' set','') 
				   ,@Standard_pack = device_names.pcs_per_pack
			FROM APCSProDB.trans.lots 
			INNER JOIN [APCSProDB].method.device_slips ON device_slips.device_slip_id = lots.device_slip_id 
			INNER JOIN [APCSProDB].method.device_versions ON device_versions.device_id = device_slips.device_id 
			AND [APCSProDB].method.device_slips.is_released = 1 			
			--AND device_versions.device_type = 6 --- comment ถ้าใช้เลข Lot ในการเรียก Store แล้ว
			INNER JOIN [APCSProDB].method.device_names ON [APCSProDB].method.device_names.id = [APCSProDB].method.device_versions.device_name_id 
			INNER JOIN [APCSProDB].method.packages ON [APCSProDB].method.device_names.package_id = [APCSProDB].method.packages.id 
			INNER JOIN [APCSProDB].method.device_flows ON [APCSProDB].method.device_slips.device_slip_id = [APCSProDB].method.device_flows.device_slip_id
			LEFT JOIN  
			(SELECT  ms.id,ms.name,comment,details,p.name as mat_name
			FROM  [APCSProDB].method.material_sets ms 
			INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id INNER JOIN
			[APCSProDB].material.productions p ON ml.material_group_id = p.id 
			where (ms.process_id = 317 OR ms.process_id = 18)
			) mat

			PIVOT ( 
				max(mat_name)
				FOR details
				IN (
				[TUBE],[TRAY]
				)
			) as pvt ON [APCSProDB].method.device_flows.material_set_id = pvt.id

			LEFT JOIN (SELECT msl.id,msl.tomson_code,ib.reel_count FROM APCSProDB.method.material_set_list msl
			LEFT JOIN APCSProDB.method.incoming_boxs ib ON ib.tomson_code = msl.tomson_code AND ib.idx = 1
			WHERE msl.tomson_code IS NOT NULL) AS tb ON tb.id = pvt.id

			LEFT JOIN (SELECT  ms.id,ms.name,comment,details,p.name as mat_name, CONVERT(VARCHAR(10), CONVERT(int, use_qty)) + ' '+ il.label_eng as use_qty_tray 
			FROM [APCSProDB].method.material_sets ms 
			INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id 
			INNER JOIN [APCSProDB].material.productions p ON ml.material_group_id = p.id 
			LEFT JOIN APCSProDB.method.item_labels il ON il.val = ml.use_qty_unit and il.name = 'material_set_list.use_qty_unit'
			where (ms.process_id = 317 OR ms.process_id = 18) and details = 'TRAY'
			) AS tray_qty ON tray_qty.id = pvt.id

			--LEFT JOIN StoredProcedureDB.dbo.IS_PACKING_MAT as pack_mat on device_names.name = pack_mat.ROHM_Model_Name  --close : 2022/07/19 time : 10.38
			LEFT JOIN [APCSProDB].[method].[jobs] AS [job] ON [job].[id] = device_flows.[job_id]
			WHERE device_flows.job_id = 317 
			and lot_no = @Lotno

			select @Standard_Tray = (@Standard_pack/@count_qty_set_tray)
			--Tray Shipment
			SELECT [recorded_at]
				, [operated_by]
				, [type_of_label]
				, [label_rec].[lot_no]
				, [customer_device]
				, [rohm_model_name] 
				, FORMAT(CONVERT(int,qty),'#,0') as [qty]
				, [barcode_lotno]
				, [tomson_box]
				, [tomson_3]
				, [box_type]
				, [barcode_bottom]
				, [mno_std]
				, [std_qty_before]
				, [mno_hasuu]
				, [hasuu_qty_before]
				, [no_reel]
				, [qrcode_detail]
				, [type_label_laterat]
				, [mno_std_laterat]
				, [mno_hasuu_laterat]
				, [barcode_device_detail]
				, [op_no]
				, [op_name]
				, [seq]
				, [ip_address]
				, [msl_label] as MSL_LAVEL
				, [floor_life]
				, [ppbt]
				, [re_comment]
				, [version]
				, [is_logo]
				, [mc_name]
				, [barcode_1_mod]
				, [barcode_2_mod]
				, ISNULL(NULLIF(seal, ' '), ' ') as seal
				, [create_at]
				, [create_by]
				, [update_at]
				, [update_by]
				, ISNULL(NULLIF(sur.pdcd, ' '), ' ') as PDCD
				, dn.assy_name as Assy_Name
				, case 
					when symbo_lot.lot_no is null then 
						case 
							when symbo_device.lot_no is null then 0
							else 1
						end
					else 
						case 
							when symbo_lot.device_name is null then 0
							else 1
						end
				end as [is_symbol]
				,case when qty < @Standard_Tray then '1' else '0' end as check_hasuu 
			FROM APCSProDB.trans.label_issue_records as label_rec WITH (NOLOCK)
			left join APCSProDB.trans.lots as lot WITH (NOLOCK) on label_rec.lot_no = lot.lot_no
			left join APCSProDB.trans.surpluses as sur WITH (NOLOCK) on lot.lot_no = sur.serial_no
			left join APCSProDB.method.device_names as dn  WITH (NOLOCK) on lot.act_device_name_id = dn.id
			left join [DBxDW].[dbo].[device_condition_symbol] as symbo_lot on symbo_lot.lot_no = label_rec.lot_no
			left join [DBxDW].[dbo].[device_condition_symbol] as symbo_device on symbo_lot.lot_no is null 
				and symbo_device.device_name = label_rec.rohm_model_name
				and symbo_device.lot_no = 'ALL'
			where label_rec.lot_no = @lotno 
			and type_of_label = @type_label 
			--and seq = @tomson_num
			order by type_of_label desc,no_reel asc
		END
		ELSE
		BEGIN
			--Tray Normal
			SELECT [recorded_at]
				, [operated_by]
				, [type_of_label]
				, [label_rec].[lot_no]
				, [customer_device]
				, [rohm_model_name] 
				, FORMAT(CONVERT(int,qty),'#,0') as [qty]
				, [barcode_lotno]
				, [tomson_box]
				, [tomson_3]
				, [box_type]
				, [barcode_bottom]
				, [mno_std]
				, [std_qty_before]
				, [mno_hasuu]
				, [hasuu_qty_before]
				, [no_reel]
				, [qrcode_detail]
				, [type_label_laterat]
				, [mno_std_laterat]
				, [mno_hasuu_laterat]
				, [barcode_device_detail]
				, [op_no]
				, [op_name]
				, [seq]
				, [ip_address]
				, [msl_label] as MSL_LAVEL
				, [floor_life]
				, [ppbt]
				, [re_comment]
				, [version]
				, [is_logo]
				, [mc_name]
				, [barcode_1_mod]
				, [barcode_2_mod]
				, ISNULL(NULLIF(seal, ' '), ' ') as seal
				, [create_at]
				, [create_by]
				, [update_at]
				, [update_by]
				, ISNULL(NULLIF(sur.pdcd, ' '), ' ') as PDCD
				, dn.assy_name as Assy_Name
				, case 
					when symbo_lot.lot_no is null then 
						case 
							when symbo_device.lot_no is null then 0
							else 1
						end
					else 
						case 
							when symbo_lot.device_name is null then 0
							else 1
						end
				end as [is_symbol]
				,'0' as check_hasuu
			FROM APCSProDB.trans.label_issue_records as label_rec WITH (NOLOCK)
			left join APCSProDB.trans.lots as lot WITH (NOLOCK) on label_rec.lot_no = lot.lot_no
			left join APCSProDB.trans.surpluses as sur WITH (NOLOCK) on lot.lot_no = sur.serial_no
			left join APCSProDB.method.device_names as dn  WITH (NOLOCK) on lot.act_device_name_id = dn.id
			left join [DBxDW].[dbo].[device_condition_symbol] as symbo_lot on symbo_lot.lot_no = label_rec.lot_no
			left join [DBxDW].[dbo].[device_condition_symbol] as symbo_device on symbo_lot.lot_no is null 
				and symbo_device.device_name = label_rec.rohm_model_name
				and symbo_device.lot_no = 'ALL'
			where label_rec.lot_no = @lotno and type_of_label = @type_label and seq = @tomson_num
			order by type_of_label desc,no_reel asc
		END
		
	END

END
