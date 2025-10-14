CREATE PROCEDURE [trans].[sp_get_material_confirm_data] 
	-- Add the parameters for the stored procedure here
		@location_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	------------------------------------------------------------------------------------
	select isnull([materials].[barcode],'')  as [barcode] 
		, isnull([materials].[category],'')  as [category]
		, isnull([materials].[product],'')  as [product]
		, isnull([materials].[parent_material],'') as [parent_material]
		, [materials].[inp_receive_date]
	from (
		select [materials].[barcode] 
			, [categories].[name] as [category] 
			, [productions].[name] as [product] 
			, [material_records].[record_class] 
			, [materials_parent].[barcode] as [parent_material]
			, [material_records_parent].[recorded_at] as [inp_receive_date]
			, RANK () OVER ( 
				PARTITION BY [material_records_parent].[barcode]
				ORDER BY [material_records_parent].[created_at] DESC
			) [rowmax]
		from [APCSProDB].[trans].[materials] 
		left join [APCSProDB].[trans].[materials] as [materials_parent] on [materials].[parent_material_id] = [materials_parent].[id]
		left join [APCSProDB].[trans].[material_records] as [material_records_parent] on [materials_parent].[id] = [material_records_parent].[material_id] 
			and [material_records_parent].[record_class] = 1
			and [material_records_parent].[to_location_id] = 4
		left join [APCSProDB].[material].[locations] on [materials].[location_id] = [locations].[id] 
		left join [APCSProDB].[material].[productions] on [productions].[id] = [materials].[material_production_id] 
		left join [APCSProDB].[material].[categories] on [categories].[id] = [productions].[category_id] 
		left join [APCSProDB].[trans].[material_records] on [materials].[id] = [material_records].[material_id] 
			and [material_records].[record_class] = 9 
		where [materials].[location_id] =  @location_id
			and [materials].[material_state] not in (0,3,9) and [materials].[limit_state] = 0
	) as [materials]
	where [materials].[rowmax] = 1 and [materials].[record_class] is null
	--order by [materials].[barcode]
	------------------------------------------------------------------------------------
END
