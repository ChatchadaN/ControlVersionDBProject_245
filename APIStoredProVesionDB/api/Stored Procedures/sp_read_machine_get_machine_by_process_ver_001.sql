-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_machine_get_machine_by_process_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@process_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	--SELECT DISTINCT CAST(1 AS BIT) AS [status]
	--	, [machines].[id]
	--	, [machines].[name]
	--FROM [APCSProDB].[mc].[machines]
	--INNER JOIN [APCSProDB].[mc].[models] ON [models].[id] = [machines].[machine_model_id]
	--INNER JOIN [APCSProDB].[mc].[group_models] ON [group_models].[machine_model_id] = [models].[id]
	--INNER JOIN [APCSProDB].[mc].[groups] ON [groups].[id] = [group_models].[machine_group_id]
	--INNER JOIN [APCSProDB].[method].[jobs] ON [jobs].[machine_group_id] = [groups].[id]
	--INNER JOIN [APCSProDB].[method].[processes] ON [processes].[id] = [jobs].[process_id]
	--WHERE [machines].[id] > 0
	--	AND (RIGHT([machines].[name], 3) != '000' AND RIGHT([machines].[name], 3) != '-00')
	--AND [processes].[id] = @process_id
	--ORDER BY [machines].[id]


 --   -- Insert statements for procedure here
	IF EXISTS(SELECT [machines].[id]
	FROM [APCSProDB].[mc].[machines]
	INNER JOIN [APCSProDB].[mc].[models] ON [models].[id] = [machines].[machine_model_id]
	INNER JOIN [APCSProDB].[mc].[group_models] ON [group_models].[machine_model_id] = [models].[id]
	INNER JOIN [APCSProDB].[mc].[groups] ON [groups].[id] = [group_models].[machine_group_id]
	INNER JOIN [APCSProDB].[method].[jobs] ON [jobs].[machine_group_id] = [groups].[id]
	INNER JOIN [APCSProDB].[method].[processes] ON [processes].[id] = [jobs].[process_id]
	WHERE [machines].[id] > 0
	AND [processes].[id] = @process_id)
	BEGIN
		SELECT DISTINCT CAST(1 AS BIT) AS [status]
		, [machines].[id]
		, [machines].[name]
		FROM [APCSProDB].[mc].[machines]
		INNER JOIN [APCSProDB].[mc].[models] ON [models].[id] = [machines].[machine_model_id]
		INNER JOIN [APCSProDB].[mc].[group_models] ON [group_models].[machine_model_id] = [models].[id]
		INNER JOIN [APCSProDB].[mc].[groups] ON [groups].[id] = [group_models].[machine_group_id]
		INNER JOIN [APCSProDB].[method].[jobs] ON [jobs].[machine_group_id] = [groups].[id]
		INNER JOIN [APCSProDB].[method].[processes] ON [processes].[id] = [jobs].[process_id]
		WHERE [machines].[id] > 0
		AND [processes].[id] = @process_id
		ORDER BY [machines].[id]
	END
	ELSE
	BEGIN
		SELECT DISTINCT CAST(1 AS BIT) AS [status]
			, [machines].[id]
			, [machines].[name]
		FROM [APCSProDB].[mc].[machines]
		INNER JOIN [APCSProDB].[mc].[models] ON [models].[id] = [machines].[machine_model_id]
		INNER JOIN [APCSProDB].[mc].[group_models] ON [group_models].[machine_model_id] = [models].[id]
		INNER JOIN [APCSProDB].[mc].[groups] ON [groups].[id] = [group_models].[machine_group_id]
		INNER JOIN [APCSProDB].[method].[jobs] ON [jobs].[machine_group_id] = [groups].[id]
		INNER JOIN [APCSProDB].[method].[processes] ON [processes].[id] = [jobs].[process_id]
		--SELECT CAST(0 AS BIT) AS [status]
		--, '' AS [id]
		--, '' AS [name]
	END
END
