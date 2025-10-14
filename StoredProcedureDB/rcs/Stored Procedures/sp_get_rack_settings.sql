------------------------------ Creater Rule ------------------------------
-- Project Name				: RCS
-- Author Name              : Chatchadaporn N.
-- Written Date             : 2025/01/07
-- Database Referd			: StoredProcedureDB
-- Specific Logic           : 
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [rcs].[sp_get_rack_settings]
	 @rack_id INT = NULL				
AS
BEGIN	 
	--SET NOCOUNT ON;
	SET NOCOUNT ON;	
	SELECT [rack_settings].[rack_id]
		,[rack_controls].[name] AS rack_name
		,[rack_settings].[rack_set_id]
		,[rack_sets].[name] AS rack_set
		,[rack_settings].[priority]
		,[rack_settings].[created_at]
		,user1.emp_num AS [created_by]
		,[rack_settings].[updated_at]
		,user2.emp_num AS [updated_by]
	FROM APCSProDB.rcs.rack_settings
	INNER JOIN APCSProDB.rcs.rack_controls ON rack_settings.rack_id = rack_controls.id
	INNER JOIN APCSProDB.rcs.rack_sets ON rack_settings.rack_set_id = rack_sets.id
	LEFT JOIN [APCSProDB].[man].[users] AS user1 ON rack_settings.[created_by] = [user1].[id]
	LEFT JOIN [APCSProDB].[man].[users] AS user2 ON rack_settings.[updated_by] = [user2].[id]
	WHERE (@rack_id IS NULL OR rack_settings.rack_id = @rack_id)
	ORDER BY rack_id, rack_set_id
END