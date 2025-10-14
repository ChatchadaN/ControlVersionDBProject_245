-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_mdm_new_user]
	-- Add the parameters for the stored procedure here
	@updated_by as int,  -- <=== Login User try to update.
	@RequestStatus AS VARCHAR(15) OUTPUT, -- state send back to form

	@name as NVARCHAR(50), @full_name as NVARCHAR(50), @english_name as VARCHAR(50), @emp_num as VARCHAR(10), @default_language as VARCHAR(5) = '', @extension as VARCHAR(10) = '', @fax_num as VARCHAR(10) = '',
	@email as VARCHAR(50) = '', @lockout as TINYINT null, @emp_code1 as VARCHAR(10) = '', @emp_code2 as VARCHAR(10) = '', @picture_data as VARBINARY(MAX) = null, @password as VARCHAR(20) = '',
	@expired_on as DATE null, @is_admin as TINYINT null, @operator_group as VARCHAR(5) = '' -- Data for table
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @lastest_id_num AS INT = 0
	SET @lastest_id_num = (select MAX(id) + 1 from APCSProDB.man.users) --add to the last index of Man.users
		IF NOT EXISTS(SELECT emp_num FROM [APCSProDB].[man].[users] WHERE emp_num = @emp_num) --Check if emp_num not already exist
		BEGIN
				INSERT INTO [APCSProDB].[man].[users]
					([id]
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
					,[picture_data]
					,[password]
					,[expired_on]
					,[is_admin]
					,[operator_group]
					,[created_at]
					,[created_by]
				)
				VALUES
				(
					@lastest_id_num,
					@full_name,
					@name,
					@english_name,
					@emp_num,
					@default_language,
					@extension,
					@fax_num,
					@email,
					@lockout,
					@emp_code1,
					@emp_code2,
					@picture_data,
					@password,
					@expired_on,
					@is_admin,
					@operator_group,
					GETDATE(),
					@updated_by
				)

				DECLARE @r AS INT
				set @r = @@ROWCOUNT
				UPDATE [APCSProDB].[man].[numbers]
				SET  id = id + @r
				WHERE name = 'users.id' -- update [APCSProDB].[man].[numbers] column id row user.id

				-- user hist
				INSERT INTO [APCSProDB].[man_hist].[users_hist]
					([category]
					  ,[id]
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
					  ,[picture_data]
					  ,[password]
					  ,[expired_on]
					  ,[is_admin]
					  ,[operator_group]
					  ,[created_at]
					  ,[created_by]
					  ,[updated_at]
					  ,[updated_by]
				)
				SELECT 
					  1 --is insert
					  ,[id]
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
					  ,[picture_data]
					  ,[password]
					  ,[expired_on]
					  ,[is_admin]
					  ,[operator_group]
					  ,[created_at]
					  ,[created_by]
					  ,[updated_at]
					  ,[updated_by]
				FROM [APCSProDB].[man].[users]
				WHERE [id] = @lastest_id_num
				-- user hist

				SELECT @RequestStatus = 'PASS' --Form State
		END
		ELSE
		BEGIN
				IF EXISTS(SELECT emp_num FROM [APCSProDB].[man].[users] WHERE emp_num = @emp_num) --emp_num already exist
				BEGIN
					SELECT @RequestStatus = 'Duplicate' --Return 'Dubplicate' to C#
				END
		END
		
				
END