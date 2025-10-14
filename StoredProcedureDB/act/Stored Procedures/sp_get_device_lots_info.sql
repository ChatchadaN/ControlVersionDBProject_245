
CREATE PROCEDURE [act].[sp_get_device_lots_info] (@device_id INT)
AS
BEGIN
	SELECT t1.id AS id,
		t1.lot_no AS lot_no,
		t1.device_slip_id AS device_slip_id
	FROM (
		SELECT *
		FROM APCSProDB.trans.lots AS tl WITH (NOLOCK)
		WHERE device_slip_id IN (
				SELECT device_slip_id
				FROM APCSProDB.method.device_slips AS ds WITH (NOLOCK)
				WHERE ds.device_id = @device_id
				)
		) AS t1
	ORDER BY device_slip_id,
		step_no;
END
