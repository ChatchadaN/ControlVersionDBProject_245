-- =============================================
-- Author:		<Tun,,Norapat>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [clms].[get_user_email]
(
	-- Add the parameters for the function here
	@user_id int
)
RETURNS varchar(50)
AS
BEGIN
	DECLARE @email VARCHAR(50)
	SET @email = (SELECT [mail_address] FROM [APCSProDB].[man].[users] WITH (ROWLOCK) WHERE [id] = @user_id);
    RETURN @email
END
