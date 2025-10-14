-- =============================================
-- Author:		Apichaya Sazuzao
-- Create date: 17/07/2025
-- Description:	insert data lebel_shipment_logo
-- =============================================
CREATE PROCEDURE [method].[sp_set_label_shipment_logo_ver_001_TEST] 
	 
      @value			INT,
      @description		VARCHAR(MAX),
      @file_extension	VARCHAR(5),
      @picture_data		nvarchar(MAX),
	  @emp_code			nvarchar(6)=null
	  
	  
      --@created_at		DATETIME,
      --@created_by		INT,
      --@updated_at		DATETIME,
      --@updated_by		INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- DECLARE @BinaryData VARBINARY(MAX);
    -- SET @BinaryData = cast( @picture_data AS VARBINARY(MAX));
	declare @parameter NVARCHAR(MAX) = N'@value INT	,
      @description		VARCHAR(MAX),
      @file_extension	VARCHAR(5),
      @picture_data		nvarchar(MAX),
	  @emp_id		INT'
	  
   BEGIN TRANSACTION
	BEGIN TRY
		DECLARE @emp_id int
		SELECT @emp_id = id from [DWH].[man].[employees]
		where   emp_code = @emp_code

		DECLARE @SQL NVARCHAR(MAX);
		-- check if exists
		IF EXISTS 
		(
            SELECT 1
            FROM [APCSProDBFile].[method].[label_shipment_logo] 
            WHERE [value] = @value
        )
        BEGIN
            -- ถ้ามีอยู่แล้ว ให้ส่งข้อความว่าไม่สามารถบันทึกได้
           
			SET @SQL = N'
    UPDATE [APCSProDBFile].[method].[label_shipment_logo]
    SET 
        [description] = '''+@description+''',
        file_extension = '''+@file_extension+''',
        picture_data =  '+@picture_data+',
        updated_at = GETDATE(),
        updated_by = '+CAST(@emp_id as varchar)+' 
    WHERE value = '+CAST(@value as varchar)+';';

EXEC sp_executesql @SQL;--,@parameter,@description=@description,@file_extension = @file_extension,@picture_data=@picture_data,@emp_id=@emp_id,@value=@value;
	COMMIT;

            SELECT 'TRUE' AS Is_Pass,
                   'Update Success.' AS Error_Message_ENG,
                   N'อัพเดทข้อมูลสำเร็จ' AS Error_Message_THA,
                   '' AS Handling;
            RETURN;
        END
		ELSE
		BEGIN
		-- insert data into [APCSProDBFile].[method].[label_shipment_logo] 
		
		SET @SQL = N'INSERT INTO [APCSProDBFile].[method].[label_shipment_logo]
					( [value]
							, [description]
							, [file_extension]
							, [picture_data]
							, [created_at]
							, [created_by])
					VALUES (' + CAST(@value as varchar) +  ',''' + @description + ''','''+ @file_extension + ''','+ @picture_data + N', GETDATE(), '+CAST(@emp_id as varchar) +' );';
		EXEC sp_executesql @SQL;
	
		SELECT    'TRUE'			AS Is_Pass 
				, 'Success'			AS Error_Message_ENG
				, N'บันทึกสำเร็จ'		AS Error_Message_THA	
				, ''				AS Handling
		COMMIT; 
		Print @sql
		RETURN
		END
	END TRY
	BEGIN CATCH
		ROLLBACK;

		SELECT    'FALSE'					AS Is_Pass 
				-- , 'Recording fail. !!'		AS Error_Message_ENG
				, ERROR_MESSAGE()	AS Error_Message_ENG
				, N'การบันทึกผิดพลาด !!'		AS Error_Message_THA
				, ''						AS Handling

		RETURN
	
	END CATCH
END
