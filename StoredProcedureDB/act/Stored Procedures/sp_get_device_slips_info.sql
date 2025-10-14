
CREATE PROCEDURE [act].[sp_get_device_slips_info] (@device_id INT)
AS
BEGIN
	SELECT ds.device_slip_id AS device_slip_id,
		ds.device_id AS device_id,
		dd.name AS device_name,
		ds.version_num AS version_num,
		ds.package_slip_id AS package_slip_id,
		ds.tp_code AS tp_code,
		ds.os_program_name AS os_program_name,
		--ds.sub_rank AS sub_rank,
		--ds.temporary_char AS temporary_char,
		ds.comments AS comments,
		ds.is_released AS is_released,
		ds.normal_leadtime_minutes AS normal_leadtime_minutes,
		ds.lead_time_sum AS lead_time_sum,
		ds.created_at AS created_at,
		mu.name AS created_by,
		ds.updated_at AS updated_at,
		mu2.name AS updated_by
	FROM APCSProDB.method.device_slips AS ds WITH (NOLOCK)
	INNER JOIN APCSProDWH.dwh.dim_devices AS dd WITH (NOLOCK) ON dd.id = ds.device_id
	LEFT OUTER JOIN apcsprodb.man.users AS mu WITH (NOLOCK) ON mu.id = ds.created_by
	LEFT OUTER JOIN apcsprodb.man.users AS mu2 WITH (NOLOCK) ON mu2.id = ds.updated_by
	WHERE ds.device_id = @device_id
	ORDER BY ds.version_num;
END
