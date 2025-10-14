-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [ctrlic].[sp_set_update_userslicense]
	-- Add the parameters for the stored procedure here
	@lic_id	AS INT
	, @user_id AS INT
	, @start_date AS DATETIME
	, @stop_date AS DATETIME 
	, @is_active  AS INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	UPDATE [APCSProDB].[ctrlic].[user_lic]
    SET start_date = @start_date, stop_date = @stop_date, is_active = @is_active 
    WHERE user_id = @user_id and lic_id = @lic_id
END
