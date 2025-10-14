-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [ctrlic].[sp_get_licensetype]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT ref_id, [ref_desc] FROM [APCSProDB].[ctrlic].[ref_value]
    WHERE ref_id in (38, 123, 456, 457, 4280)
    group by[ref_desc], ref_id
END
