-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_rcs_rack_users]
	-- Add the parameters for the stored procedure here
	@OPNo varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	SELECT id, emp_num, name
	FROM [APCSProDB].[man].[users]
	WHERE emp_num like @OPNo
END
