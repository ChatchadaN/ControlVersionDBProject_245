-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_config_path]
	-- Add the parameters for the stored procedure here
	@app_name VARCHAR(MAX)
	, @comment VARCHAR(MAX)
	, @function_name VARCHAR(MAX)
	, @is_use VARCHAR(MAX)
	, @factories VARCHAR(MAX)
	, @config_path VARCHAR(MAX)
	, @created_by INT
	, @is_disable INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		INSERT INTO [APCSProDB].[cellcon].[config_functions]
        ([app_name],[comment],[function_name],[is_use],[factory_code],[value],[created_at],[created_by],[is_disabled])
        VALUES (@app_name, @comment, @function_name, @is_use, @factories, @config_path, GETDATE(), @created_by, @is_disable)

	END
END
