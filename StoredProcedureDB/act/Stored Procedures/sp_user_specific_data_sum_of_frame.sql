
CREATE PROCEDURE [act].[sp_user_specific_data_sum_of_frame] (
	@date_from DATETIME
	,@date_to DATETIME
	,@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	)
AS
BEGIN
	--DECLARE @date_from DATETIME = '2021-06-01 00:00:00'
	--DECLARE @date_to DATETIME = '2021-07-01 00:00:00'
	--DECLARE @package_id INT = NULL
	--DECLARE @process_id INT = 3
	--DECLARE @time_offset INT = 8
	--DECLARE @shift_code INT = NULL
	SELECT process_id
		,process_name
		,act_package_id AS package_id
		,package_name
		,count(lot_id) AS sum_lot_count
		,sum(qty_frame_in) AS sum_frame_in
	FROM (
		SELECT lpr.day_id
			,lpr.recorded_at
			,lpr.record_class
			,lpr.lot_id
			,tl.act_package_id
			,pk.name AS package_name
			,lpr.process_id
			,mp.name AS process_name
			,lpr.job_id
			,lpr.step_no
			,lpr.qty_in
			,lpr.qty_pass
			,lpr.machine_id
			,lpr.process_job_id
			,lpr.wip_state
			,lpr.qty_frame_in
		FROM apcsprodb.trans.lot_process_records AS lpr WITH (NOLOCK)
		INNER JOIN apcsprodb.trans.lots AS tl WITH (NOLOCK) ON tl.id = lpr.lot_id
		LEFT OUTER JOIN APCSProDB.method.device_names AS d WITH (NOLOCK) ON d.id = tl.act_device_name_id
			AND d.is_assy_only IN (
				0
				,1
				)
		LEFT JOIN APCSProDB.method.packages AS pk WITH (NOLOCK) ON pk.id = tl.act_package_id
		LEFT JOIN APCSProDB.method.package_groups AS pg WITH (NOLOCK) ON pg.id = pk.package_group_id
		INNER JOIN APCSProDB.method.processes AS mp WITH (NOLOCK) ON mp.id = lpr.process_id
		WHERE recorded_at BETWEEN @date_from
				AND @date_to
			AND (
				(
					@package_group_id IS NOT NULL
					AND pg.id = @package_group_id
					)
				OR (
					@package_group_id IS NULL
					AND pg.id > 0
					)
				)
			AND (
				(
					@package_id IS NOT NULL
					AND pk.id = @package_id
					)
				OR (
					@package_id IS NULL
					AND pk.id > 0
					)
				)
			AND (
				(
					@process_id IS NOT NULL
					AND mp.id = @process_id
					)
				OR (
					@process_id IS NULL
					AND mp.id > 0
					)
				)
			--AND process_id IN (
			--	6
			--	,34
			--	,24
			--	,7
			--	)
			AND record_class = 2
			AND lpr.wip_state <> 210
		) AS t1
	GROUP BY process_id
		,process_name
		,act_package_id
		,package_name
	ORDER BY process_id
		,sum_frame_in DESC
		,act_package_id
END
