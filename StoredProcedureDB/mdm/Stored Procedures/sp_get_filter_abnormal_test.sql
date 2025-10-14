------------------------------ Creater Rule ------------------------------
-- Project Name				: MDN
-- Author Name              : CHATCHADAPORN N
-- Written Date             : 2024/02/05
-- Procedure Name 	 		: [mdm].[sp_get_filter_abnormal]
-- Filename					: mdm.sp_get_filter_abnormal.sql
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: method.abnormal_detail
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [mdm].[sp_get_filter_abnormal_test]
(	 
	  @abmode			varchar(MAX) = '%'
	, @isdisable		varchar(MAX) = '%'
	, @abname		varchar(MAX) = '%'
	, @filter			int = 1 
)
	--   1: abmode	 2: isdisable   3: abname
						
AS
BEGIN 
	SET NOCOUNT ON;	

	IF(@filter = 1)
	BEGIN
		SELECT name as filter_name FROM APCSProDB.trans.abnormal_mode
	END
	ELSE IF(@filter = 2)
	BEGIN
		SELECT is_disable as filter_name FROM APCSProDB.trans.abnormal_detail
		GROUP BY is_disable
	END
	ELSE IF(@filter = 3)
	BEGIN
		SELECT name AS filter_name 
		FROM APCSProDB.trans.abnormal_detail
		WHERE is_disable LIKE @isdisable
		GROUP BY name
	END
END
