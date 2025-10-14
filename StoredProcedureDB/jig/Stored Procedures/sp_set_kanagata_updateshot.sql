-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_kanagata_updateshot]
	@kanagataNo varchar(50),
	@shotcounter int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	Declare @root_id3 as int
	SET @root_id3 = (select  APCSProDB.trans.jigs.id from APCSProDB.trans.jigs where APCSProDB.trans.jigs.qrcodebyuser = @kanagataNo )

	update APCSProDB.trans.jig_conditions 
	SET [value] = [value] + @shotcounter
	where jig_conditions.id in(select jig_conditions.id
	from APCSProDB.trans.jigs INNER JOIN APCSProDB.trans.jig_conditions on jigs.id = jig_conditions.id 
	where jigs.id <> @root_id3 and root_jig_id = @root_id3)

END
