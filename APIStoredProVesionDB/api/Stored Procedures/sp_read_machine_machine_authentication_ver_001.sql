-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_machine_machine_authentication_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@machine_no varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [users].[id]
	FROM [APCSProDB].[man].[users]
	INNER JOIN [APCSProDB].[ctrlic].[user_lic] ON [user_lic].[user_id] = [users].[id]
	INNER JOIN [APCSProDB].[ctrlic].[license] ON [license].[lic_id] = [user_lic].[lic_id]
	INNER JOIN [APCSProDB].[ctrlic].[model_lic] ON [model_lic].[lic_id] = [license].[lic_id]
	INNER JOIN [APCSProDB].[mc].[models] ON [models].[id] = [model_lic].[model_ref_id]
	INNER JOIN [APCSProDB].[mc].[machines] ON [machines].[machine_model_id] = [models].[id]
	WHERE [users].[emp_num] = @username
	AND [machines].[name] = @machine_no
	AND [user_lic].[start_date] <= GETDATE()
	AND [user_lic].[stop_date] >= GETDATE()
	AND [user_lic].[is_active] = 1
	)
	BEGIN
		SELECT CAST(1 AS BIT) as [status]
	END
	ELSE
	BEGIN
		SELECT CAST(0 AS BIT) as [status]
	END
END
