
CREATE PROCEDURE [act].[sp_get_trans_item_labels] @name VARCHAR(50) = NULL
AS
BEGIN
	--DECLARE @name VARCHAR(50) = 'machine_states.run_state'
	SELECT name
		,val
		,label_eng
		,label_jpn
		--,label_sub
		--,color_code
	FROM [APCSProDB].[trans].[item_labels] AS il WITH (NOLOCK)
	WHERE (
			@name IS NOT NULL
			AND il.name = @name
			)
		OR (@name IS NULL)
END
