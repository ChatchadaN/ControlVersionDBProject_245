-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[removeASCIILogo]
(
	-- Add the parameters for the function here
	@string NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @length smallint = LEN(@string)
	DECLARE @position smallint = 0
	DECLARE @codes varchar(MAX) = ''
 
	WHILE (@length >= @position)
	BEGIN
		IF(UNICODE(SUBSTRING(@string,@position,1))<50000)
		BEGIN
			SELECT @codes = @codes + SUBSTRING(@string,@position,1)
		END
	SELECT @position = @position + 1
	END
 
	SET @codes = CASE WHEN @codes = '' THEN '' ELSE REPLACE(REPLACE(@codes,'?',''),'*','') END
	RETURN @codes

END
