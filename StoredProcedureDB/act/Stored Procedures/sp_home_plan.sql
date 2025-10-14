
CREATE PROCEDURE [act].[sp_home_plan]
	@date DATE = ''
AS
	BEGIN

	    -- date
        DECLARE @day_id INT
		DECLARE @is_back INT

        ------------------------------------------------------------------------
        -- Setup date
        ------------------------------------------------------------------------
        SET
        @day_id = (
			select 					
			da.id		
			from APCSProDWH.dwh.dim_days as da 					
			where da.date_value  = @date
        );
		SET
		@is_back = (
			select		
			case when datepart(hour,GETDATE()) > 7 then 0 else 1 end as is_back				
			from APCSProDWH.dwh.dim_days as da 					
			where da.date_value  = @date		
		);
		------------------------------------------------------------------------
        -- Select
        ------------------------------------------------------------------------
		SELECT
			fp.day_id,
			ROUND(
				SUM(fp.pcs),
				- 3
			) / 1000 AS Kpcs
		FROM
			apcsprodwh.dwh.fact_plan AS fp
		WHERE
			((@is_back = 0) and (day_id between @day_id-2 and @day_id-1))
			or ((@is_back = 1) and (day_id between @day_id-3 and @day_id-2))
		GROUP BY
			fp.day_id
		ORDER BY day_id

	END
