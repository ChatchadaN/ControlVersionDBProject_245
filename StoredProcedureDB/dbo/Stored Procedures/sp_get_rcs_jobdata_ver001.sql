-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_rcs_jobdata_ver001]
	-- Add the parameters for the stored procedure here
	@JobName1 varchar(20), @JobName2 varchar(20) = '', @JobName3 varchar(20) = '', @JobName4 varchar(20) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@JobName1 != '%' AND @JobName2 != '%' AND @JobName3 != '%' AND @JobName4 != '%' )
	BEGIN
		SELECT id, name
		FROM APCSProDB.method.jobs
		WHERE (name like @JobName1 or name like @JobName2 or name like @JobName3 or name like @JobName4 ) and name not like '%Lapis%' --and name not like '%INS%' 
		ORDER BY id
	END
	ELSE
	BEGIN
		SELECT id, name
		FROM APCSProDB.method.jobs
		--WHERE (name like @JobName1 or name like @JobName2) and name not like '%SBLSYL%' and name not like '%Lapis%' --and name not like '%INS%' 
		ORDER BY id
	END
END
