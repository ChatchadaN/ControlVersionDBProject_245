
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_edit_operations]
    @id INT,
    @op_name VARCHAR(50),
    @descriptions NVARCHAR(50),
    @app_name VARCHAR(20),
    @func_name VARCHAR(30),
    @parameter_1 VARCHAR(20),
    @updated_by INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
		--IF EXISTS (SELECT  'xx' FROM  [APCSProDB].[man].[operations] WHERE [name] = @op_name )
        IF NOT EXISTS (SELECT COUNT(*) FROM [APCSProDB].[man].[operations] WHERE [name] = @op_name)
        BEGIN
            SELECT 'FALSE' AS Is_Pass,
                   'Data Not Found' AS Error_Message_ENG,
                   N'ไม่พบข้อมูลการลงทะเบียน' AS Error_Message_THA,
                   '' AS Handling;
            ROLLBACK TRANSACTION;
            RETURN;
        END
        ELSE
        BEGIN
            UPDATE [APCSProDB].[man].[operations]
            SET [name] = @op_name,
                [descriptions] = @descriptions,
                [app_name] = @app_name,
                [function_name] = @func_name,
                [parameter_1] = @parameter_1,
                [updated_at] = GETDATE(),
                [updated_by] = @updated_by
            WHERE [id] = @id;

            SELECT 'TRUE' AS Is_Pass,
                   'Successed !!' AS Error_Message_ENG,
                   N'บันทึกข้อมูลเรียบร้อย.' AS Error_Message_THA,
                   '' AS Handling;

            COMMIT TRANSACTION;
            RETURN;
        END
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        SELECT 'FALSE' AS Is_Pass,
               'Update Failed !!' AS Error_Message_ENG,
               N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA,
               '' AS Handling;
    END CATCH
END