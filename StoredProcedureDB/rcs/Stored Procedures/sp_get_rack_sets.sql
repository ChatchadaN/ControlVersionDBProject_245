------------------------------ Creater Rule ------------------------------
-- Project Name				: RCS
-- Author Name              : Chatchadaporn N.
-- Written Date             : 2025/01/07
-- Database Referd			: StoredProcedureDB
-- Specific Logic           : 
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [rcs].[sp_get_rack_sets]
(		
	@rack_id INT = NULL
)				
AS
BEGIN	 
	--SET NOCOUNT ON;
	SET NOCOUNT ON;	
	SELECT rack_sets.id
		, rack_sets.name AS rack_set
		, rack_sets.created_at
		, user1.emp_num AS created_by
		, rack_sets.updated_at
		, user2.emp_num AS updated_by
	FROM APCSProDB.rcs.rack_sets
	LEFT JOIN [APCSProDB].[man].[users] AS user1 ON rack_sets.[created_by] = [user1].[id]
	LEFT JOIN [APCSProDB].[man].[users] AS user2 ON rack_sets.[updated_by] = [user2].[id]
	WHERE rack_sets.id NOT IN (SELECT rack_set_id FROM APCSProDB.rcs.rack_settings WHERE rack_id = @rack_id)
	ORDER BY rack_sets.id
END