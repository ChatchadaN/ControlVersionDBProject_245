------------------------------ Creater Rule ------------------------------
-- Project Name				: LSI SEARCH PRO
-- Author Name              : Chatchadaporn N.
-- Written Date             : 20233/07/07
-- Database Referd			: StoredProcedureDB
-- Specific Logic           : 
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[sp_get_filter_lsisearch_erecord_AGPaste]
(		
	@filter			INT = 1 
	-- 1: machine 2: AGPasteType
)
						
AS
BEGIN	 
	--SET NOCOUNT ON;
	SET NOCOUNT ON;	

	IF(@filter = 1)
	BEGIN
		SELECT [MixMCNo] AS filter_name
		FROM [DBx].[MAT].[MixAGPaste]
		GROUP BY [MixMCNo]
		ORDER BY [MixMCNo]
	END
	ELSE IF(@filter = 2)
	BEGIN	
		SELECT [AGPasteType] AS filter_name
		FROM [DBx].[MAT].[MixAGPaste]
		WHERE [AGPasteType] != ''
		GROUP BY [AGPasteType]
		ORDER BY [AGPasteType]
	END
END