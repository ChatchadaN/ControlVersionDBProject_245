


CREATE FUNCTION  [man].[fnc_get_locations_id](
	@name NVARCHAR(100)
	, @address NVARCHAR(100)
	 
)
 RETURNS     @table_locations table (
		[locations_id]   INT
		)
 
BEGIN 

		INSERT INTO @table_locations  

		SELECT id  FROM [10.29.1.230].[DWH].trans.locations
			WHERE locations.[name] = @name
			AND locations.[address] =  @address
 
 return
END;
