-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon_menu].[sp_get_extend_clolumn]
	@type VARCHAR(5)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT master_tb.column_name, json_name, is_master
	FROM (
		SELECT column_name, [json_name]
			FROM [APCSProDB_lsi_110].[cellcon_menu].[lot_transactions_menu]
			WHERE [type] IN ('ALL', @type)
			AND [is_created] = 1
		UNION
		SELECT column_name, [json_name]
			FROM [APCSProDB_lsi_110].[cellcon_menu].[lot_extend_menu]
			WHERE [type] = @type
			AND [is_created] = 1
	) AS master_tb
	JOIN (
			SELECT c.name COLLATE Latin1_General_CI_AS as column_name, CASE WHEN t.name = 'lot_transactions' then 1 else 0 end as is_master
			FROM APCSProDWR.sys.tables t
			JOIN APCSProDWR.sys.columns c on t.object_id = c.object_id
			JOIN APCSProDWR.sys.schemas sc on T.schema_id = sc.schema_id
			WHERE t.name IN ('lot_extended','lot_transactions')
			AND sc.name = 'trans'
	) as tb ON master_tb.column_name = tb.column_name

END
