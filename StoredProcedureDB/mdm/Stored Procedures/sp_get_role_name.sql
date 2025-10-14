-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_role_name]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		SELECT [id]
			,[name] AS role_name
			,[created_at]
			,[created_by]
			,[updated_at]
			,[updated_by]
		FROM[APCSProDB].[man].[roles]
		where name LIKE '%OP' or name in ('DISABLEDPERSON','UserCtrlLicense','UserCalibration') order by role_name
	END
END
