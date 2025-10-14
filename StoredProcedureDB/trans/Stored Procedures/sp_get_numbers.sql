-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_numbers] 
	-- Add the parameters for the stored procedure here
	@countup_column	varchar(50) = N''  
AS
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF @countup_column != N''
		SELECT NUM.id
		FROM [APCSProDB].trans.numbers as NUM
		WHERE NUM.name = @countup_column
	ELSE RETURN -1
