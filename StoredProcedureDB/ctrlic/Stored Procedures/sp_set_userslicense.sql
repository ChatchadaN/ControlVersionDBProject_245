-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [ctrlic].[sp_set_userslicense]
	-- Add the parameters for the stored procedure here
	@lic_id	AS INT
	, @user_id AS INT
	, @start_date AS DATETIME
	, @stop_date AS DATETIME
	, @is_active AS INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	INSERT INTO [APCSProDB].[ctrlic].[user_lic]
    (lic_id,user_id,start_date,stop_date,is_active)
    VALUES(@lic_id, @user_id , @start_date, @stop_date, @is_active)
END
