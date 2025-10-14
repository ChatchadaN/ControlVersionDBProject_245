CREATE PROCEDURE [rans].[sp_get_machine mp] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	---- Query find machine MP
	SELECT [machines].[id]
		, [machines].[name]
	FROM [APCSProDB].[mc].[machines]
	WHERE [machines].[name] LIKE 'MP%'  -- find location MP
		AND [machines].[short_name1] NOT IN ('Test Machine','ATOM Move');
END
