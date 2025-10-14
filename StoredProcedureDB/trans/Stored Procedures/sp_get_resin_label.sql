-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_resin_label]
	@barcode VARCHAR(255)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @is_unfreeze INT = 0;
	SELECT @is_unfreeze = 1 FROM APCSProDB_lsi_110.trans.materials
	WHERE barcode = @barcode
	AND open_limit_date1 IS NOT NULL
	AND wait_limit_date IS NOT NULL;

	IF ISNULL(@barcode, '') = ''
		BEGIN
			SELECT 'FALSE' AS Is_Pass,
				   'NO BARCODE !!' AS Error_Message_ENG,
				   N'ไม่มี Barcode !!' AS Error_Message_THA,
				   '' AS Handling;
		END
	ELSE IF @is_unfreeze = 0
		BEGIN
			SELECT 'FALSE' AS Is_Pass,
				   'No defrost data !!' AS Error_Message_ENG,
				   N'ไม่มีข้อมูลการทำละลาย !!​' AS Error_Message_THA,
				   '' AS Handling;
		END
	ELSE
		BEGIN
			SELECT 'TRUE' AS Is_Pass, '' AS Error_Message_ENG, '' AS Error_Message_THA, '' AS Handling, m.id, barcode, 
					name, quantity, lot_no, wait_limit_date wait_date, open_limit_date1 open_limit_date, limit_date, descriptions as unit
					, emp_code, display_name, m.updated_at
			FROM APCSProDB_lsi_110.trans.materials m
			JOIN APCSProDB_lsi_110.material.productions p on m.material_production_id = p.id
			JOIN APCSProDB_lsi_110.material.material_codes on unit_code = material_codes.code AND [group] = 'package_unit'
			JOIN DWH_wh_230.man.employees on m.updated_by = employees.id
			WHERE barcode = @barcode
		END

END