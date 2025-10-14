
CREATE PROCEDURE [act].[sp_get_processing_time] @p_time INT OUTPUT
AS
BEGIN
	-- 開始日時を取得する
	DECLARE @STARTDATETIME DATETIME2 = SYSDATETIME()

	--
	--WAITFOR DELAY '00:00:05'
	EXEC act.sp_machinemonitor_gantt_status_v4 '2020-06-15 00:00:00'
		,'2020-06-17 00:00:00'
		,8
		,'7,1119,216,1307,184,220,221,222,223'

	--
	EXEC act.sp_machinemonitor_summary_status_v5 '2020-06-15 00:00:00'
		,'2020-06-17 00:00:00'
		,8
		,'7,1119,216,1307,184,220,221,222,223'

	-- 終了日時と開始日時の差から処理時間を取得する
	SET @p_time = DATEDIFF(MILLISECOND, @STARTDATETIME, SYSDATETIME())

	RETURN 0
END
