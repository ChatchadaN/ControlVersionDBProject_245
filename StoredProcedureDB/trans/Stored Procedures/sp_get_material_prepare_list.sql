-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_material_prepare_list]
	@category INT, --  4 = Resin
	@barcode VARCHAR(255) = NULL, 
	@status INT = NULL -- 1 In prepare, 2 Prepared
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @SQL NVARCHAR(MAX);

	IF @category = 4
	BEGIN
		SET @SQL = 'SELECT barcode, [name], lot_no, quantity, descriptions as unit, wait_limit_date wait_date, open_limit_date1 open_limit_date, limit_date
					FROM APCSProDB_lsi_110.trans.materials m
					JOIN APCSProDB_lsi_110.material.productions p on m.material_production_id = p.id
					JOIN APCSProDB_lsi_110.material.material_codes on unit_code = material_codes.code AND [group] = ''package_unit''
					WHERE open_limit_date1 IS NOT NULL
					AND wait_limit_date IS NOT NULL ';

		IF @barcode IS NOT NULL
			SET @SQL += ' AND barcode = @barcode ';

		IF @status = 1
			SET @SQL += ' AND wait_limit_date > GETDATE() ';
		IF @status = 2
			SET @SQL += ' AND wait_limit_date < GETDATE() ';
		
		EXEC sp_executesql @SQL, 
				N'@barcode VARCHAR(255)', @barcode;

	END

END
