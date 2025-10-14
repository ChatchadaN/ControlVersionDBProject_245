-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_inventory_classfications]
	-- Add the parameters for the stored procedure here
	@class_no varchar(20) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

			SELECT inv_class.[id]
		  ,[class_no]
		  ,[rack_no]
		  ,[name_of_process]
		  ,[process_no]
		  ,[sheet_no_start]
		  ,[sheet_no_end]
		  ,[process_dept]
		  ,[section_code]
		  ,[process_name]
		  ,inv_class.[created_at]
		  ,[user2].[emp_num] AS created_by
		  ,inv_class.[updated_at]
		  ,[user1].[emp_num] AS updated_by
		  ,[stock_class]
		  ,item_labels.label_eng
			FROM [APCSProDB].[inv].[Inventory_classfications] as inv_class
			LEFT JOIN APCSProDB.trans.item_labels ON inv_class.stock_class = item_labels.val 
			and item_labels.name = 'lot_inventory.stock_class'
			LEFT JOIN [APCSProDB].[man].[users]  AS user1 ON inv_class.[updated_by] = [user1].[id]
			LEFT JOIN [APCSProDB].[man].[users]  AS user2 ON inv_class.[created_by] = [user2].[id]
			Where class_no like @class_no
			ORDER BY [rack_no] asc
END
