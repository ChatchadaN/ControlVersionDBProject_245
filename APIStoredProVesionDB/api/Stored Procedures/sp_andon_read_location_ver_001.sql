-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_andon_read_location_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@search varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT DISTINCT [name]
	FROM [APCSProDB].[trans].[locations]
	WHERE [name] LIKE CONCAT('%', @search, '%'))
	BEGIN
		SELECT CAST(1 AS BIT) AS [status]
		, [master_location].[name] AS master_location
		FROM
		(
			SELECT DISTINCT [name]
			FROM [APCSProDB].[trans].[locations]
			WHERE [name] LIKE CONCAT('%', @search, '%')
			and headquarter_id is not null
		) AS master_location
	END
	ELSE
	BEGIN
		SELECT CAST(0 AS BIT) AS [status]
		, '' AS master_location
	END
END
