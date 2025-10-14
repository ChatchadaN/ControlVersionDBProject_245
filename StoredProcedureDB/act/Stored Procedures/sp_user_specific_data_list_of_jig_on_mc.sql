
CREATE PROCEDURE [act].[sp_user_specific_data_list_of_jig_on_mc] (
	@date_from DATETIME
	,@date_to DATETIME
	,@jig_category INT
	)
AS
BEGIN
	--DECLARE @date_from DATETIME = '2022-10-01'
	--DECLARE @date_to DATETIME = '2022-10-10'
	--DECLARE @jig_category NVARCHAR(max) = 'Capillary'
	SELECT jc.id AS jig_category_id
		,jc.name AS jig_category_name
		,jr.transaction_type
		,jp.name AS jig_name
		,j.barcode
		,g.name AS machine_group_name
		,md.name AS machine_model_name
		,m.name AS machine_name
		,jr.record_at
	FROM apcsprodb.jig.categories AS jc WITH (NOLOCK)
	LEFT OUTER JOIN apcsprodb.jig.productions AS jp WITH (NOLOCK) ON jp.category_id = jc.id
	LEFT OUTER JOIN apcsprodb.trans.jig_records AS jr WITH (NOLOCK) ON jr.jig_production_id = jp.id
	LEFT OUTER JOIN apcsprodb.trans.jigs AS j WITH (NOLOCK) ON j.id = jr.jig_id
	LEFT OUTER JOIN apcsprodb.mc.machines AS m WITH (NOLOCK) ON m.name = jr.mc_no
	LEFT OUTER JOIN apcsprodb.mc.group_models AS gm WITH (NOLOCK) ON gm.machine_model_id = m.machine_model_id
	LEFT OUTER JOIN apcsprodb.mc.models AS md WITH (NOLOCK) ON md.id = gm.machine_model_id
	LEFT OUTER JOIN apcsprodb.mc.groups AS g WITH (NOLOCK) ON g.id = gm.machine_group_id
	WHERE jr.record_at BETWEEN @date_from
			AND @date_to
		AND jc.id = @jig_category
		AND jr.transaction_type = 'On Machine'
	ORDER BY jc.name
		,g.name DESC
		,m.name
		,jr.record_at
END
