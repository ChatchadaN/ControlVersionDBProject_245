-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_andon_read_user_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(max)
	,	@is_gl bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [users].[id]
	FROM [APCSProDB].[man].[users]
	WHERE [users].[emp_num] = @username)
	BEGIN
		SELECT CAST(1 AS BIT) AS [status]
	END
	ELSE
	BEGIN
		SELECT CAST(0 AS BIT) AS [status]
	END
END
