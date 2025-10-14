
CREATE FUNCTION [act].[fnc_LeadTime_united_v2] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@job_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@from INT
	,@to INT
	,@N DECIMAL(2, 1) = 1 --目標leadtime計算用係数
	,@time_offset INT = 0
	)
RETURNS @retTbl TABLE (
	day_id INT
	,new_day_id INT
	,hour_code TINYINT
	,shift_code INT
	,not_target_flag INT
	,package_id INT NULL
	,
	--package_group_id INT NULL,
	process_id INT NULL
	,job_id INT NULL
	,device_id INT NULL
	,lot_id INT NULL
	,lot_no NVARCHAR(32) NULL
	,lot_type NVARCHAR(32) NULL
	,is_assy_only INT NULL
	,pass_pcs INT NULL
	,std_time INT NULL
	,lead_time INT NULL
	,wait_time INT NULL
	,process_time INT NULL
	,run_time INT NULL
	,target_lead_time INT NULL
	)

BEGIN
	---------------------------------------------------------------------------------------------------------
	-- process指定無し
	---------------------------------------------------------------------------------------------------------
	IF @process_id IS NULL
	BEGIN
		INSERT INTO @retTbl
		SELECT t2.day_id AS day_id
			,CASE 
				WHEN t2.hour_code < @time_offset + 1
					THEN t2.day_id - 1
				ELSE t2.day_id
				END AS new_day_id
			,t2.hour_code AS hour_code
			,CASE 
				WHEN @time_offset <= 12
					THEN CASE 
							WHEN t2.hour_code BETWEEN (@time_offset + 1)
									AND (@time_offset + 12)
								THEN 0
							ELSE 1
							END
				ELSE CASE 
						WHEN t2.hour_code BETWEEN (@time_offset - 12 + 1)
								AND (@time_offset)
							THEN 1
						ELSE 0
						END
				END AS shift_code
			,CASE 
				WHEN t2.is_assy_only IN (
						0
						,1
						)
					THEN 0
				ELSE 1
				END AS not_target_flag
			,t2.package_id AS package_id
			,NULL AS process_id
			,NULL AS job_id
			,t2.device_id AS device_id
			,t2.lot_id AS lot_id
			,t2.lot_no AS lot_no
			,t2.lot_type AS lot_type
			,t2.is_assy_only AS is_assy_only
			,t2.pass_pcs AS pass_pcs
			,t2.std_time AS std_time
			,t2.lead_time AS lead_time
			,
			--t2.wait_time AS wait_time,
			CASE 
				WHEN t2.wait_time >= 0
					THEN t2.wait_time
				ELSE 0
				END AS wait_time
			,t2.process_time AS process_time
			,NULL AS run_time
			,CASE 
				WHEN t2.normal_leadtime_minutes = 0
					THEN NULL
				ELSE t2.normal_leadtime_minutes * @N
				END AS target_lead_time
		FROM (
			SELECT dd.day_id AS day_id
				,dd.hour_code AS hour_code
				,t1.package_id AS package_id
				,t1.lot_id AS lot_id
				,t1.device_id AS device_id
				,t1.pass_pcs AS pass_pcs
				,t1.std_time AS std_time
				,t1.lead_time AS lead_time
				,t1.wait_time AS wait_time
				,t1.process_time AS process_time
				,CASE 
					WHEN t1.normal_leadtime_minutes = NULL
						THEN 0
					ELSE t1.normal_leadtime_minutes
					END AS normal_leadtime_minutes
				,t1.lot_no AS lot_no
				,substring(t1.lot_no, 5, 1) AS lot_type
				,t1.device_name AS device_name
				,t1.is_assy_only AS is_assy_only
			FROM (
				SELECT ddy.id AS day_id
					,dh.code AS hour_code
				FROM apcsprodwh.dwh.dim_days AS ddy WITH (NOLOCK)
				CROSS JOIN apcsprodwh.dwh.dim_hours AS dh WITH (NOLOCK)
				) AS dd
			LEFT OUTER JOIN (
				SELECT fs.day_id AS day_id
					,fs.hour_code AS hour_code
					,fs.package_id AS package_id
					,fs.device_id AS device_id
					,fs.lot_id AS lot_id
					,fs.pass_pcs AS pass_pcs
					,fs.std_time AS std_time
					,fs.lead_time AS lead_time
					,fs.wait_time AS wait_time
					,fs.process_time AS process_time
					,tl.lot_no AS lot_no
					,tl.wip_state AS wip_state
					,tl.device_slip_id AS device_slip_id
					,ds.normal_leadtime_minutes AS normal_leadtime_minutes
					,dn.name AS device_name
					,dn.is_assy_only AS is_assy_only
				FROM apcsprodwh.dwh.fact_shipment AS fs WITH (NOLOCK)
				INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = fs.lot_id
				LEFT OUTER JOIN APCSProDB.method.device_slips AS ds WITH (NOLOCK) ON ds.device_slip_id = tl.device_slip_id
				LEFT OUTER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = fs.device_id
				LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = fs.device_id
				WHERE (
						(
							@package_id IS NOT NULL
							AND fs.package_id = @package_id
							)
						OR (
							@package_id IS NULL
							AND @package_group_id IS NOT NULL
							AND fs.package_group_id = @package_group_id
							)
						OR (
							@package_id IS NULL
							AND @package_group_id IS NULL
							AND fs.package_id > 0
							)
						)
					AND (
						(
							@device_name IS NOT NULL
							AND ddv.name = @device_name
							)
						OR (@device_name IS NULL)
						)
				) AS t1 ON t1.day_id = dd.day_id
				AND t1.hour_code = dd.hour_code
			WHERE dd.day_id BETWEEN @from - 1
					AND @to + 1
			) AS t2
	END
			---------------------------------------------------------------------------------------------------------
			-- process指定有
			---------------------------------------------------------------------------------------------------------
	ELSE
	BEGIN
		INSERT INTO @retTbl
		SELECT t2.day_id AS day_id
			,CASE 
				WHEN t2.hour_code < @time_offset + 1
					THEN t2.day_id - 1
				ELSE t2.day_id
				END AS new_day_id
			,t2.hour_code AS hour_code
			,CASE 
				WHEN @time_offset <= 12
					THEN CASE 
							WHEN t2.hour_code BETWEEN (@time_offset + 1)
									AND (@time_offset + 12)
								THEN 0
							ELSE 1
							END
				ELSE CASE 
						WHEN t2.hour_code BETWEEN (@time_offset - 12 + 1)
								AND (@time_offset)
							THEN 1
						ELSE 0
						END
				END AS shift_code
			,CASE 
				WHEN t2.is_assy_only IN (
						0
						,1
						)
					THEN 0
				WHEN t2.is_skipped IN (
						0
						,1
						)
					THEN 0
				ELSE 1
				END AS not_target_flag
			,t2.package_id AS package_id
			,t2.process_id AS process_id
			,t2.job_id AS job_id
			,t2.device_id AS device_id
			,t2.lot_id AS lot_id
			,t2.lot_no AS lot_no
			,t2.lot_type AS lot_type
			,t2.is_assy_only AS is_assy_only
			,t2.pass_pcs AS pass_pcs
			,t2.std_time AS std_time
			,
			--fact_endにはlead_timeが無いのでwait+process
			ISNULL(t2.wait_time, 0) + t2.process_time AS lead_time
			,CASE 
				WHEN t2.wait_time >= 0
					THEN t2.wait_time
				ELSE 0
				END AS wait_time
			,t2.process_time AS process_time
			,t2.run_time AS rum_time
			,CASE 
				WHEN t2.process_minutes = 0
					THEN NULL
				ELSE t2.process_minutes * @N
				END AS target_lead_time
		FROM (
			SELECT dd.day_id AS day_id
				,dd.hour_code AS hour_code
				,t1.package_id AS package_id
				,t1.process_id AS process_id
				,t1.job_id AS job_id
				,t1.device_id AS device_id
				,t1.lot_id AS lot_id
				,t1.pass_pcs AS pass_pcs
				,t1.std_time AS std_time
				,
				--t1.lead_time AS lead_time,
				t1.wait_time AS wait_time
				,t1.process_time AS process_time
				,t1.run_time AS run_time
				,CASE 
					WHEN t1.process_minutes = NULL
						THEN 0
					ELSE t1.process_minutes
					END AS process_minutes
				,t1.lot_no AS lot_no
				,substring(t1.lot_no, 5, 1) AS lot_type
				,t1.device_name AS device_name
				,t1.is_assy_only AS is_assy_only
				,t1.is_skipped AS is_skipped
			FROM (
				SELECT ddy.id AS day_id
					,dh.code AS hour_code
				FROM apcsprodwh.dwh.dim_days AS ddy WITH (NOLOCK)
				CROSS JOIN apcsprodwh.dwh.dim_hours AS dh WITH (NOLOCK)
				) AS dd
			LEFT OUTER JOIN (
				SELECT fe.day_id AS day_id
					,fe.hour_code AS hour_code
					,fe.package_id AS package_id
					,fe.process_id AS process_id
					,fe.job_id AS job_id
					,fe.device_id AS device_id
					,fe.lot_id AS lot_id
					,fe.pass_pcs AS pass_pcs
					,fe.code AS code
					,fe.std_time AS std_time
					,fe.wait_time AS wait_time
					,fe.process_time AS process_time
					,fe.run_time AS run_time
					,tl.lot_no AS lot_no
					,tl.wip_state AS wip_state
					,tl.device_slip_id AS device_slip_id
					,df.process_minutes AS process_minutes
					,df.is_skipped AS is_skipped
					,dn.name AS device_name
					,dn.is_assy_only AS is_assy_only
				FROM apcsprodwh.dwh.fact_end AS fe WITH (NOLOCK)
				INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = fe.lot_id
				LEFT OUTER JOIN APCSProDB.method.device_slips AS ds WITH (NOLOCK) ON ds.device_slip_id = tl.device_slip_id
				LEFT OUTER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = fe.device_id
				LEFT OUTER JOIN APCSProDB.method.device_flows AS df WITH (NOLOCK) ON df.device_slip_id = tl.device_slip_id
					AND df.job_id = fe.job_id
				LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS ddv WITH (NOLOCK) ON ddv.id = fe.device_id
				WHERE (
						(
							@package_id IS NOT NULL
							AND fe.package_id = @package_id
							)
						OR (
							@package_id IS NULL
							AND @package_group_id IS NOT NULL
							AND fe.package_group_id = @package_group_id
							)
						OR (
							@package_id IS NULL
							AND @package_group_id IS NULL
							AND fe.package_id > 0
							)
						)
					AND (
						(
							@process_id IS NOT NULL
							AND fe.process_id = @process_id
							)
						OR (
							@process_id IS NULL
							AND fe.process_id > 0
							)
						)
					AND (
						(
							@job_id IS NOT NULL
							AND fe.job_id = @job_id
							)
						OR (
							@job_id IS NULL
							AND fe.job_id > 0
							)
						)
					AND (
						(
							@device_name IS NOT NULL
							AND ddv.name = @device_name
							)
						OR (@device_name IS NULL)
						)
					AND (
						(
							@job_id IS NULL
							AND fe.code = 2
							)
						OR (
							@job_id IS NOT NULL
							AND fe.code >= 0
							)
						)
				) AS t1 ON t1.day_id = dd.day_id
				AND t1.hour_code = dd.hour_code
			WHERE dd.day_id BETWEEN @from - 1
					AND @to + 1
			) AS t2
	END

	RETURN
END
