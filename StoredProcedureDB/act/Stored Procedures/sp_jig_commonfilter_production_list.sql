
CREATE PROCEDURE [act].[sp_jig_commonfilter_production_list] @process_id INT = NULL
	,@category_id INT = NULL
AS
BEGIN
	--DECLARE @process_id INT = 3
	--DECLARE @category_id INT = NULL
	----check column 
	DECLARE @return_value INT = 0

	EXEC @return_value = StoredProcedureDB.act.sp_check_column_exist @schema = N'jig'
		,@table = N'categories'
		,@column = N'lsi_process_id'

	----process
	IF (@return_value = 1)
	BEGIN
		SELECT jc.lsi_process_id AS process_id
			,mp.name AS process_name
		FROM APCSProDB.jig.categories AS jc WITH (NOLOCK)
		LEFT JOIN apcsprodb.method.processes AS mp WITH (NOLOCK) ON mp.id = jc.lsi_process_id
		WHERE (
				(
					@category_id IS NOT NULL
					AND jc.id = @category_id
					)
				OR (
					@category_id IS NULL
					AND jc.id > 0
					)
				)
		GROUP BY jc.lsi_process_id
			,mp.name
		ORDER BY jc.lsi_process_id
	END
	ELSE
	BEGIN
		SELECT TOP 0 NULL AS process_id
			,NULL AS process_name
	END

	----jig_category
	IF (@return_value = 1)
	BEGIN
		SELECT jc.id AS category_id
			,CASE 
				WHEN mp.name IS NOT NULL
					THEN jc.name + ' (' + mp.name + ')'
				ELSE jc.name
				END AS category_name
		FROM APCSProDB.jig.categories AS jc WITH (NOLOCK)
		LEFT JOIN APCSProDB.method.processes AS mp WITH (NOLOCK) ON mp.id = jc.lsi_process_id
		WHERE (
				(
					@process_id IS NOT NULL
					AND jc.lsi_process_id = @process_id
					)
				OR (
					@process_id IS NULL
					AND jc.lsi_process_id > 0
					)
				)
		ORDER BY category_name
	END
	ELSE
	BEGIN
		SELECT jc.id AS category_id
			,jc.name AS category_name
		FROM APCSProDB.jig.categories AS jc WITH (NOLOCK)
		ORDER BY category_name
	END

	----jig_production
	IF (@return_value = 1)
	BEGIN
		IF @process_id IS NOT NULL
			OR @category_id IS NOT NULL
		BEGIN
			SELECT jp.id AS production_id
				,jp.name AS production_name
				,jp.category_id
				,jc.name AS category_name
				,jc.lsi_process_id
				,mp.name AS process_name
			FROM APCSProDB.jig.productions AS jp WITH (NOLOCK)
			LEFT JOIN APCSProDB.jig.categories AS jc WITH (NOLOCK) ON jc.id = jp.category_id
			LEFT JOIN APCSProDB.method.processes AS mp WITH (NOLOCK) ON mp.id = jc.lsi_process_id
			WHERE (
					(
						@process_id IS NOT NULL
						AND jc.lsi_process_id = @process_id
						)
					OR (
						@process_id IS NULL
						AND jc.lsi_process_id > 0
						)
					)
				AND (
					(
						@category_id IS NOT NULL
						AND jp.category_id = @category_id
						)
					OR (
						@category_id IS NULL
						AND jp.category_id > 0
						)
					)
			ORDER BY jc.name
				,jp.name
		END
	END
	ELSE
	BEGIN
		IF @process_id IS NOT NULL
			OR @category_id IS NOT NULL
		BEGIN
			SELECT jp.id AS production_id
				,jp.name AS production_name
				,jp.category_id
				,jc.name AS category_name
			FROM APCSProDB.jig.productions AS jp WITH (NOLOCK)
			LEFT JOIN APCSProDB.jig.categories AS jc WITH (NOLOCK) ON jc.id = jp.category_id
			WHERE (
					(
						@category_id IS NOT NULL
						AND jp.category_id = @category_id
						)
					OR (
						@category_id IS NULL
						AND jp.category_id > 0
						)
					)
			ORDER BY jc.name
				,jp.name
		END
	END
END
