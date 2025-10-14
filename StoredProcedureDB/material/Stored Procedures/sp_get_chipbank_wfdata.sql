------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Author Name              : Chatchadaporn N
-- Written Date             : 2024/08/22
-- Procedure Name 	 		: [material].[sp_get_wfdetails]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_get_chipbank_wfdata]
	@mat_id INT 
AS
BEGIN
	SET NOCOUNT ON;
	SELECT material_id 
		,idx 
		,qty 
		,is_enable
	FROM APCSProDB.trans.wf_datas
	WHERE material_id = @mat_id
END
