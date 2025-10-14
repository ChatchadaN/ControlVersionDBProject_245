-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_get_unmapped_lot_record_columns_ver_001]
	@template_id INT
AS
BEGIN

	SET NOCOUNT ON;

	IF (ISNULL(@template_id,0) > 0)
	BEGIN
		SELECT MENU.id, MENU.column_name, MENU.json_name, MENU.data_type, case when MENUTEMP.id is null then 0 else 1 end as is_created
		FROM [APCSProDWR].[lds].[lot_record_menu] MENU
		LEFT JOIN [APCSProDWR].[lds].[lot_record_menu_templates] MENUTEMP ON MENU.id = MENUTEMP.lot_record_menu_id AND (MENUTEMP.lot_record_templates_id = @template_id)
		WHERE ISNULL(is_common,0) = 0
		ORDER BY is_created DESC, MENU.column_name ASC
	END
	/*
	SELECT MENU.id, MENU.column_name, MENU.json_name, MENU.data_type
	FROM [APCSProDWR].[lds].[lot_record_menu] MENU
	LEFT JOIN [APCSProDWR].[lds].[lot_record_menu_templates] MENUTEMP ON MENU.id = MENUTEMP.lot_record_menu_id AND (MENUTEMP.lot_record_templates_id = @template_id)
	WHERE created_table = 'lot_extends' 
	AND MENUTEMP.id IS NULL
	*/
END
