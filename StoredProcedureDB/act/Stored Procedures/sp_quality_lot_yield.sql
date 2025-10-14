
CREATE PROCEDURE [act].[sp_quality_lot_yield] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@job_id INT = NULL
	,@device_id INT = NULL
	,@date_from DATE = '2020-08-01'
	,@date_to DATE = '2020-08-10'
	)
AS
BEGIN
	----- only use for TEST
	DECLARE @from INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = @date_from
			)
	DECLARE @to INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = @date_to
			)

	--SELECT 12345 as lot_id
	--,'1925E0005F' as lot_no
	--,200 as RANK_1
	--,5100 as RANK_2
	--,33003 as RANK_3
	--,33004 as RANK_4
	--,33005 as RANK_5
	--,33006 as RANK_6
	--,33007 as RANK_7
	--,33008 as RANK_8
	--,33009 as RANK_9
	--,99999 as RANK_others
	SELECT x1.id AS lot_id
		,x1.lot_no AS lot_no
		,x2.RANK_1 + x1.qty_in AS RANK_1
		,x2.RANK_2 + x1.qty_in AS RANK_2
		,x2.RANK_3 + x1.qty_in AS RANK_3
		,x2.RANK_4 + x1.qty_in AS RANK_4
		,x2.RANK_5 + x1.qty_in AS RANK_5
		,x2.RANK_6 + x1.qty_in AS RANK_6
		,x2.RANK_7 + x1.qty_in AS RANK_7
		,x2.RANK_8 + x1.qty_in AS RANK_8
		,x2.RANK_9 + x1.qty_in AS RANK_9
		,x2.RANK_others + x1.qty_in AS RANK_OTHERS
	FROM (
		SELECT tl.id
			,tl.lot_no
			,tl.qty_in
		FROM APCSProDB.trans.lots AS tl WITH (NOLOCK)
		WHERE id IN (
				352734
				,352735
				,352736
				,352737
				,352738
				,352739
				)
		) AS x1
	CROSS JOIN (
		SELECT 200 AS RANK_1
			,5100 AS RANK_2
			,33003 AS RANK_3
			,33004 AS RANK_4
			,33005 AS RANK_5
			,33006 AS RANK_6
			,33007 AS RANK_7
			,33008 AS RANK_8
			,33009 AS RANK_9
			,99999 AS RANK_others
		) AS x2
END
