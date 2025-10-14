CREATE PROCEDURE [atom].[sp_get_class_with_rack]
	-- Add the parameters for the stored procedure here
	@class_id int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET @class_id = CASE WHEN  @class_id = 0 THEN NULL ELSE @class_id  END  

    -- Insert statements for procedure here
	---- Query find machine compare location
	SELECT [class_id]
	 ,class.class_no
	 ,[location_name]
	FROM [APCSProDB].[inv].[class_locations] as rack
	INNER JOIN APCSProDB.inv.Inventory_classfications AS class ON class.id = rack.class_id
	WHERE rack.class_id =  @class_id  OR  @class_id  IS NULL 
END
