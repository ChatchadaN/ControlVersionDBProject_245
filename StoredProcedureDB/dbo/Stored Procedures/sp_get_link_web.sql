-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_link_web]
	-- Add the parameters for the stored procedure here
	@keyword varchar(30) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT ID as id
		, Title as title
		, CreateTime as createtime
		, Creater as creater
		, Link as link
		, KeyWord as keyword
	FROM DBx.SES.Link
	WHERE KeyWord LIKE '%' + @keyword + '%'

END
