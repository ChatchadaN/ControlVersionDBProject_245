-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_resin_prepare_list]
	@barcode VARCHAR(255) = NULL, 
	@status INT = NULL -- 1 In prepare, 2 Prepared
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @SQL NVARCHAR(MAX);
	BEGIN
		SET @SQL = 'SELECT m.id, barcode, [name], lot_no, quantity, descriptions as unit, wait_limit_date wait_date, open_limit_date1 open_limit_date, limit_date
							, emp_code, display_name, m.updated_at
					FROM APCSProDB_lsi_110.trans.materials m
					JOIN APCSProDB_lsi_110.material.productions p on m.material_production_id = p.id
					JOIN APCSProDB_lsi_110.material.material_codes on unit_code = material_codes.code AND [group] = ''package_unit''
					JOIN DWH_wh_230.man.employees on m.updated_by = employees.id
					WHERE 1=1
					AND open_limit_date1 IS NOT NULL
					AND wait_limit_date IS NOT NULL ';

		IF ISNULL(@barcode, '') <> ''
			SET @SQL += ' AND barcode = @barcode ';

		IF @status = 1
			SET @SQL += ' AND wait_limit_date > GETDATE() ';
		IF @status = 2
			SET @SQL += ' AND wait_limit_date < GETDATE() ';
		
		EXEC sp_executesql @SQL, 
				N'@barcode VARCHAR(255)', @barcode;

	END


END
