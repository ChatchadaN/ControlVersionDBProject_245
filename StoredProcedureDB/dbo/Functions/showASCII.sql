
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[showASCII](@string NVARCHAR(max))
returns nvarchar(max)
AS
BEGIN
   DECLARE @length smallint = LEN(@string)
   DECLARE @position smallint = 0
   DECLARE @codes varchar(max) = ''
 
   WHILE (@length >= @position)
   BEGIN
	  IF(UNICODE(SUBSTRING(@string,@position,1))>50000)
	  BEGIN
		SELECT @codes = @codes + CONCAT(UNICODE(SUBSTRING(@string,@position,1)),',')
	  END
      SELECT @position = @position + 1
   END
 
   --SELECT @codes = SUBSTRING(@codes,2,LEN(@codes)-2)
   SET @codes = CASE WHEN @codes = '' THEN '0' ELSE SUBSTRING(@codes, 1, LEN(@codes)-1) END
   RETURN @codes
END
