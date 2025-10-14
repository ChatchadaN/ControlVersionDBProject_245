-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_mdm_edit_user] 
	-- Add the parameters for the stored procedure here
	@emp_ID as int , @updated_by as int,  -- <=== Argument for procedure

	@name as NVARCHAR(50), @full_name as NVARCHAR(50), @english_name as VARCHAR(50), @emp_num as VARCHAR(10), @default_language as VARCHAR(5) = '', @extension as VARCHAR(10) = '', @fax_num as VARCHAR(10) = '',
	@email as VARCHAR(50) = '', @lockout as TINYINT, @emp_code1 as VARCHAR(10) = '', @emp_code2 as VARCHAR(10) = '', @picture_data as VARBINARY(MAX) = NULL, @password as VARCHAR(20) = '',
	@expired_on as DATE null, @is_admin as TINYINT, @operator_group as VARCHAR(5) = '' -- Data for table
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION
			BEGIN TRY
				IF (@picture_data IS NOT NULL)
				BEGIN
					UPDATE [APCSProDB].[man].[users]
					SET
					full_name = @full_name,
					name = @name,
					english_name = @english_name,
					emp_num = @emp_num,
					[default_language] = @default_language,
					[extension] = @extension,
					[fax_num] = @fax_num,
					[mail_address] = @email,
					[lockout] = @lockout,
					[emp_code1] = @emp_code1,
					[emp_code2] = @emp_code2,
					[picture_data] = @picture_data,
					[password] = @password,
					[expired_on] = @expired_on,
					[is_admin] = @is_admin,
					[operator_group] = @operator_group,
					[updated_at] = GETDATE(),
					[updated_by] = @updated_by
					WHERE id = @emp_ID
				END

				ELSE IF (@picture_data IS NULL)
				BEGIN
					UPDATE [APCSProDB].[man].[users]
					SET
					full_name = @full_name,
					name = @name,
					english_name = @english_name,
					emp_num = @emp_num,
					[default_language] = @default_language,
					[extension] = @extension,
					[fax_num] = @fax_num,
					[mail_address] = @email,
					[lockout] = @lockout,
					[emp_code1] = @emp_code1,
					[emp_code2] = @emp_code2,
					[password] = @password,
					[expired_on] = @expired_on,
					[is_admin] = @is_admin,
					[operator_group] = @operator_group,
					[updated_at] = GETDATE(),
					[updated_by] = @updated_by
					WHERE id = @emp_ID
				END

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
					  2 --is update
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
				WHERE [id] = @emp_ID
				-- user hist

				COMMIT;
			END TRY
			BEGIN CATCH
				ROLLBACK;
				SELECT 'FALSE' AS Is_Pass, ERROR_MESSAGE()
			END CATCH

END

