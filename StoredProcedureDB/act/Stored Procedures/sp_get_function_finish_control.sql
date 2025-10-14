
CREATE PROCEDURE [act].[sp_get_function_finish_control] (@to_fact_table VARCHAR(50) = NULL)
AS
BEGIN
	SELECT finished_at as finished_at,
	(select val FROM APCSProDWH.dwh.act_settings where name='FactoryTimeSpan') as FactoryTimeSpan
	FROM APCSProDWH.dwh.function_finish_control
	WHERE to_fact_table = @to_fact_table
END
