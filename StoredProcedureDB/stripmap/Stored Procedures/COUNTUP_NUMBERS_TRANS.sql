-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[COUNTUP_NUMBERS_TRANS]
	-- Add the parameters for the stored procedure here
	@ID_NAME  varchar(30),
	@UP_NUM   INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @CURRENT_NUM INT

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select @CURRENT_NUM = NU.id
	from APCSProDB.trans.numbers as NU
    where NU.name = @ID_NAME

	IF @CURRENT_NUM is NULL
		BEGIN
			insert APCSProDB.trans.numbers(id, name) select @UP_NUM, @ID_NAME
			SET @CURRENT_NUM = @UP_NUM
		END
	ELSE
		BEGIN
			update NU SET
				NU.id = NU.id + @UP_NUM
			from APCSProDB.trans.numbers as NU
			where NU.name = @ID_NAME
			SET @CURRENT_NUM = @CURRENT_NUM + @UP_NUM
		END

	select @CURRENT_NUM as CURRENT_NUM
	return @@ROWCOUNT
END
