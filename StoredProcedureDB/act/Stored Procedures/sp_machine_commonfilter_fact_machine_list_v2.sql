
CREATE PROCEDURE [act].[sp_machine_commonfilter_fact_machine_list_v2] @package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@job_id INT = NULL
	,@device_name CHAR(20) = NULL
	,@date_from DATE
	,@date_to DATE
AS
BEGIN
	--DECLARE @package_group_id INT = NULL
	--DECLARE @package_id INT = 246
	--DECLARE @process_id INT = NULL
	--DECLARE @job_id INT = 106
	--DECLARE @device_name CHAR(20) = NULL
	--DECLARE @date_from DATE = '2022-12-01'
	--DECLARE @date_to DATE = '2023-01-23'
	SELECT fs.machine_model_id
		,md.name AS machine_model_name
		,COUNT(fs.lot_id) AS cnt
	FROM APCSProDWH.dwh.fact_start AS fs WITH (NOLOCK)
	INNER JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.id = fs.day_id
	INNER JOIN APCSProDWH.dwh.dim_machine_models AS md WITH (NOLOCK) ON md.id = fs.machine_model_id
	INNER JOIN apcsprodwh.dwh.dim_devices AS dv WITH (NOLOCK) ON dv.id = fs.device_id
	WHERE (
			dd.date_value BETWEEN FORMAT(@date_from, 'yyyy-MM-dd')
				AND FORMAT(@date_to, 'yyyy-MM-dd')
			)
		AND (
			(
				@package_group_id IS NOT NULL
				AND fs.package_group_id = @package_group_id
				)
			OR (
				@package_group_id IS NULL
				AND fs.package_group_id >= 0
				)
			)
		AND (
			(
				@package_id IS NULL
				AND fs.package_id > 0
				)
			OR (
				@package_id IS NOT NULL
				AND fs.package_id = @package_id
				)
			)
		AND (
			(
				@process_id IS NOT NULL
				AND fs.process_id = @process_id
				)
			OR (
				@process_id IS NULL
				AND fs.process_id >= 0
				)
			)
		AND (
			(
				@job_id IS NOT NULL
				AND fs.job_id = @job_id
				)
			OR (
				@job_id IS NULL
				AND fs.job_id > 0
				)
			)
		AND (
			(
				@device_name IS NOT NULL
				AND dv.name = @device_name
				)
			OR (@device_name IS NULL)
			)
	GROUP BY fs.machine_model_id
		,md.name
	ORDER BY machine_model_name

	SELECT fs.machine_model_id
		,md.name AS machine_model_name
		,fs.machine_id
		,dm.name AS machine_name
		,COUNT(fs.lot_id) AS cnt
	FROM APCSProDWH.dwh.fact_start AS fs WITH (NOLOCK)
	INNER JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.id = fs.day_id
	INNER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = fs.machine_id
	INNER JOIN APCSProDWH.dwh.dim_machine_models AS md WITH (NOLOCK) ON md.id = fs.machine_model_id
	INNER JOIN apcsprodwh.dwh.dim_devices AS dv WITH (NOLOCK) ON dv.id = fs.device_id
	WHERE (
			dd.date_value BETWEEN FORMAT(@date_from, 'yyyy-MM-dd')
				AND FORMAT(@date_to, 'yyyy-MM-dd')
			)
		AND (
			(
				@package_group_id IS NOT NULL
				AND fs.package_group_id = @package_group_id
				)
			OR (
				@package_group_id IS NULL
				AND fs.package_group_id >= 0
				)
			)
		AND (
			(
				@package_id IS NULL
				AND fs.package_id > 0
				)
			OR (
				@package_id IS NOT NULL
				AND fs.package_id = @package_id
				)
			)
		AND (
			(
				@process_id IS NOT NULL
				AND fs.process_id = @process_id
				)
			OR (
				@process_id IS NULL
				AND fs.process_id >= 0
				)
			)
		AND (
			(
				@job_id IS NOT NULL
				AND fs.job_id = @job_id
				)
			OR (
				@job_id IS NULL
				AND fs.job_id > 0
				)
			)
		AND (
			(
				@device_name IS NOT NULL
				AND dv.name = @device_name
				)
			OR (@device_name IS NULL)
			)
	GROUP BY fs.machine_id
		,dm.name
		,fs.machine_model_id
		,md.name
	ORDER BY machine_model_name
		,machine_name
END
