
CREATE PROCEDURE [act].[sp_act_setting]
AS
BEGIN
	SELECT st.name
		,st.val
	FROM APCSProDWH.dwh.act_settings AS st WITH (NOLOCK)
	--man.factories にclosing_hourカラムが出来るまでは下記のように直設定
	UNION ALL
	
	SELECT 'closing_hour' AS name
		,CASE 
			WHEN st.val = '64646'
				THEN 8
			WHEN st.val = '65505'
				THEN 9
			ELSE 0
			END AS val
	FROM (
		SELECT val
		FROM APCSProDWH.dwh.act_settings AS st WITH (NOLOCK)
		WHERE st.name = 'FactoryCode'
		) AS st
END
