-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_method_get_process_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [id]
	FROM [APCSProDB].[method].[processes])
	BEGIN
		SELECT CAST(1 AS BIT) as [status]
		, [id]
		, [name]
		FROM [APCSProDB].[method].[processes]
	END
	ELSE
	BEGIN
		SELECT CAST(0 AS BIT) as [status]
		, [id]
		, [name]
		FROM [APCSProDB].[method].[processes]
	END
END
