
CREATE PROCEDURE [act].[sp_home_act_v2] @date_from DATE = ''
	,@date_to DATE = ''
	,@time_offset INT = 0
AS
BEGIN
	-- date
	DECLARE @from INT
	DECLARE @to INT

	------------------------------------------------------------------------
	-- Setup date
	------------------------------------------------------------------------
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

	------------------------------------------------------------------------
	-- Select actual data
	------------------------------------------------------------------------
	SELECT t1.new_day_id AS day_id
		,COUNT(t1.lot_id) AS lot_count
		,ROUND(SUM(t1.pass_pcs), - 3) / 1000 AS sum_Kpcs
	FROM (
		SELECT fs.day_id + CASE 
				WHEN fs.hour_code > @time_offset
					THEN 0
				ELSE - 1
				END AS new_day_id
			,fs.day_id
			,fs.hour_code
			,fs.lot_id
			,fs.pass_pcs
		FROM apcsprodwh.dwh.fact_shipment AS fs WITH (NOLOCK)
		WHERE fs.day_id BETWEEN @from - 1
				AND @to
		) AS t1
	WHERE
		--t1.new_day_id IN (@from, @to)
		--◆重要◆
		--当日8時絞めデータが必要なので、一昨日と昨日のデータを引く
		t1.new_day_id IN (
			@from - 1
			,@from
			)
	GROUP BY t1.new_day_id
	ORDER BY t1.new_day_id
END
