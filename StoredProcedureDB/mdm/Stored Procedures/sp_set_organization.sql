-- =============================================
-- Author:		<Author,,Name>
-- Create date: <03/03/2021,,>
-- Description:	<MDM ORGANIZATION,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_organization]
	-- Add the parameters for the stored procedure here
	@table_name int = 0, --1 = division,2 = department,3 = section
	@id int = 0,
	@name varchar(50) = '',
	@short_name varchar(20) = '',
	@id_link int = 0, -- id of headquarter_id or division_id or department_id
	@updated_by varchar(5) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	BEGIN TRY  
		-- Start
		IF @id != 0
		BEGIN
		------------------------------------------------------------------
			IF @table_name = 1
			BEGIN
				---division
				-- division table
				UPDATE [APCSProDB].[man].[divisions]
					SET [name] = @name
						,[short_name] = @short_name
						,[headquarter_id] = @id_link
						,[updated_at] = GETDATE()
						,[updated_by] = @updated_by
				WHERE [id] = @id;

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
				SELECT 2,[id],[name],[short_name],[headquarter_id],NULL,[created_at],[created_by],[updated_at],[updated_by]
				FROM [APCSProDB].[man].[divisions]
				WHERE [id] = @id
				
				---division
			END
			ELSE IF @table_name = 2
			BEGIN
				--department
				-- department table
				UPDATE [APCSProDB].[man].[departments]
					SET [name] = @name
						,[short_name] = @short_name
						,[division_id] = @id_link
						,[updated_at] = GETDATE()
						,[updated_by] = @updated_by
				WHERE [id] = @id;

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
				SELECT 2,[id],[name],[short_name],[division_id],[created_at],[created_by],[updated_at],[updated_by]
				FROM [APCSProDB].[man].[departments]
				WHERE [id] = @id
				--department
			END
			ELSE IF @table_name = 3
			BEGIN
				--section
				-- section table
				UPDATE [APCSProDB].[man].[sections]
					SET [name] = @name
						,[short_name] = @short_name
						,[department_id] = @id_link
						,[updated_at] = GETDATE()
						,[updated_by] = @updated_by
				WHERE [id] = @id;

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
				SELECT 2,[id],[name],[short_name],[department_id],[created_at],[created_by],[updated_at],[updated_by]
				FROM [APCSProDB].[man].[sections]
				WHERE [id] = @id
				--section
			END

			SELECT 'TRUE' as Is_pass
				,ERROR_MESSAGE() AS ErrorMessage;
		------------------------------------------------------------------
		END
		-- End
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

