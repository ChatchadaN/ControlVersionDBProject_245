
CREATE PROCEDURE [act].[sp_check_column_exist] (
	@schema VARCHAR(50)
	,@table VARCHAR(50)
	,@column VARCHAR(50)
	)
AS
BEGIN
	IF EXISTS (
			SELECT *
			FROM APCSProDB.sys.objects AS t
			INNER JOIN APCSProDB.sys.columns AS c ON t.object_id = c.object_id
			INNER JOIN APCSProDB.sys.schemas AS s ON s.schema_id = t.schema_id
			WHERE s.name = @schema
				AND t.name = @table
				AND c.name = @column
			)
		RETURN 1
	ELSE
		RETURN 0
END
