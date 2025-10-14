
-- =============================================
-- Author:		<Author,Sadanan B.>
-- Create date: <Create Date, 2025/07/31>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_stock_in_pd_001]
	-- Add the parameters for the stored procedure here
		@location_id			INT  
		 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  
			SELECT	  material_outgoings.id	
					, day_id
					,CONVERT( VARCHAR , [days].date_value	,121 ) AS date_value		
					, from_location_id
					, from_location.[name]					AS from_location
					, to_location_id
					, to_location.[name]					AS to_location	
					, status_code	
					, created_by.[name]							AS operator
					, created_by.emp_num							AS  picking_by	
					, ISNULL(CONVERT(VARCHAR ,material_outgoings.created_at,121	),'')	AS created_at
					, created_by.emp_num					AS created_by	
					, ISNULL(CONVERT(VARCHAR , material_outgoings.updated_at,121),'')	AS updated_at
					, ISNULL(updated_by.emp_num	,'')		AS updated_by  
			FROM  APCSProDB.trans.material_outgoings
			INNER JOIN APCSProDB.material.locations from_location
			ON  from_location.id  = material_outgoings.from_location_id
			INNER JOIN APCSProDB.material.locations to_location
			ON  to_location.id  = material_outgoings.to_location_id
			LEFT JOIN APCSProDB.man.users		AS created_by
			ON  created_by.id =  material_outgoings.created_by  
			LEFT JOIN APCSProDB.man.users		AS updated_by
			ON  updated_by.id =  material_outgoings.updated_by   
			LEFT JOIN APCSProDB.trans.[days]
			ON  [days].id = material_outgoings.day_id
			WHERE status_code = 0	AND material_outgoings.to_location_id = @location_id
			ORDER BY material_outgoings.id DESC


END
