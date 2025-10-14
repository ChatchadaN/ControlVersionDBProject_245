------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Author Name              : Chatchadaporn N
-- Written Date             : 2025/05/21
-- Procedure Name 	 		: [material].[[sp_get_chipbank_wfdata_check_seqno]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.trans.wf_details
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [material].[sp_get_chipbank_wfdata_check_seqno]
	-- Add the parameters for the stored procedure here
	@seq_no VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;	
	
	IF EXISTS (SELECT seq_no FROM APCSProDB.trans.wf_details WHERE seq_no = @seq_no)
	BEGIN
		SELECT 'FALSE' AS Is_Pass
		, '' AS Error_Message_ENG
		, '' AS Error_Message_THA
		, '' AS Handling
	END
	ELSE 
	BEGIN
		SELECT 'TRUE' AS Is_Pass
		, '' AS Error_Message_ENG
		, '' AS Error_Message_THA
		, '' AS Handling
	END
END