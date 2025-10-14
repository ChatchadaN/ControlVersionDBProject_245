
CREATE PROCEDURE [act].[sp_productionipi_input_control] (
	@package_id INT = NULL,
	@product_group_id INT = NULL,
	@device_id INT = NULL
	)
AS
BEGIN
	-- 経過日数判定値
	DECLARE @span INT = (
			SELECT val
			FROM APCSProDWH.dwh.act_settings
			--デバッグ用カラム使用
			WHERE name = 'ThresholdOfLongTimeStay'
			)

	SELECT *
	INTO #t
	FROM [act].fnc_productionipi_monitoring_items(@package_id, @product_group_id, @device_id);


	SELECT 1 AS No,
		1 AS new_no,
		N'オーバー' AS name,
		N'Over UCL' AS name_en,
		isnull(sum(CASE 
					WHEN il.is_input_control = 1
						THEN CASE 
								WHEN il.is_alarmed = 1
									THEN 1
								ELSE 0
								END
					ELSE 0
					END), 0) AS in_cnt,
		isnull(sum(CASE 
					WHEN isnull(il.is_input_control, 0) <> 1
						THEN CASE 
								WHEN il.is_alarmed = 1
									THEN 1
								ELSE 0
								END
					ELSE 0
					END), 0) AS process_cnt
	FROM #t AS il WITH (NOLOCK)
	
	UNION ALL
	
	SELECT 2 AS No,
		3 AS new_no,
		N'警告中' AS name,
		N'Alarm' AS name_en,
		isnull(sum(CASE 
					WHEN il.is_input_control = 1
						THEN CASE 
								WHEN il.is_alarmed = 10
									THEN 1
								ELSE 0
								END
					ELSE 0
					END), 0) AS in_cnt,
		isnull(sum(CASE 
					WHEN isnull(il.is_input_control, 0) <> 1
						THEN CASE 
								WHEN il.is_alarmed = 10
									THEN 1
								ELSE 0
								END
					ELSE 0
					END), 0) AS process_cnt
	FROM #t AS il WITH (NOLOCK)
	
	UNION ALL
	
	SELECT 3 AS No,
		5 AS new_no,
		N'直近1日オーバー' AS name,
		N'Over UCL the last day' AS name_en,
		isnull(sum(CASE 
					WHEN il.is_input_control = 1
						THEN CASE 
								WHEN dateadd(day, @span, il.occurred_at) >= getdate()
									THEN 1
								ELSE 0
								END
					ELSE 0
					END), 0) AS in_cnt,
		isnull(sum(CASE 
					WHEN isnull(il.is_input_control, 0) <> 1
						THEN CASE 
								WHEN dateadd(day, @span, il.occurred_at) >= getdate()
									THEN 1
								ELSE 0
								END
					ELSE 0
					END), 0) AS process_cnt
	FROM #t AS il WITH (NOLOCK)
	
	UNION ALL
	
	SELECT 4 AS No,
		6 AS new_no,
		N'直近1日解除' AS name,
		N'Reset the last day' AS name_en,
		isnull(sum(CASE 
					WHEN il.is_input_control = 1
						THEN CASE 
								WHEN dateadd(day, @span, il.cleared_at) >= getdate()
									THEN 1
								ELSE 0
								END
					ELSE 0
					END), 0) AS in_cnt,
		isnull(sum(CASE 
					WHEN isnull(il.is_input_control, 0) <> 1
						THEN CASE 
								WHEN dateadd(day, @span, il.cleared_at) >= getdate()
									THEN 1
								ELSE 0
								END
					ELSE 0
					END), 0) AS process_cnt
	FROM #t AS il WITH (NOLOCK)
	
	UNION ALL
	
	SELECT 5 AS No,
		7 AS new_no,
		N'管理対象' AS name,
		N'Monitoring Items' AS name_en,
		isnull(sum(CASE 
					WHEN il.is_input_control = 1
						THEN 1
					ELSE 0
					END), 0) AS in_cnt,
		isnull(sum(CASE 
					WHEN isnull(il.is_input_control, 0) <> 1
						THEN 1
					ELSE 0
					END), 0) AS process_cnt
	FROM #t AS il WITH (NOLOCK)
	
	UNION ALL
	
	SELECT 11 AS No,
		2 AS new_no,
		N'一部オーバー' AS name,
		N'Partially Over UCL' AS name_en,
		isnull(sum(CASE 
					WHEN il.is_input_control = 1
						THEN CASE 
								WHEN il.is_alarmed = 2
									THEN 1
								ELSE 0
								END
					ELSE 0
					END), 0) AS in_cnt,
		isnull(sum(CASE 
					WHEN isnull(il.is_input_control, 0) <> 1
						THEN CASE 
								WHEN il.is_alarmed = 2
									THEN 1
								ELSE 0
								END
					ELSE 0
					END), 0) AS process_cnt
	FROM #t AS il WITH (NOLOCK)
	
	UNION ALL
	
	SELECT 12 AS No,
		4 AS new_no,
		N'下限アラーム' AS name,
		N'LCL' AS name_en,
		isnull(sum(CASE 
					WHEN il.is_input_control = 1
						THEN CASE 
								WHEN il.is_alarmed = 3
									THEN 0
								ELSE 0
								END
					ELSE 0
					END), 0) AS in_cnt,
		isnull(sum(CASE 
					WHEN isnull(il.is_input_control, 0) <> 1
						THEN CASE 
								WHEN il.is_alarmed = 3
									THEN 0
								ELSE 0
								END
					ELSE 0
					END), 0) AS process_cnt
	FROM #t AS il WITH (NOLOCK)
	ORDER BY new_no
END
