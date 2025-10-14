-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_alljobs_by_Process]
	-- Add the parameters for the stored procedure here
	@process varchar(20), @like varchar(20) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT *
	FROM APCSProDB.method.jobs AS a
	INNER JOIN APCSProDB.method.processes AS B ON A.process_id = B.id
	WHERE B.name = @process AND A.name like @like
END
