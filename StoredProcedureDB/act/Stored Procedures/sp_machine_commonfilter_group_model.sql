
CREATE PROCEDURE [act].[sp_machine_commonfilter_group_model] @machine_group_id INT = NULL
	,@machine_model_id INT = NULL
AS
BEGIN
	--DECLARE @machine_group_id INT = 2
	--DECLARE @machine_model_id INT = NULL
	IF OBJECT_ID(N'tempdb..#table', N'U') IS NOT NULL
		DROP TABLE #table;

	SELECT g.id AS machine_group_id
		,g.name AS machine_group_name
		,md.id AS machine_model_id
		,md.name AS machine_model_name
		,m.id AS machine_id
		,m.name AS machine_name
		,md.name AS machine_model
	INTO #table
	FROM APCSProDB.mc.groups AS g WITH (NOLOCK)
	INNER JOIN APCSProDB.mc.group_models AS gm WITH (NOLOCK) ON gm.machine_group_id = g.id
	INNER JOIN APCSProDB.mc.models AS md WITH (NOLOCK) ON md.id = gm.machine_model_id
	INNER JOIN APCSProDB.mc.machines AS m WITH (NOLOCK) ON m.machine_model_id = md.id

	--Machine Group
	SELECT t2.machine_group_id AS id
		,t2.machine_group_name AS name
	FROM #table AS t2
	WHERE (
			(
				@machine_model_id IS NOT NULL
				AND t2.machine_model_id = @machine_model_id
				)
			OR (
				@machine_model_id IS NULL
				AND t2.machine_model_id >= 0
				)
			)
		AND (
			(
				@machine_group_id IS NOT NULL
				AND t2.machine_group_id = @machine_group_id
				)
			OR (
				@machine_group_id IS NULL
				AND t2.machine_group_id >= 0
				)
			)
	GROUP BY t2.machine_group_id
		,t2.machine_group_name
	ORDER BY t2.machine_group_name;

	--Machine Model
	SELECT t2.machine_model_id AS id
		,t2.machine_model_name AS name
	FROM #table AS t2
	WHERE (
			(
				@machine_model_id IS NOT NULL
				AND t2.machine_model_id = @machine_model_id
				)
			OR (
				@machine_model_id IS NULL
				AND t2.machine_model_id >= 0
				)
			)
		AND (
			(
				@machine_group_id IS NOT NULL
				AND t2.machine_group_id = @machine_group_id
				)
			OR (
				@machine_group_id IS NULL
				AND t2.machine_group_id >= 0
				)
			)
	GROUP BY t2.machine_model_id
		,t2.machine_model_name
	ORDER BY t2.machine_model_name;

	--Machine 
	IF @machine_group_id IS NOT NULL
		OR @machine_model_id IS NOT NULL
	BEGIN
		SELECT t2.machine_id AS id
			,t2.machine_name AS name
		FROM #table AS t2
		WHERE (
				(
					@machine_model_id IS NOT NULL
					AND t2.machine_model_id = @machine_model_id
					)
				OR (
					@machine_model_id IS NULL
					AND t2.machine_model_id >= 0
					)
				)
			AND (
				(
					@machine_group_id IS NOT NULL
					AND t2.machine_group_id = @machine_group_id
					)
				OR (
					@machine_group_id IS NULL
					AND t2.machine_group_id >= 0
					)
				)
		ORDER BY t2.machine_name
	END
	ELSE
	BEGIN
		SELECT NULL AS id
			,NULL AS name
	END
END
