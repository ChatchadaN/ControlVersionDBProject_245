
---- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_material_locations_001]
	-- Add the parameters for the stored procedure here
		  @locations_id			INT  = 0
		, @headquarter_id		INT  = 0

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

				SELECT    locations.id	
				, locations.[name]
				, locations.headquarter_id
				, [headquarters].[name]		AS headquarter_name
				, ISNULL(locations.[address],'') AS [address]
				, locations.wh_code	
				, ISNULL(locations.created_at,'')	AS created_at
				, ISNULL([employees].emp_code,'')  AS created_by
				, ISNULL(locations.updated_at,'')		AS updated_at
				, ISNULL(updated_by.emp_code,'')   AS  updated_by
		FROM APCSProDB.material.locations
		LEFT JOIN   [10.29.1.230].[DWH].[man].[employees]
		ON locations.created_at = [employees].id
		LEFT JOIN   [10.29.1.230].[DWH].[man].[employees] AS updated_by
		ON locations.updated_by = updated_by.id
		LEFT JOIN   [10.29.1.230].[DWH].[man].[headquarters]
		ON [headquarters].id  =  locations.headquarter_id
		WHERE (locations.id = @locations_id  OR ISNULL(@locations_id,0) = 0  )
		AND (locations.headquarter_id =  @headquarter_id	OR ISNULL(@headquarter_id,0) = 0 )
		 
END
