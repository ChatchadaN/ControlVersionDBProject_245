-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_organization_in]
	-- Add the parameters for the stored procedure here
	@table_name int = 0, --1 = division,2 = department,3 = section
	--@id int = 0,
	@name varchar(20) = '',
	@short_name varchar(20) = '',
	@id_link int = 0, -- id of division_id or department_id
	@updated_by varchar(5) = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
		DECLARE @divisions_Id int = 0
		DECLARE @departments_Id int = 0
		DECLARE @sections_Id int = 0
		DECLARE @organizations_Id int = 0
		DECLARE @headquarters_Id int = 0
		DECLARE @r AS INT

		BEGIN TRY  
		------------------------------------------------------------------
			IF @table_name = 1
			BEGIN
				---division
				SET @divisions_Id = (select (id + 1) as id from APCSProDB.man.numbers where name = 'divisions.id')
				-- division table
				INSERT INTO [APCSProDB].[man].[divisions]
					([id]
					,[name]
					,[short_name]
					,[headquarter_id]
					,[is_production]
					,[created_at]
					,[created_by]
					,[updated_at]
					,[updated_by])
				VALUES
					(@divisions_Id
					,@name
					,@short_name
					,@id_link
					,NULL
					,GETDATE()
					,@updated_by
					,NULL
					,NULL)

				set @r = @@ROWCOUNT
				UPDATE [APCSProDB].[man].[numbers]
				SET  id = id + @r
				WHERE name = 'divisions.id' -- update [APCSProDB].[man].[numbers] column id row division.id

				-- division hist
				INSERT INTO [APCSProDB].[man_hist].[divisions_hist] 
					(category
					,id
					,name
					,short_name
					,headquarter_id
					,is_production
					,created_at
					,created_by
					,updated_at
					,updated_by) 
				SELECT 1,[id],[name],[short_name],[headquarter_id],NULL,[created_at],[created_by],[updated_at],[updated_by]
				FROM [APCSProDB].[man].[divisions]
				WHERE [id] = @divisions_Id
				---division

				-- add organization
				SET @organizations_Id = (select (id + 1) as id from APCSProDB.man.numbers where name = 'organizations.id')
				INSERT INTO [APCSProDB].[man].[organizations]
					([id]
					,[headquarter_id]
					,[division_id]
					,[department_id]
					,[section_id]
					,[created_at]
					,[created_by]
					,[updated_at]
					,[updated_by])
				VALUES 
					(@organizations_Id
					,@id_link
					,@divisions_Id
					,NULL
					,NULL
					,GETDATE()
					,@updated_by
					,NULL
					,NULL)

				-- organization hist
				INSERT INTO [APCSProDB].[man_hist].[organizations_hist] 
					([category]
					,[id]
					,[headquarter_id]
					,[division_id]
					,[department_id]
					,[section_id]
					,[created_at]
					,[created_by]
					,[updated_at]
					,[updated_by]) 
				SELECT 1
					,[id]
					,[headquarter_id]
					,[division_id]
					,[department_id]
					,[section_id]
					,[created_at]
					,[created_by]
					,[updated_at]
					,[updated_by]
				FROM [APCSProDB].[man].[organizations]
				WHERE [id] = @organizations_Id

				set @r = @@ROWCOUNT
				UPDATE [APCSProDB].[man].[numbers]
				SET  id = id + @r
				WHERE name = 'organizations.id' -- update [APCSProDB].[man].[numbers] column id row organization.id

			END
			ELSE IF @table_name = 2
			BEGIN
				--department
				SET @departments_Id = (select (id + 1) as id from APCSProDB.man.numbers where name = 'departments.id')
				-- department table
				INSERT INTO [APCSProDB].[man].[departments]
					([id]
					,[name]
					,[short_name]
					,[division_id]
					,[created_at]
					,[created_by]
					,[updated_at]
					,[updated_by])
				VALUES
					(@departments_Id
					,@name
					,@short_name
					,@id_link
					,GETDATE()
					,@updated_by
					,NULL
					,NULL)

				set @r = @@ROWCOUNT
				UPDATE [APCSProDB].[man].[numbers]
				SET  id = id + @r
				WHERE name = 'departments.id' -- update [APCSProDB].[man].[numbers] column id row department.id

				-- department hist
				INSERT INTO [APCSProDB].[man_hist].[departments_hist]
					(category
					,id
					,name
					,short_name
					,division_id
					,created_at
					,created_by
					,updated_at
					,updated_by) 
				SELECT 1,[id],[name],[short_name],[division_id],[created_at],[created_by],[updated_at],[updated_by]
				FROM [APCSProDB].[man].[departments]
				WHERE [id] = @departments_Id
				--department

				-- add organization
				SET @organizations_Id = (select (id + 1) as id from APCSProDB.man.numbers where name = 'organizations.id')
				SET @headquarters_Id = (SELECT [divisions].[headquarter_id]
										FROM [APCSProDB].[man].[departments]
										INNER JOIN [APCSProDB].[man].[divisions] on [departments].[division_id] = [divisions].[id]
										WHERE [departments].[id] = @departments_Id)
				INSERT INTO [APCSProDB].[man].[organizations]
					([id]
					,[headquarter_id]
					,[division_id]
					,[department_id]
					,[section_id]
					,[created_at]
					,[created_by]
					,[updated_at]
					,[updated_by])
				VALUES 
					(@organizations_Id
					,@headquarters_Id
					,NULL
					,@departments_Id
					,NULL
					,GETDATE()
					,@updated_by
					,NULL
					,NULL)

				-- organization hist
				INSERT INTO [APCSProDB].[man_hist].[organizations_hist] 
					([category]
					,[id]
					,[headquarter_id]
					,[division_id]
					,[department_id]
					,[section_id]
					,[created_at]
					,[created_by]
					,[updated_at]
					,[updated_by]) 
				SELECT 1
					,[id]
					,[headquarter_id]
					,[division_id]
					,[department_id]
					,[section_id]
					,[created_at]
					,[created_by]
					,[updated_at]
					,[updated_by]
				FROM [APCSProDB].[man].[organizations]
				WHERE [id] = @organizations_Id
				
				set @r = @@ROWCOUNT
				UPDATE [APCSProDB].[man].[numbers]
				SET  id = id + @r
				WHERE name = 'organizations.id' -- update [APCSProDB].[man].[numbers] column id row organization.id
			END
			ELSE IF @table_name = 3
			BEGIN
				--section
				SET @sections_Id = (select (id + 1) as id from APCSProDB.man.numbers where name = 'sections.id')
				-- section table
				INSERT INTO [APCSProDB].[man].[sections]
					([id]
					,[name]
					,[short_name]
					,[department_id]
					,[created_at]
					,[created_by]
					,[updated_at]
					,[updated_by])
				VALUES
					(@sections_Id
					,@name
					,@short_name
					,@id_link
					,GETDATE()
					,@updated_by
					,NULL
					,NULL)

				set @r = @@ROWCOUNT
				UPDATE [APCSProDB].[man].[numbers]
				SET  id = id + @r
				WHERE name = 'sections.id' -- update [APCSProDB].[man].[numbers] column id row section.id

				-- section hist
				INSERT INTO [APCSProDB].[man_hist].[sections_hist]
					(category
					,id
					,name
					,short_name
					,department_id
					,created_at
					,created_by
					,updated_at
					,updated_by) 
				SELECT 1,[id],[name],[short_name],[department_id],[created_at],[created_by],[updated_at],[updated_by]
				FROM [APCSProDB].[man].[sections]
				WHERE [id] = @sections_Id
				--section

				-- add organization
				SET @organizations_Id = (select (id + 1) as id from APCSProDB.man.numbers where name = 'organizations.id')
				SET @headquarters_Id = (SELECT [divisions].[headquarter_id]
										FROM [APCSProDB].[man].[sections]
										INNER JOIN [APCSProDB].[man].[departments] on [sections].[department_id] = [departments].[id]
										INNER JOIN [APCSProDB].[man].[divisions] on [departments].[division_id] = [divisions].[id]
										WHERE [sections].[id] = @sections_Id)
				INSERT INTO [APCSProDB].[man].[organizations]
					([id]
					,[headquarter_id]
					,[division_id]
					,[department_id]
					,[section_id]
					,[created_at]
					,[created_by]
					,[updated_at]
					,[updated_by])
				VALUES 
					(@organizations_Id
					,@headquarters_Id
					,NULL
					,NULL
					,@sections_Id
					,GETDATE()
					,@updated_by
					,NULL
					,NULL)

				-- organization hist
				INSERT INTO [APCSProDB].[man_hist].[organizations_hist] 
					([category]
					,[id]
					,[headquarter_id]
					,[division_id]
					,[department_id]
					,[section_id]
					,[created_at]
					,[created_by]
					,[updated_at]
					,[updated_by]) 
				SELECT 1
					,[id]
					,[headquarter_id]
					,[division_id]
					,[department_id]
					,[section_id]
					,[created_at]
					,[created_by]
					,[updated_at]
					,[updated_by]
				FROM [APCSProDB].[man].[organizations]
				WHERE [id] = @organizations_Id

				set @r = @@ROWCOUNT
				UPDATE [APCSProDB].[man].[numbers]
				SET  id = id + @r
				WHERE name = 'organizations.id' -- update [APCSProDB].[man].[numbers] column id row organization.id
			END

			SELECT 'TRUE' as Is_pass
				,ERROR_MESSAGE() AS ErrorMessage;
		------------------------------------------------------------------
	END TRY 
	BEGIN CATCH  
		SELECT 'FALSE' as Is_pass
            --,ERROR_NUMBER() AS ErrorNumber  
            --,ERROR_SEVERITY() AS ErrorSeverity  
            --,ERROR_STATE() AS ErrorState  
            --,ERROR_PROCEDURE() AS ErrorProcedure  
            --,ERROR_LINE() AS ErrorLine  
            ,ERROR_MESSAGE() AS ErrorMessage;  
	END CATCH  			
END

