-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_rcs_records]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	--SELECT A.record_id, A.lot_no, A.location_id, B.name, B.address, A.update_at_in, A.update_at_out, A.status, A.updated_by_in, A.updated_by_out

	--FROM [DBx].[dbo].[rcs_records] AS A
	--INNER JOIN [APCSProDB].[trans].[locations] AS B ON A.location_id = B.id

	--WHERE update_at_out IS null

	--ORDER BY update_at_in desc
	----------------------------------------------------------------------------------------
	--modify query on 23/06/2022
	SELECT A.record_id, A.lot_no, A.location_id, B.name, B.address, A.update_at_in, A.update_at_out, A.status, A.updated_by_in, A.updated_by_out
	
	FROM [DBx].[dbo].[rcs_records] AS A
	INNER JOIN [APCSProDB].[trans].[locations] AS B ON A.location_id = B.id and A.update_at_out IS null

	ORDER BY update_at_in desc;
	----------------------------------------------------------------------------------------
END
