-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_lot_recall_text]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @first_day DATETIME --= DATEADD(DAY, 1, EOMONTH(GETDATE(), -1)) --first day of last month
		, @last_day DATETIME --= EOMONTH(GETDATE()) --last day of last month

	SET @first_day = CAST(EOMONTH(GETDATE(), -1) AS VARCHAR) + ' 08:00:00';
	SET @last_day = CAST(EOMONTH(GETDATE()) AS VARCHAR) + ' 08:00:00';

	SELECT CAST('"' AS VARCHAR) + CAST(IIF(lot_new.production_category = 70,'01','02') AS CHAR(2)) + CAST('",' AS VARCHAR) 
			+ CAST('"' AS VARCHAR) + CAST(lot_new.lot_no AS CHAR(10)) + CAST('",' AS VARCHAR)
			+ CAST('"' AS VARCHAR) + CAST(lot_original.lot_no AS CHAR(10)) + CAST('",' AS VARCHAR)
			+ CAST('"' AS VARCHAR) + CAST(packages.name AS CHAR(10)) + CAST('",' AS VARCHAR)
			+ CAST('"' AS VARCHAR) + CAST(device_names.name AS CHAR(20)) + CAST('",' AS VARCHAR)
			+ CAST('"' AS VARCHAR) + CAST(device_names.assy_name AS CHAR(20)) + CAST('",' AS VARCHAR)
			+ CAST('"' AS VARCHAR) + CAST(ISNULL(fukuoka.R_Fukuoka_Model_Name,device_names.name) AS CHAR(20)) + CAST('",' AS VARCHAR)
			+ CAST('"' AS VARCHAR) + CAST(ISNULL(device_names.rank,'') AS CHAR(5)) + CAST('",' AS VARCHAR)
			+ CAST('"' AS VARCHAR) + CAST(ISNULL(device_names.tp_rank,'') AS CHAR(3)) + CAST('",' AS VARCHAR)
			+ CAST('"' AS VARCHAR) + CAST(lot_new.qty_in AS VARCHAR) + CAST('",' AS VARCHAR)
			+ CAST('"' AS VARCHAR) + CAST(ISNULL(lot_original.qty_out,0) AS VARCHAR) + CAST('",' AS VARCHAR)
			+ CAST('"' AS VARCHAR) + FORMAT(lot_new.created_at,'yyyy/MM/dd HH:mm:ss') + CAST('"' AS VARCHAR)
		AS text_data
	FROM APCSProDB.trans.lots AS lot_new
	INNER JOIN APCSProDB.trans.lot_combine ON lot_new.id = lot_combine.lot_id
	INNER JOIN APCSProDB.trans.lots AS lot_original ON lot_original.id = lot_combine.member_lot_id
	INNER JOIN APCSProDB.method.device_names ON lot_new.act_device_name_id = device_names.id
	INNER JOIN APCSProDB.method.packages ON device_names.package_id = packages.id
	OUTER APPLY (
		SELECT TOP 1 ROHM_Model_Name
			, ASSY_Model_Name
			, R_Fukuoka_Model_Name
		FROM APCSProDB.method.allocat_temp AS at
		WHERE TRIM(at.ROHM_Model_Name) = TRIM(device_names.name)
			AND TRIM(at.ASSY_Model_Name) = TRIM(device_names.assy_name) 
	) AS fukuoka
	WHERE lot_new.production_category IN (70,21,22,23)
		AND lot_new.created_at BETWEEN @first_day and @last_day
	ORDER BY lot_new.created_at ASC;
END
