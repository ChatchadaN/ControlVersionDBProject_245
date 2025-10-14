
CREATE PROCEDURE [act].[sp_jigsearch_01] @process_id INT = NULL
	,@category_id INT = NULL
	,@production_id INT = NULL
	,@jig_state INT
AS
BEGIN
	--DECLARE @process_id INT = 3
	--DECLARE @category_id INT = NULL
	--DECLARE @production_id INT = NULL
	--DECLARE @jig_state INT = 12
	----check column 
	DECLARE @return_value INT = 0

	EXEC @return_value = StoredProcedureDB.act.sp_check_column_exist @schema = N'jig'
		,@table = N'categories'
		,@column = N'lsi_process_id'

	IF (@return_value = 1)
	BEGIN
		SELECT tj.[id]
			,mj.machine_id
			,mm.name AS machine_name
			,tj.[barcode]
			,tj.[smallcode]
			,tj.[qrcodebyuser]
			--,tj.[status]
			,jc.lsi_process_id AS process_id
			,mp.name AS process_name
			,tj.[jig_production_id]
			,jp.name AS jig_production_name
			,jp.category_id AS jig_category_id
			,jc.name AS jig_category_name
			,tj.[in_quantity]
			,tj.[quantity]
			,tj.[limit_base_date]
			,tj.[contents_record_id]
			,tj.[is_production_usage]
			,tj.[jig_state]
			,il.label_eng AS jig_state_label
			,tj.[process_state]
			,tj.[qc_state]
			,tj.[label_issue_state]
			,tj.[limit_state]
			,tj.[limit_date]
			,tj.[open_limit_date1]
			,tj.[open_limit_date2]
			,tj.[wait_limit_date]
			,tj.[location_id]
			,tj.[acc_location_id]
			,tj.[lot_no]
			,tj.[qc_comment_id]
			,tj.[qc_memo_id]
			,tj.[arrival_material_id]
			,tj.[counter_state]
			,tj.[root_jig_id]
			,tj.[depth]
			,tj.[sequence]
			,tj.[parent_jig_id]
			,tj.[created_at]
			,tj.[created_by]
			,tj.[updated_at]
			,tj.[updated_by]
			,mu.name AS updated_by_name
		FROM [APCSProDB].[trans].[jigs] AS tj WITH (NOLOCK)
		LEFT JOIN APCSProDB.trans.machine_jigs AS mj WITH (NOLOCK) ON mj.jig_id = tj.id
		LEFT JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = mj.machine_id
		LEFT JOIN APCSProDB.jig.productions AS jp WITH (NOLOCK) ON jp.id = tj.jig_production_id
		LEFT JOIN APCSProDB.jig.categories AS jc WITH (NOLOCK) ON jc.id = jp.category_id
		LEFT JOIN APCSProDB.method.processes AS mp WITH (NOLOCK) ON mp.id = jc.lsi_process_id
		LEFT JOIN APCSProDB.trans.item_labels AS il WITH (NOLOCK) ON il.val = tj.jig_state
			AND il.name = 'jigs.jig_state'
		LEFT JOIN apcsprodb.man.users AS mu WITH (NOLOCK) ON mu.id = tj.updated_by
		WHERE (
				(
					@process_id IS NOT NULL
					AND jc.lsi_process_id = @process_id
					)
				OR (
					@process_id IS NULL
					AND jc.lsi_process_id > 0
					)
				)
			AND (
				(
					@category_id IS NOT NULL
					AND jp.category_id = @category_id
					)
				OR (
					@category_id IS NULL
					AND jp.category_id > 0
					)
				)
			AND (
				(
					@production_id IS NOT NULL
					AND jp.id = @production_id
					)
				OR (
					@production_id IS NULL
					AND jp.id > 0
					)
				)
			AND (
				(
					@jig_state IS NOT NULL
					AND tj.jig_state = @jig_state
					)
				OR (
					@jig_state IS NULL
					AND tj.jig_state > 0
					)
				)
		ORDER BY mm.name
			,tj.barcode
	END
	ELSE
	BEGIN
		SELECT tj.[id]
			,mj.machine_id
			,mm.name AS machine_name
			,tj.[barcode]
			,tj.[smallcode]
			,tj.[qrcodebyuser]
			--,tj.[status]
			,NULL AS process_id
			,NULL AS process_name
			,tj.[jig_production_id]
			,jp.name AS jig_production_name
			,jp.category_id AS jig_category_id
			,jc.name AS jig_category_name
			,tj.[in_quantity]
			,tj.[quantity]
			,tj.[limit_base_date]
			,tj.[contents_record_id]
			,tj.[is_production_usage]
			,tj.[jig_state]
			,il.label_eng AS jig_state_label
			,tj.[process_state]
			,tj.[qc_state]
			,tj.[label_issue_state]
			,tj.[limit_state]
			,tj.[limit_date]
			,tj.[open_limit_date1]
			,tj.[open_limit_date2]
			,tj.[wait_limit_date]
			,tj.[location_id]
			,tj.[acc_location_id]
			,tj.[lot_no]
			,tj.[qc_comment_id]
			,tj.[qc_memo_id]
			,tj.[arrival_material_id]
			,tj.[counter_state]
			,tj.[root_jig_id]
			,tj.[depth]
			,tj.[sequence]
			,tj.[parent_jig_id]
			,tj.[created_at]
			,tj.[created_by]
			,tj.[updated_at]
			,tj.[updated_by]
			,mu.name AS updated_by_name
		FROM [APCSProDB].[trans].[jigs] AS tj WITH (NOLOCK)
		LEFT JOIN APCSProDB.trans.machine_jigs AS mj WITH (NOLOCK) ON mj.jig_id = tj.id
		LEFT JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = mj.machine_id
		LEFT JOIN APCSProDB.jig.productions AS jp WITH (NOLOCK) ON jp.id = tj.jig_production_id
		LEFT JOIN APCSProDB.jig.categories AS jc WITH (NOLOCK) ON jc.id = jp.category_id
		LEFT JOIN APCSProDB.trans.item_labels AS il WITH (NOLOCK) ON il.val = tj.jig_state
			AND il.name = 'jigs.jig_state'
		LEFT JOIN apcsprodb.man.users AS mu WITH (NOLOCK) ON mu.id = tj.updated_by
		WHERE (
				(
					@category_id IS NOT NULL
					AND jp.category_id = @category_id
					)
				OR (
					@category_id IS NULL
					AND jp.category_id > 0
					)
				)
			AND (
				(
					@production_id IS NOT NULL
					AND jp.id = @production_id
					)
				OR (
					@production_id IS NULL
					AND jp.id > 0
					)
				)
			AND (
				(
					@jig_state IS NOT NULL
					AND tj.jig_state = @jig_state
					)
				OR (
					@jig_state IS NULL
					AND tj.jig_state > 0
					)
				)
		ORDER BY mm.name
			,tj.barcode
	END
END
