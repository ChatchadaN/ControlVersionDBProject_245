
CREATE PROCEDURE [act].[sp_home_hasuu_next] @date_from DATE = ''
	,@date_to DATE = ''
	--@hour_now INT 
AS
BEGIN
	-- date
	DECLARE @from INT
	DECLARE @to INT
	DECLARE @hour INT

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
	SET @hour = (
			SELECT code
			FROM APCSProDWH.dwh.dim_hours WITH (NOLOCK)
			WHERE
				--h = @hour_now
				h = (
					SELECT convert(INT, val) + DATEPART(hh, GETUTCDATE())
					FROM APCSProDWH.dwh.act_settings WITH (NOLOCK)
					WHERE name = 'FactoryTimeSpan'
					)
			);

	------------------------------------------------------------------------
	-- Select hasuu data
	------------------------------------------------------------------------
	SELECT t2.*
		,CASE 
			WHEN t2.total_device_count > 0
				THEN ROUND(CONVERT(FLOAT, t2.cnt) * 100 / t2.total_device_count, 1)
			ELSE 0
			END AS hasuu_rate
	FROM (
		SELECT t1.*
			,SUM(t1.cnt) OVER (
				PARTITION BY t1.day_id
				,t1.hour_code
				) AS total_device_count
		FROM (
			SELECT ha.day_id
				,ha.hour_code
				,COUNT(ha.device_id) AS cnt
				,CASE 
					WHEN ha.pcs > ha.pcs_per_pack
						THEN 1
					ELSE 0
					END AS flg
			FROM apcsprodwh.dwh.fact_hasuu AS ha WITH (NOLOCK)
			WHERE ha.day_id IN (
					@to
					,@from
					)
				AND hour_code = @hour
			GROUP BY ha.day_id
				,ha.hour_code
				,CASE 
					WHEN ha.pcs > ha.pcs_per_pack
						THEN 1
					ELSE 0
					END
			) AS t1
		) AS t2
	WHERE t2.flg = 1
	ORDER BY day_id
END
