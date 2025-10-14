
CREATE PROCEDURE [act].[sp_machine_commonfilter_machine_list] @process_id INT = NULL
	,@job_id INT = NULL
	,@location_id INT = NULL
	,@machine_group_id INT = NULL
	,@machine_model_id INT = NULL
AS
BEGIN
	SELECT t2.*
	FROM (
		SELECT t1.*
		FROM (
			SELECT RANK() OVER (
					PARTITION BY mc.id ORDER BY mj.id
					) AS mc_rank
				,mc.id AS machine_id
				,mc.machine_model_id AS machine_model_id
				,md.name AS model_name
				,mk.name AS maker_name
				,mj.machine_group_id AS machine_group_id
				,gp.name AS group_name
				,mc.name AS machine_name
				,mc.short_name1 AS machine_short_name1
				,mc.short_name2 AS machine_short_name2
				,mj.process_id AS process_id
				,dp.name AS process_name
				,mj.id AS job_id
				,dj.name AS job_name
				,mc.location_id AS location_id
				,dl.name AS location_name
			FROM APCSProDB.mc.machines AS mc WITH (NOLOCK)
			LEFT OUTER JOIN APCSProDB.mc.models AS md WITH (NOLOCK) ON mc.machine_model_id = md.id
			LEFT OUTER JOIN APCSProDB.mc.makers AS mk WITH (NOLOCK) ON md.maker_id = mk.id
			LEFT OUTER JOIN APCSProDB.mc.group_models AS gm WITH (NOLOCK) ON md.id = gm.machine_model_id
			LEFT OUTER JOIN APCSProDB.mc.groups AS gp WITH (NOLOCK) ON gm.machine_group_id = gp.id
			LEFT OUTER JOIN APCSProDB.method.jobs AS mj WITH (NOLOCK) ON mj.machine_group_id = gm.machine_group_id
			LEFT OUTER JOIN APCSProDWH.dwh.dim_processes AS dp WITH (NOLOCK) ON dp.id = mj.process_id
			LEFT OUTER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = mj.id
			LEFT OUTER JOIN APCSProDWH.dwh.dim_locations AS dl WITH (NOLOCK) ON dl.id = mc.location_id
			WHERE (
					(
						(@job_id IS NOT NULL)
						AND (mj.id = @job_id)
						)
					OR (
						(@job_id IS NULL)
						AND (mj.id > 0)
						)
					)
			) AS t1
		WHERE (t1.mc_rank = 1)
		) AS t2
	WHERE (
			(
				(@process_id IS NOT NULL)
				AND (t2.process_id = @process_id)
				)
			OR (
				(@process_id IS NULL)
				AND (
					(t2.process_id >= 0)
					OR (t2.process_id IS NULL)
					)
				)
			)
		AND (
			(
				(@location_id IS NOT NULL)
				AND (t2.location_id = @location_id)
				)
			OR (
				(@location_id IS NULL)
				AND (
					(t2.location_id >= 0)
					OR (t2.location_id IS NULL)
					)
				)
			)
		AND (
			(
				(@machine_group_id IS NOT NULL)
				AND (t2.machine_group_id = @machine_group_id)
				)
			OR (
				(@machine_group_id IS NULL)
				AND (t2.machine_group_id > 0)
				)
			)
		AND (
			(
				(@machine_model_id IS NOT NULL)
				AND (t2.machine_model_id = @machine_model_id)
				)
			OR (
				(@machine_model_id IS NULL)
				AND (t2.machine_model_id > 0)
				)
			)
	ORDER BY machine_name
END
