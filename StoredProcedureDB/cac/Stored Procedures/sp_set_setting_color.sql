-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE cac.sp_set_setting_color
	-- Add the parameters for the stored procedure here
	@color_name varchar(50)
	, @color_code varchar(7)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE [APCSProDWH].[cac].[setting_color]
	SET [color_code] = @color_code
	WHERE [color_name] = @color_name
END
