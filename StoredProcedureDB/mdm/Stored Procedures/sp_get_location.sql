

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_location]
	-- Add the parameters for the stored procedure here
	@id AS INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	BEGIN
		SELECT TOP (100) Loc.id 
		, Loc.name
		, Loc.headquarter_id
		, hq.short_name
		, Loc.address
		, Loc.x
		, Loc.y
		, Loc.z
		, Loc.depth
		, Loc.queue
		, Loc.wh_code
		, Loc.created_at
		, Loc.created_by
		, Loc.updated_at
		, Loc.updated_by
		FROM [APCSProDB].[trans].[locations] AS Loc with (NOLOCK)
		LEFT JOIN [APCSProDB].[man].[headquarters] AS hq with (NOLOCK) ON hq.id = Loc.headquarter_id
		WHERE (Loc.headquarter_id is not null AND Loc.id LIKE '%' AND @id = 0) OR (Loc.headquarter_id is not null AND Loc.id = @id AND @id <> 0)
		--WHERE (Loc.id LIKE '%' AND @id = 0) OR (Loc.id = @id AND @id <> 0 AND Loc.headquarter_id is not null)
	END
END