CREATE PROCEDURE [dbo].[myStoredProcedure]
	@pLimitRow	INT	
AS
BEGIN
	
		DECLARE @i INT
		SET @i = 1

		WHILE (@i <= @pLimitRow)
		  BEGIN 

			PRINT + ' Row : ' + CONVERT(VARCHAR,@i)
         
			SET @i = @i + 1 
		  END -- WHILE

END
