CREATE PROCEDURE [trans].[sp_get_material_record_wire_detail] 
	-- Add the parameters for the stored procedure here
		@barcode as NVARCHAR(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	 select barcode,
	 record_class.descriptions as record_class,
	 productions.name as wireName,
	 mat_state.descriptions as material_state,
	 ProcessState.descriptions as process_state,
	 form_location.name as Form_location,
	 To_location.name as To_Location,
	 material_records.quantity,
	 CONVERT(Char(16), recorded_at ,20) as recorded_at from APCSProDB.trans.material_records 
	 inner join  [APCSProDB].material.productions on material_records.material_production_id = productions.id
	 inner join [APCSProDB].[material].[categories] on productions.category_id = [categories].id
	 inner join [APCSProDB].[material].[material_codes] as mat_state on material_records.material_state = mat_state.code AND mat_state.[group] = 'matl_state'
	 inner join [APCSProDB].[material].[material_codes] as ProcessState on process_state = ProcessState.code and ProcessState.[group] = 'process_state'
	 inner join [APCSProDB].[material].[material_codes] as record_class on record_class = record_class.code and record_class.[group] = 'record_class'
	 inner join APCSProDB.material.locations as form_location on form_location.id = material_records.location_id
	 left join APCSProDB.material.locations as To_location on To_location.id = material_records.to_location_id
	 where  [categories].name LIKE '%WIRE%' and barcode = @barcode  order by recorded_at

END
