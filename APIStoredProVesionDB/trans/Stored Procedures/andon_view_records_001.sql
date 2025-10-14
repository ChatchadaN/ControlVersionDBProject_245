-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[andon_view_records_001]
	@location_id		INT = NULL,
	@machine_id			INT = NULL,
	@category_id		INT = NULL,
	@sub_cate_id		INT = NULL,
	@abnomal_id			INT = NULL,
	@item				VARCHAR(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @str VARCHAR(MAX)
 
	SET @str = 'SELECT contrl.id
						, contrl.andon_control_no
						, items.item
						, contrl.comment_id_at_finding
						, abnormal_detail.[name]		AS comment_name_at_finding
						, contrl.machine_id
						, machines.[name]				AS machine_name
						, items.sub_category_id
						, sub_cat.[name]				AS sub_category_name
						, cat.[name]					AS category_name
						, items.location_id
						, locations.[name]				AS location_name
						, contrl.comments
						, contrl.[is_solved]
						, contrl.[treat_state]
						, contrl.[treatment_result] 
						, created_emp.emp_code			AS created_by
						, items.created_at	AS created_at
						, updated_emp.emp_code			AS updated_by
						, contrl.updated_at	AS updated_at
				FROM       [APCSProDB].trans.andon_controls AS contrl 
				INNER JOIN [APCSProDB].trans.andon_items AS items ON contrl.id = items.andon_control_id
				LEFT JOIN [APCSProDB].mc.machines ON contrl.machine_id = machines.id
				LEFT JOIN [APCSProDB].trans.locations ON items.location_id = locations.id
				LEFT JOIN [APCSProDB].trans.abnormal_detail ON comment_id_at_finding = abnormal_detail.id
				LEFT JOIN [10.29.1.230].[AppDB].[dbo].[sub_categories] sub_cat ON items.sub_category_id = sub_cat.id
				LEFT JOIN [10.29.1.230].[AppDB].[dbo].[categories] cat ON sub_cat.category_id = cat.id
				LEFT JOIN [10.29.1.230].[DWH].[man].[employees] created_emp ON items.created_at = created_emp.id
				LEFT JOIN [10.29.1.230].[DWH].[man].[employees] updated_emp ON items.updated_by = updated_emp.id
				WHERE 1=1 ' 

	IF @location_id is not null and @location_id <> 0
			SET @str = @str + 'AND items.location_id = ' + CAST(@location_id AS NVARCHAR)
	IF @machine_id is not null and @machine_id <> 0
			SET @str = @str + 'AND contrl.machine_id = ' + CAST(@machine_id AS NVARCHAR)
	IF @category_id is not null and @category_id <> 0
			SET @str = @str + 'AND cat.id = ' + CAST(@category_id AS NVARCHAR)
	IF @sub_cate_id is not null and @sub_cate_id <> 0
			SET @str = @str + 'AND items.sub_category_id = ' + CAST(@sub_cate_id AS NVARCHAR)
	IF @abnomal_id is not null and @abnomal_id <> 0
			SET @str = @str + 'AND contrl.comment_id_at_finding = ' + CAST(@abnomal_id AS NVARCHAR)
	IF @item is not null and  @item <> ''
			SET @str = @str + 'AND items.item = ''' + @item + ''''
		 
	EXEC(@str)

	 
END
