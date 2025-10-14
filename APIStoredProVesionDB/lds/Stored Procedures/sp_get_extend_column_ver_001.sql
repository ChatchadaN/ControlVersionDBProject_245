-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_get_extend_column_ver_001]
	@record_template VARCHAR(20) = NULL -- , @is_common INT = NULL
AS
BEGIN

	SET NOCOUNT ON;

	-- IF (ISNULL(@record_type,'') <> '')
	-- BEGIN

		SELECT m.column_name, m.json_name, 0 from_tb
			FROM APCSProDWR.lds.lot_record_templates t
			LEFT JOIN APCSProDWR.lds.lot_record_menu_templates tm ON t.id = tm.lot_record_templates_id
			LEFT JOIN APCSProDWR.lds.lot_record_menu m ON tm.lot_record_menu_id = m.id
			WHERE t.[name] = @record_template
			AND m.created_table = 'lot_extends'
		
		UNION

		SELECT m.column_name, m.json_name, 1 from_tb
			FROM APCSProDWR.lds.lot_record_menu m
			LEFT JOIN APCSProDWR.lds.lot_record_menu_templates tm ON tm.lot_record_menu_id = m.id
			LEFT JOIN APCSProDWR.lds.lot_record_templates t ON t.id = tm.lot_record_templates_id
			WHERE ( m.is_common = 1 OR
			(t.[name] = @record_template AND m.created_table = 'lot_transactions') );

	/*
		IF (ISNULL(@is_common,0) = 0)
		BEGIN
			SELECT m.column_name, m.json_name
			FROM APCSProDWR.lds.lot_record_templates t
			LEFT JOIN APCSProDWR.lds.lot_record_menu_templates tm ON t.id = tm.lot_record_templates_id
			LEFT JOIN APCSProDWR.lds.lot_record_menu m ON tm.lot_record_menu_id = m.id
			WHERE t.[name] = @record_type
			AND m.created_table = 'lot_extends';
		END
		ELSE IF (ISNULL(@is_common,0) = 1)
		BEGIN
			SELECT m.column_name, m.json_name
			FROM APCSProDWR.lds.lot_record_menu m
			LEFT JOIN APCSProDWR.lds.lot_record_menu_templates tm ON tm.lot_record_menu_id = m.id
			LEFT JOIN APCSProDWR.lds.lot_record_templates t ON t.id = tm.lot_record_templates_id
			WHERE ( m.is_common = 1 OR
			(t.[name] = @record_type AND m.created_table = 'lot_transactions') );
		END
		*/
	-- END
	
END
