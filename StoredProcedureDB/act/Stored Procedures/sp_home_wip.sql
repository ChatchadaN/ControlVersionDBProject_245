
CREATE PROCEDURE [act].[sp_home_wip]
	@date_from DATE = '',
	@date_to DATE = '',
	@hour_now INT 
AS
	BEGIN

		-- date
        DECLARE @from INT
        DECLARE @to INT
        DECLARE @hour INT

        ------------------------------------------------------------------------
        -- Setup date
        ------------------------------------------------------------------------
        SET
        @from = (
            SELECT
                id
            FROM
                apcsprodwh.dwh.dim_days
            WHERE
                date_value = @date_from
        );

        SET
        @to = (
            SELECT
                id
            FROM
                apcsprodwh.dwh.dim_days
            WHERE
                date_value = @date_to
        );

        SET
        @hour = (
            SELECT
                code
            FROM
                apcsprodwh.dwh.dim_hours
            WHERE
				h = @hour_now
        );


		------------------------------------------------------------------------
        -- Select
        ------------------------------------------------------------------------
		SELECT
			t2.day_id,
			t2.hour_code,
			--t2.lot_count_sum,				
			--t2.pcs_sum,				
			t2.delay_state_code,
			t2.total_lot_count,
			ROUND(
				t2.total_pcs,
				- 3
			) / 1000 AS total_kpcs,
			CASE
				WHEN t2.total_lot_count > 0 THEN ROUND(
					CONVERT(FLOAT, t2.pcs_sum * 100) / t2.total_pcs,
					1
				)
				ELSE 0
			END AS delay_rate_pcs,
			CASE
				WHEN t2.total_lot_count > 0 THEN ROUND(
					CONVERT(FLOAT, t2.lot_count_sum) * 100 / t2.total_lot_count,
					1
				)
				ELSE 0
			END AS delay_rate_lot_count
		FROM
			(
				SELECT
					t1.*,
					SUM(t1.lot_count_sum) OVER (PARTITION BY t1.day_id, t1.hour_code) AS total_lot_count,
					SUM(t1.pcs_sum) OVER (PARTITION BY t1.day_id, t1.hour_code) AS total_pcs
				FROM
					(
						SELECT
							day_id,
							hour_code,
							SUM(lot_count) AS lot_count_sum,
							SUM(pcs) AS pcs_sum,
							delay_state_code
						FROM
							apcsprodwh.dwh.fact_wip AS wi WITH(NOLOCK)
						WHERE
							--wi.day_id IN(@to, @from)
							(wi.day_id between @from and @to)
						AND wi.hour_code = @hour
						GROUP BY
							day_id,
							hour_code,
							delay_state_code
					) AS t1
			) AS t2
		WHERE
			t2.delay_state_code = 10
		ORDER BY
			t2.delay_state_code,
			t2.day_id ASC

	END
