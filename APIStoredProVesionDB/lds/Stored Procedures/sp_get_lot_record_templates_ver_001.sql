-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_get_lot_record_templates_ver_001]
	@id INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT rt.id, rt.name, rt.display_name, rt.description
		, rt.created_at, created_by.emp_code AS created_code, created_by.display_name AS created_by
		, rt.updated_at, updated_by.emp_code AS updated_code, updated_by.display_name AS updated_by
	FROM APCSProDWR.lds.lot_record_templates rt
	LEFT JOIN DWH.man.employees created_by ON rt.created_by = created_by.id
	LEFT JOIN DWH.man.employees updated_by ON rt.updated_by = updated_by.id
	WHERE (rt.[id] = @id  OR ISNULL(@id,0) = 0)

END
