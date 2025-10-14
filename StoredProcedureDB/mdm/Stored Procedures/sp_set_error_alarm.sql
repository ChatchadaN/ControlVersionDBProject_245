-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_error_alarm]
	-- Add the parameters for the stored procedure here
	@app_name VARCHAR(MAX)
	, @code INT
	, @language NVARCHAR(MAX)
	, @message NVARCHAR(MAX)
	, @cause NVARCHAR(MAX)
	, @handling NVARCHAR(MAX)
	, @information_code VARCHAR(MAX)
	, @comment NVARCHAR(MAX)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		INSERT INTO [APCSProDB].[mdm].[errors]
       ([app_name],[code],[lang],[message],[cause],[handling],[information_code],[comment],[created_at])
       VALUES(@app_name, @code, @language, @message, @cause, @handling, @information_code, @comment,GETDATE())
	END
END
