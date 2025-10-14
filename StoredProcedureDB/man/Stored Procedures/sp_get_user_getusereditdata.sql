
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_user_getusereditdata]
	-- Add the parameters for the stored procedure here
	
	@state INT, 
	@userid INT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @state = 0 --Finduser
	BEGIN
		   SELECT [id]
		   ,[name]
		   ,[full_name]
		   ,[name]
		   ,[english_name]
		   ,[emp_num]
		   ,[default_language]
		   ,[extension]
		   ,[fax_num]
		   ,[mail_address]
		   ,[lockout]
		   ,[emp_code1]
		   ,[emp_code2]
		   ,[password]
		   ,[expired_on]
		   ,[is_admin]
		   ,[operator_group]
		   ,[updated_at]
		   ,[picture_data]
		 FROM [APCSProDB].[man].[users]
		 where id = @userid
	
	END
	
	ELSE IF @state = 1 	--Findoperator_group

	BEGIN

		SELECT [label_eng] FROM [APCSProDB].[man].[item_labels] 
		WHERE name = 'users.operator_group'
                       
	END
END;