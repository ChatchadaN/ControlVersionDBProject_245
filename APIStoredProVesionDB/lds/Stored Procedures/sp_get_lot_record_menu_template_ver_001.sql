-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_get_lot_record_menu_template_ver_001]
	@lot_record_templates_id INT = NULL, @lot_record_menu_id INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT mt.id, mt.lot_record_templates_id, rt.[name] AS template_name, rt.display_name AS template_display_name, mt.lot_record_menu_id, rm.column_name, rm.json_name
		, mt.is_display
		, mt.created_at, created_by.emp_code AS created_code, created_by.display_name AS created_by, mt.updated_at, updated_by.emp_code AS updated_code, updated_by.display_name AS updated_by
	FROM APCSProDWR.lds.lot_record_menu_templates mt
	JOIN APCSProDWR.lds.lot_record_templates rt ON mt.lot_record_templates_id = rt.id
	JOIN APCSProDWR.lds.lot_record_menu rm ON mt.lot_record_menu_id = rm.id
	LEFT JOIN DWH.man.employees created_by ON mt.created_by = created_by.id
	LEFT JOIN DWH.man.employees updated_by ON mt.updated_by = updated_by.id
	WHERE (lot_record_templates_id = ISNULL(@lot_record_templates_id, 0) OR ISNULL(@lot_record_templates_id, 0) = 0)
	AND (lot_record_menu_id = ISNULL(@lot_record_menu_id, 0) OR ISNULL(@lot_record_menu_id, 0) = 0)

END