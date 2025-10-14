

create FUNCTION [act].[fnc_test_lastmcstate_old] (
	@machine_id INT = NULL,
	@reference_date datetime = NULL
	)
RETURNS @retTbl TABLE (
	machine_id INT NOT NULL,
	current_run_state TINYINT,
	pre_id INT,
	pre_run_state TINYINT,
	pre_update_at datetime
	)

BEGIN
	INSERT INTO @retTbl
	select top 1
		s.machine_id
		,s.run_state as current_run_state
		,r_pre.id as pre_id
		,r_pre.run_state as pre_run_state
		,r_pre.updated_at as pre_update_at
	from APCSProDB.trans.machine_states as s with (NOLOCK)
		left outer join apcsprodb.trans.lot_pjs as lp with (NOLOCK) 
			on lp.machine_id = s.machine_id 
				and lp.started_at < @reference_date 
				and not exists (select * from apcsprodb.trans.lot_pjs as lp2 with (NOLOCK) where lp2.machine_id = lp.machine_id and lp2.started_at < @reference_date and lp2.process_job_id > lp.process_job_id) 
		left outer join APCSProDB.trans.machine_state_records as r_pre with (NOLOCK)
			on r_pre.machine_id = s.machine_id 
				and r_pre.updated_at < lp.started_at
	where s.machine_id in(@machine_id)
	order by r_pre.id desc

	RETURN
END
