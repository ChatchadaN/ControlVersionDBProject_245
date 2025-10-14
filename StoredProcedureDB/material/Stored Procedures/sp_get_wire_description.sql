-- =============================================
-- Author:		<Sadanan B.>
-- Create date: <2025/09/02>
-- Description:	<GetWireDescription>
-- =============================================
CREATE PROCEDURE [material].[sp_get_wire_description]
	-- Add the parameters for the stored procedure here
	@production_id		NVARCHAR(255) = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 

			SELECT    ROW_NUMBER() OVER(ORDER BY wireName ) AS indexer
					, wireName
					, wireState
					, SUM(quantity) AS quantity
					, prodId 
			FROM 
				( SELECT	  productions.[name] AS wireName
							, productions.id AS prodId
							, CONVERT(INT,quantity) AS quantity
							, CASE WHEN location_id IN (1,2) AND material_state = 1 THEN 'WH' 
								WHEN location_id IN (7,5) AND material_state = 1 THEN 'PD NEW' 
								WHEN location_id IN (7,5) AND material_state = 2 THEN 'PD Used(inp)' 
								WHEN location_id = 9 AND material_state = 2 THEN 'PD Used(M)'
								WHEN location_id = 9 AND material_state = 12 THEN 'ON Machine'  
								ELSE NULL END AS wireState 
					FROM [APCSProDB].[trans].[materials]  
					INNER JOIN  [APCSProDB].material.productions 
					ON [materials].material_production_id = productions.id 
					INNER JOIN [APCSProDB].[material].[categories] 
					ON productions.category_id = [categories].id 
					INNER JOIN [APCSProDB].[material].[material_codes] 
					ON [materials].material_state = [material_codes].code 
					AND [material_codes].[group] = 'matl_state' 
					WHERE	material_state IN (1,2,12) 
					AND location_id IN (1,2,7,5,9) 
					AND category_id = 1 
			) AS RawData 
			WHERE  (ISNULL(@production_id, '') = '' OR prodId IN (SELECT  [value] FROM STRING_SPLIT(@production_id,',')) )
			AND wireState IS NOT NULL 
			GROUP BY wireState,wireName,prodId 
			ORDER BY wireName

 
END
