-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_trc_read_machine_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@process_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [machines].[id]
	FROM [APCSProDB].[mc].[machines]
	INNER JOIN [APCSProDB].[mc].[models] ON [models].[id] = [machines].[machine_model_id]
	INNER JOIN [APCSProDB].[mc].[group_models] ON [group_models].[machine_model_id] = [models].[id]
	INNER JOIN [APCSProDB].[mc].[groups] ON [groups].[id] = [group_models].[machine_group_id]
	INNER JOIN [APCSProDB].[method].[jobs] ON [jobs].[machine_group_id] = [groups].[id]
	INNER JOIN [APCSProDB].[method].[processes] ON [processes].[id] = [jobs].[process_id]
	WHERE [processes].[id] = @process_id)
	BEGIN
		SELECT CAST(1 AS BIT) AS [status]
		, 0 AS [id]
		, '-' AS [name]
		UNION ALL
		SELECT DISTINCT CAST(1 AS BIT) AS [status]
		, [machines].[id]
		, [machines].[name]
		FROM [APCSProDB].[mc].[machines]
		INNER JOIN [APCSProDB].[mc].[models] ON [models].[id] = [machines].[machine_model_id]
		INNER JOIN [APCSProDB].[mc].[group_models] ON [group_models].[machine_model_id] = [models].[id]
		INNER JOIN [APCSProDB].[mc].[groups] ON [groups].[id] = [group_models].[machine_group_id]
		INNER JOIN [APCSProDB].[method].[jobs] ON [jobs].[machine_group_id] = [groups].[id]
		INNER JOIN [APCSProDB].[method].[processes] ON [processes].[id] = [jobs].[process_id]
		WHERE [processes].[id] = @process_id
		ORDER BY [id]
	END
	ELSE
	BEGIN
		SELECT CAST(0 AS BIT) AS [status]
		, 0 AS [id]
		, '' AS [name]
	END
END
