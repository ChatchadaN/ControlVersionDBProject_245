
CREATE PROCEDURE [act].[sp_productiondetail_01] @package_group_id INT = NULL
	,@packages_id INT = NULL
	,@process_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@date_from DATE = ''
	,@date_to DATE = ''
	,@span VARCHAR(32) = N'dd'
	,@acum BIT = 0
AS
BEGIN
	DECLARE @from INT
	DECLARE @to INT

	SET @from = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_from
			);
	SET @to = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_to
			);

	SELECT t1.id AS id
		,t1.span AS span
		,t1.date_value AS date_value
		,t1.plan_Kpcs AS plan_Kpcs
		,t1.input_lot_cnt AS input_lot_cnt
		,t1.input_Kpcs AS input_Kpcs
		,t1.input_lot_cnt_7ave AS input_lot_cnt_7ave
		,t1.input_Kpcs_7ave AS input_Kpcs_7ave
		,t1.ship_lot_cnt AS ship_lot_cnt
		,t1.ship_Kpcs AS ship_Kpcs
		,t1.ship_lot_cnt_7ave AS ship_lot_cnt_7ave
		,t1.ship_Kpcs_7ave AS ship_Kpcs_7ave
		,t1.wip_days AS wip_days
		,t2.hour_code AS hour_code
		,t2.wip_all_lot_cnt + t2.on_time_lot_cnt + t2.delayed_lot_cnt AS wip_all_lot_cnt
		,t2.wip_all_Kpcs + t2.on_time_Kpcs + t2.delayed_Kpcs AS wip_all_Kpcs
		,t2.on_time_lot_cnt AS on_time_lot_cnt
		,t2.on_time_Kpcs AS on_time_Kpcs
		,t2.delayed_lot_cnt AS delayed_lot_cnt
		,t2.delayed_Kpcs AS delayed_Kpcs
		,isnull(t3.sum_normal_lot_count, 0) AS qc_normal_lot_cnt
		,isnull(convert(FLOAT, t3.sum_normal_pcs) / 1000, 0) AS qc_normal_Kpcs
		,isnull(t3.sum_abnormal_lot_count, 0) AS qc_abnormal_lot_cnt
		,isnull(convert(FLOAT, t3.sum_abnormal_pcs) / 1000, 0) AS qc_abnormal_Kpcs
	FROM [act].fnc_ProductionMain_01_daily(@package_group_id, @packages_id, @process_id, @device_id, @device_name, @from, @to, @span) AS t1
	LEFT OUTER JOIN [act].fnc_ProductionMain_02_daily(@package_group_id, @packages_id, @process_id, @device_id, @device_name, @from, @to, @span) AS t2 ON t2.id = t1.id
	LEFT OUTER JOIN act.fnc_fact_wip_qc(@package_group_id, @packages_id, @process_id, @device_id, @device_name, @from, @to, 0) AS t3 ON t3.day_id = t1.id
	ORDER BY t1.date_value;
END
