-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_temp_tp_ver_temp]
	-- Add the parameters for the stored procedure here
	@PKG VARCHAR(MAX) =''
	,@line int = 0 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@line != 0)
	BEGIN
		SELECT *
		FROM DBxDW.dbo.scheduler_temp_tp_01 as temp 
		INNER JOIN DBx.dbo.scheduler_tp_qa_mc_setup as tpsetup on tpsetup.mcid = temp.McId
		WHERE tpsetup.line = @line
	END
	ELSE 
	BEGIN
		select * 
		from DBxDW.dbo.scheduler_temp_tp_01 where PackageName in (SELECT * from STRING_SPLIT ( @PKG , ',' ))
	END
END
