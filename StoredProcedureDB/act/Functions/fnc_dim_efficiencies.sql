
CREATE FUNCTION [act].[fnc_dim_efficiencies] ()
RETURNS @retTbl TABLE (
	code TINYINT
	,class_code TINYINT NULL
	,sub_class_code VARCHAR(3) NULL
	,run_state TINYINT NULL
	,name NVARCHAR(30)
	,disp_order TINYINT
	)

BEGIN
	INSERT INTO @retTbl
	SELECT de.code
		,de.class_code
		,de.sub_class_code
		,de.run_state
		,il.label_eng
		,ROW_NUMBER() OVER (
			ORDER BY class_code
				,de.name
			) AS disp_order
	FROM APCSProDWH.dwh.dim_efficiencies AS de WITH (NOLOCK)
	LEFT OUTER JOIN APCSProDB.trans.item_labels AS il WITH (NOLOCK) ON il.name = 'machine_states.run_state'
		AND il.val = de.run_state
	
	UNION ALL
	
	--2020-06-03
	SELECT DISTINCT 99 AS code
		,NULL AS class_code
		,NULL AS sub_class_code
		,99 AS run_state
		,'Alarm' AS name
		,99 AS disp_order
	
	UNION ALL
	
	SELECT DISTINCT 199 AS code
		,NULL AS class_code
		,NULL AS sub_class_code
		,199 AS run_state
		,'LotEnd' AS name
		,199 AS disp_order
	
	UNION ALL
	
	SELECT DISTINCT 255 AS code
		,NULL AS class_code
		,NULL AS sub_class_code
		,255 AS run_state
		,'Others' AS name
		,255 AS disp_order

	RETURN
END
