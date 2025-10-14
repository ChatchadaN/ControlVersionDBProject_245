-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_kanagata_max_checking]
	@kanagata varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @rootId as int
	set @rootId = (select id from APCSProDB.trans.jigs where qrcodebyuser = @kanagata)

	SELECT         APCSProDB. jig.productions.name AS basetype, MAX( APCSProDB. trans.jig_conditions.value) AS LifeTimeMax
	FROM           APCSProDB. trans.jigs INNER JOIN
                          APCSProDB. trans.jig_conditions ON  APCSProDB. trans.jigs.id =  APCSProDB. trans.jig_conditions.id INNER JOIN
                         APCSProDB.  jig.productions ON  APCSProDB. trans.jigs.jig_production_id =  APCSProDB. jig.productions.id
	WHERE        ( APCSProDB. trans.jigs.root_jig_id = @rootId) AND ( APCSProDB. trans.jigs.id <> @rootId)
	GROUP BY  APCSProDB. jig.productions.name
	ORDER BY  APCSProDB. jig.productions.name DESC

END
