-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_error_alarm]
	-- Add the parameters for the stored procedure here
	@app_name VARCHAR(50) = ''	
	,@code int = 0
	,@language VARCHAR(50) = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET @app_name = CASE WHEN @app_name = '' THEN NULL ELSE @app_name  END 
	SET @code = CASE WHEN @code = 0 THEN NULL ELSE @code  END 
	SET @language = CASE WHEN @language = '' THEN NULL ELSE @language  END 

    -- Insert statements for procedure here
	BEGIN
		SELECT [app_name]
			,[code]
			,[lang]
			,[message]
			,[cause]
			,[handling]
			,[information_code]
			,[importance]
			,[comment]
			,[created_at]
		FROM [APCSProDB].[mdm].[errors]
		WHERE ([errors].app_name =  @app_name OR @app_name IS NULL)
			AND ([errors].[code] =  @code OR @code IS NULL)
			AND ([errors].[lang] =  @language OR @language IS NULL)
	END
END
