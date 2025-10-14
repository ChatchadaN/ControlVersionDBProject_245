
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_combine]
	-- Add the parameters for the stored procedure here
	@limit_id AS INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		SELECT limit_id
		, package_group
		, package_name
		, device_name
		, limit_of_lot
		, is_enable
		, create_at
		, create_by
		, update_at
		, update_by
		, started_at
		, ended_at
		FROM [APCSProDWH].tg.condition_mix_limit_lot
		WHERE (limit_id LIKE '%' AND @limit_id = 0) OR (limit_id = @limit_id AND @limit_id <> 0)
	END
END