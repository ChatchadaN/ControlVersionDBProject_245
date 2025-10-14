-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_man_user_authentication_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@password varchar(50) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [users].[id]
	FROM [APCSProDB].[man].[users]
	WHERE [users].[emp_num] = @username
	AND [users].[password] = @password
	)
	BEGIN
		SELECT CAST(1 AS BIT) as [status]
	END
	ELSE
	BEGIN
		SELECT CAST(0 AS BIT) as [status]
	END
END
