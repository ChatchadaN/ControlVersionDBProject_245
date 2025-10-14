
create PROCEDURE [act].[sp_get_device_type]
AS
BEGIN
	SELECT val AS id
		,label_eng AS value_eng
		,label_jpn AS value_jpn
	FROM APCSProDB.method.item_labels
	WHERE name = 'device_versions.device_type'
END