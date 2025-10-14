
CREATE FUNCTION [act].[fnc_test_lastmcstate] (
	@machine_id INT = NULL
	,@reference_date DATETIME = NULL
	)
RETURNS @retTbl TABLE (
	machine_id INT NOT NULL
	,current_run_state TINYINT
	,pre_id INT
	,pre_run_state TINYINT
	,pre_update_at DATETIME
	)

BEGIN
	INSERT INTO @retTbl
	SELECT TOP 1 t1.machine_id
		,t1.current_run_state
		,r_pre.id AS pre_id
		,r_pre.run_state AS pre_run_state
		,r_pre.updated_at AS pre_update_at
	FROM (
		SELECT TOP 1 s.machine_id
			,s.run_state AS current_run_state
			,lp.started_at
		FROM APCSProDB.trans.machine_states AS s WITH (NOLOCK)
		LEFT OUTER JOIN apcsprodb.trans.lot_pjs AS lp WITH (NOLOCK) ON lp.machine_id = s.machine_id
			AND lp.started_at < @reference_date
		WHERE s.machine_id IN (@machine_id)
		ORDER BY lp.process_job_id DESC
		) AS t1
	LEFT OUTER JOIN APCSProDB.trans.machine_state_records AS r_pre WITH (NOLOCK) ON r_pre.machine_id = t1.machine_id
		AND r_pre.updated_at < t1.started_at
	ORDER BY r_pre.id DESC

	RETURN
END
