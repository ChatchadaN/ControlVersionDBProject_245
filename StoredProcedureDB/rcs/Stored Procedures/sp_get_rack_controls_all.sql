------------------------------ Creater Rule ------------------------------
-- Project Name				: RCS
-- Author Name              : Chatchadaporn N.
-- Written Date             : 2025/01/07
-- Database Referd			: StoredProcedureDB
-- Specific Logic           : 
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [rcs].[sp_get_rack_controls_all]
(
	@rack_id INT = 0
)		
AS
BEGIN	 
	--SET NOCOUNT ON;
	SET NOCOUNT ON;	
	SET @rack_id = CASE WHEN  @rack_id = 0 THEN NULL ELSE @rack_id  END  

	SELECT [rack_controls].[id]
		, [rack_controls].[name] AS [rack_name]
		, [rack_controls].[category] AS [category_id]
		, [rack_categories].[name] AS [category]
		, [rack_categories].[pattern]
		, [rack_controls].[priority]
		, [rack_controls].[leadtime]
		, [rack_controls].[is_enable]
		, [rack_controls].[created_at]
		, user1.emp_num AS [created_by]
		, [rack_controls].[updated_at]
		, user2.emp_num AS [updated_by]
		, [rack_controls].[location_id]
		, [locations].[name] AS [location]
		, [rack_controls].[is_fifo]
		, [rack_controls].[is_type_control]
	FROM [APCSProDB].[rcs].[rack_controls]
	INNER JOIN [APCSProDB].[rcs].[rack_categories] ON [rack_controls].[category] = [rack_categories].[id]
	LEFT JOIN [APCSProDB].[trans].[locations] ON [rack_controls].[location_id] = [locations].[id]
	LEFT JOIN [APCSProDB].[man].[users] AS user1 ON [rack_controls].[created_by] = [user1].[id]
	LEFT JOIN [APCSProDB].[man].[users] AS user2 ON [rack_controls].[updated_by] = [user2].[id]
	WHERE [rack_controls].[id] =  @rack_id  OR  @rack_id  IS NULL 
END
