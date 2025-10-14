
CREATE PROCEDURE [act].[sp_user_specific_data_sbl_result] (
	@date_from DATETIME
	,@date_to DATETIME
	)
AS
BEGIN
	--DECLARE @test_date_from DATETIME = '2021-10-01'
	DECLARE @test_date_from DATETIME = @date_from
	DECLARE @test_date_to DATETIME = @date_to

	SELECT t1.device AS device_name
		,t1.job AS job_name
		--処理日時
		,t1.recorded_at AS recorded_at
		,t1.lot_no AS lot_no
		--総測定数
		,t1.qty_pass + TotalNGQty + TotalNGBin17Qty + TotalNGBin19PassQty + TotalNGBin19Qty + TotalNGBin27Qty + TotalPassBin27Qty + TotalMeka1Qty + TotalMeka2Qty + TotalMeka4Qty + TotalUnknowQty AS qty_total
		--良品数
		,t1.qty_pass AS qty_pass
		--不良数
		,TotalNGQty + TotalNGBin17Qty + TotalNGBin19PassQty + TotalNGBin19Qty + TotalNGBin27Qty + TotalPassBin27Qty + TotalMeka1Qty + TotalMeka2Qty + TotalMeka4Qty + TotalUnknowQty AS qty_ng
		--メカ不良
		,t1.TotalMeka1Qty + t1.TotalMeka2Qty + t1.TotalMeka4Qty AS qty_mech_ng
		--Bin19の不良数
		,t1.TotalNGBin19PassQty + t1.TotalNGBin19Qty AS qty_bin19_ng
		--Binリミット
		,t1.sbl_upper_limit AS sbl_upper_limit
		--Bin不良率
		,convert(DECIMAL(6, 3), convert(DECIMAL(7, 2), (TotalNGBin19PassQty + TotalNGBin19Qty)) * 100 / (t1.qty_pass + TotalNGQty + TotalNGBin17Qty + TotalNGBin19PassQty + TotalNGBin19Qty + TotalNGBin27Qty + TotalPassBin27Qty + TotalUnknowQty)) AS bin_ng_rate
		--プログラム名
		,t1.ProgramName AS program_name
		--テスタ機台番号
		,t1.ChannelATesterNo AS tester_no
		--ハンドラ
		,t1.handler AS handler
		,t1.Remark AS remark
	FROM (
		SELECT rtrim(p.name) AS package
			,rtrim(d.name) AS device
			,r.recorded_at
			,l.id AS lot_id
			,l.ship_at
			,rtrim(l.lot_no) AS lot_no
			,j.id AS job_id
			,j.name AS job
			,e.id
			,r.qty_pass
			,r.qty_fail
			,r.qty_last_fail
			,e.extend_data.value('(/LotDataCommon/TotalGoodBin1Qty)[1]', 'int') AS TotalGoodBin1Qty
			,e.extend_data.value('(/LotDataCommon/TotalNGQty)[1]', 'int') AS TotalNGQty
			,e.extend_data.value('(/LotDataCommon/TotalNGBin17Qty)[1]', 'int') AS TotalNGBin17Qty
			,e.extend_data.value('(/LotDataCommon/TotalNGBin19PassQty)[1]', 'int') AS TotalNGBin19PassQty
			,e.extend_data.value('(/LotDataCommon/TotalNGBin19Qty)[1]', 'int') AS TotalNGBin19Qty
			,e.extend_data.value('(/LotDataCommon/TotalPassBin27Qty)[1]', 'int') AS TotalPassBin27Qty
			,e.extend_data.value('(/LotDataCommon/TotalNGBin27Qty)[1]', 'int') AS TotalNGBin27Qty
			,e.extend_data.value('(/LotDataCommon/TotalMeka1Qty)[1]', 'int') AS TotalMeka1Qty
			,e.extend_data.value('(/LotDataCommon/TotalMeka2Qty)[1]', 'int') AS TotalMeka2Qty
			,e.extend_data.value('(/LotDataCommon/TotalMeka4Qty)[1]', 'int') AS TotalMeka4Qty
			,e.extend_data.value('(/LotDataCommon/TotalUnknowQty)[1]', 'int') AS TotalUnknowQty
			,e.extend_data.value('(/LotDataCommon/ProgramName)[1]', 'varchar(max)') AS ProgramName
			,e.extend_data.value('(/LotDataCommon/TesterType)[1]', 'varchar(max)') AS TesterType
			,e.extend_data.value('(/LotDataCommon/ChannelATesterNo)[1]', 'varchar(max)') AS ChannelATesterNo
			,e.extend_data.value('(/LotDataCommon/Remark)[1]', 'varchar(max)') AS Remark
			,sbl.sbl_upper_limit
			,m.name AS handler
			,e.extend_data
		FROM apcsprodb.trans.lots AS l WITH (NOLOCK)
		INNER JOIN apcsprodb.method.device_names AS d WITH (NOLOCK) ON d.id = l.act_device_name_id
		INNER JOIN apcsprodb.method.packages AS p WITH (NOLOCK) ON p.id = d.package_id
		INNER JOIN apcsprodb.method.device_slips AS s WITH (NOLOCK) ON s.device_slip_id = l.device_slip_id
			AND s.is_sblsyl_approved BETWEEN 1
				AND 9
		INNER JOIN apcsprodb.method.device_flows AS f WITH (NOLOCK) ON f.device_slip_id = s.device_slip_id
			AND f.is_sblsyl = 1
		INNER JOIN apcsprodb.method.jobs AS j WITH (NOLOCK) ON j.id = f.job_id
		LEFT OUTER JOIN apcsprodb.method.device_flows_sblsyl AS sbl WITH (NOLOCK) ON sbl.device_flow_id = f.id
		INNER JOIN apcsprodb.trans.lot_process_records AS r WITH (NOLOCK) ON r.lot_id = l.id
			AND r.record_class = 2
			AND r.job_id = f.job_id
		INNER JOIN apcsprodb.mc.machines AS m WITH (NOLOCK) ON m.id = r.machine_id
		INNER JOIN apcsprodb.trans.lot_extend_records AS e WITH (NOLOCK) ON e.id = r.id
		WHERE l.wip_state = 100
			AND r.recorded_at >= @test_date_from
			AND r.recorded_at < @test_date_to
		) AS t1
	ORDER BY t1.recorded_at
END
