
CREATE FUNCTION [act].[fnc_fact_wip_delay_united_v2_NotUse] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@from INT
	,@to INT
	,@hour_flag BIT
	,@time_offset INT = 0
	)
RETURNS @retTbl TABLE (
	day_id INT NOT NULL
	,hour_code TINYINT
	,delay_state_code INT NOT NULL
	,sum_lot_count INT NOT NULL
	,sum_pcs BIGINT NOT NULL
	)

BEGIN
	--------------------------------------------------------------------------
	--IF @process_id IS NOT NULL
	--BEGIN
	--	INSERT INTO @retTbl
	--	SELECT t.day_id AS day_id
	--		,t.hour_code AS hour_code
	--		,t.delay_state_code AS delay_state_code
	--		,t.sum_lot_count AS sum_lot_count
	--		,t.sum_pcs AS sum_pcs
	--	FROM act.fnc_fact_wip_delay_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @hour_flag, @time_offset) AS t
	--END
	--------------------------------------------------------------------------
	--IF @process_id IS NULL
	--BEGIN
	--	IF @hour_flag = 0
	--	BEGIN
	--		INSERT INTO @retTbl
	--		SELECT t.day_id AS day_id
	--			,max(t.hour_code) AS hour_code
	--			,t.delay_state_code AS delay_state_code
	--			,sum(t.sum_lot_count) AS sum_lot_count
	--			,sum(t.sum_pcs) AS sum_pcs
	--		FROM act.fnc_fact_wip_delay_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @hour_flag, @time_offset) AS t
	--		GROUP BY t.day_id
	--			,t.delay_state_code
	--	END
	--	IF @hour_flag = 1
	--		--hour
	--	BEGIN
	--		INSERT INTO @retTbl
	--		SELECT t.day_id AS day_id
	--			,t.hour_code AS hour_code
	--			,t.delay_state_code AS delay_state_code
	--			,sum(t.sum_lot_count) AS sum_lot_count
	--			,sum(t.sum_pcs) AS sum_pcs
	--		FROM act.fnc_fact_wip_delay_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @hour_flag, @time_offset) AS t
	--		GROUP BY t.day_id
	--			,t.hour_code
	--			,t.delay_state_code
	--	END
	--END
	INSERT INTO @retTbl
	SELECT t.day_id AS day_id
		,t.hour_code AS hour_code
		,t.delay_state_code AS delay_state_code
		,t.sum_lot_count AS sum_lot_count
		,t.sum_pcs AS sum_pcs
	FROM act.fnc_fact_wip_delay_v2(@package_group_id, @package_id, @process_id, @device_id, @device_name, @from, @to, @hour_flag, @time_offset) AS t

	RETURN
END
