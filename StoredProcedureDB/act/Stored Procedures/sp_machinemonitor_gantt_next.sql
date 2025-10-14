
CREATE PROCEDURE [act].[sp_machinemonitor_gantt_next] (
	@package_id INT = NULL,
	@process_id INT = NULL,
	@job_id INT = NULL,
	@from_at DATE,
	@to_at DATE,
	@list NVARCHAR(max) = NULL
	)
AS
BEGIN
	--DECLARE @from_at DATE = '2019-01-12'
	--DECLARE @to_at DATE = '2019-01-14'
	--DECLARE @package_id INT = 242
	--DECLARE @process_id INT = NULL
	--DECLARE @job_id INT = 119
	----declare @list nvarchar(max) = '13'
	--declare @list nvarchar(max) = null

SELECT t1.*
FROM (
	SELECT pj.id AS id,
		ROW_NUMBER() OVER (
			PARTITION BY pj.machine_id ORDER BY datediff(second, @from_at, started_at)
			) AS num,
		pj.machine_id AS machine_id,
		dm.name AS machine_name,
		pj.setup_at AS setup_at,
		pj.started_at AS started_at,
		pj.finished_at AS finished_at,
		pl.lot_id AS lot_id,
		l.lot_no AS lot_no,
		l.production_category AS production_category,
		il.label_eng AS production_category_val,
		datediff(second, @from_at, started_at) AS start_diff_sec,
		datediff(second, @from_at, finished_at) AS finish_diff_sec
	FROM APCSProDWH.dwh.view_fact_pjs AS pj WITH (NOLOCK)
	INNER JOIN APCSProDWH.dwh.view_fact_pj_lots AS pl WITH (NOLOCK) ON pl.pj_id = pj.id
	INNER JOIN APCSProDWH.dwh.dim_lots AS l WITH (NOLOCK) ON l.id = pl.lot_id
	LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = pj.machine_id
	LEFT OUTER JOIN APCSProDWH.dwh.item_labels AS il WITH (NOLOCK) ON il.name = 'fact_wip.production_category'
		AND il.val = l.production_category
	WHERE pj.machine_id IN (
			SELECT machine_id
			FROM APCSProDWH.dwh.fact_end AS e WITH (NOLOCK)
			INNER JOIN APCSProDWH.dwh.dim_jobs AS j WITH (NOLOCK) ON j.id = e.job_id
			INNER JOIN APCSProDWH.dwh.dim_days AS dy WITH (NOLOCK) ON dy.id = e.day_id
			WHERE dy.date_value BETWEEN @from_at
					AND @to_at
				AND (
					(
						@package_id IS NOT NULL
						AND e.package_id = @package_id
						)
					OR (
						@package_id IS NULL
						AND e.package_id > 0
						)
					)
				AND (
					(
						@process_id IS NOT NULL
						AND e.process_id = @process_id
						)
					OR (
						@process_id IS NULL
						AND e.process_id >= 0
						)
					)
				AND (
					(
						@job_id IS NOT NULL
						AND e.job_id = @job_id
						)
					OR (
						@job_id IS NULL
						AND e.job_id > 0
						)
					)
				AND (
					(
						((@list IS NOT NULL) or (@list <> ''))
						AND (',' + @list + ',' LIKE '%,' + cast(e.machine_id AS VARCHAR) + ',%')
						)
					OR ((@list IS NULL)or(@list = ''))
					)
			GROUP BY machine_id
			)
		AND (
			(
				pj.started_at BETWEEN @from_at
					AND @to_at
				)
			OR (
				pj.finished_at BETWEEN @from_at
					AND @to_at
				)
			)
	) AS t1
ORDER BY t1.machine_id,
	t1.num;

	--machine list
	SELECT fe.machine_id as machine_id,
	isnull(dm.name,'machine name') as machine_name
	FROM APCSProDWH.dwh.fact_end AS fe
	--LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = fe.machine_id
	left outer join APCSProDB.mc.machines as dm with (nolock) on dm.id = fe.machine_id
	WHERE (
			(
				@package_id IS NOT NULL
				AND fe.package_id = @package_id
				)
			OR (
				@package_id IS NULL
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
				AND fe.process_id >= 0
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
	GROUP BY fe.machine_id,dm.name
	HAVING fe.machine_id > 0
	order by fe.machine_id;



END
