-- =============================================
-- Author:		Nutchanat K.
-- Create date: 30/07/2025
-- Description:	Edit Machine
-- =============================================
CREATE PROCEDURE [mc].[sp_set_edit_machines_ver_001] 
			@id AS INT
			,@headquarter_id AS INT =NULL
			,@name AS  varchar (30) =NULL 
			,@short_name1 AS varchar (20) =NULL
			,@short_name2 AS varchar (20)  =NULL
			,@barcode AS varchar (20) =NULL
			,@machine_model_id AS INT =NULL
			,@cell_ip AS varchar (15) =NULL
			,@machine_ip1 AS varchar (15) =NULL
			,@machine_ip2 AS varchar (15) =NULL
			,@terminal_ip AS varchar (15) =NULL
			,@display_size AS varchar (10) =NULL
			,@location_id AS INT =NULL
			,@machine_arrived AS date =NULL
			,@serial_no  AS nvarchar (20) =NULL
			,@acc_location_id AS INT =NULL
			,@machine_level AS BIT =NULL
			,@is_fictional AS BIT =NULL
			,@connectable_number AS tinyint =NULL
			,@cell_num  AS tinyint =NULL
			,@is_disabled AS BIT =NULL
			,@code_for_strip char(2) =NULL
			,@emp_code AS varchar (6) =NULL
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @emp_id INT


	SELECT @emp_id = id FROM [10.29.1.230].[DWH].[man].[employees] WHERE emp_code = @emp_code

	--DECLARE @num_id INT;

    -- Insert statements for procedure here
 	BEGIN TRANSACTION
	BEGIN TRY

	IF NOT EXISTS (SELECT  'xx' FROM  [DWH].[mc].[machines] WHERE  id = @id )
	
	BEGIN  

					SELECT	  'FALSE'			AS Is_Pass
					, 'Data Not found'			AS Error_Message_ENG
					, N'ไม่พบข้อมูลการลงทะเบียน'		AS Error_Message_THA	
					, ''						AS Handling
					COMMIT;
					RETURN

	END 
	ELSE

		BEGIN
			
				UPDATE [DWH].[mc].[machines]
				SET	 
					 [headquarter_id] = COALESCE(@headquarter_id,[headquarter_id])
					,[name] = COALESCE(@name ,[name])
					,[short_name1] = COALESCE(@short_name1,[short_name1])
					,[short_name2] = COALESCE(@short_name2,[short_name2])
					,[barcode] = COALESCE(@barcode ,[barcode])
					,[machine_model_id] = COALESCE(@machine_model_id,[machine_model_id])
					,[cell_ip] = COALESCE(@cell_ip ,[cell_ip])
					,[machine_ip1] = COALESCE(@machine_ip1,[machine_ip1])
					,[machine_ip2] = COALESCE(@machine_ip2,[machine_ip2])
					,[terminal_ip] = COALESCE(@terminal_ip,[terminal_ip])
					,[display_size] = COALESCE(@display_size,[display_size])
					,[location_id] = COALESCE(@location_id,[location_id])
					,[machine_arrived] = COALESCE(@machine_arrived,[machine_arrived])
					,[serial_no] = COALESCE(@serial_no  ,[serial_no])
					,[acc_location_id] = COALESCE(@acc_location_id,[acc_location_id])
					,[machine_level] = COALESCE(@machine_level,[machine_level])
					,[is_fictional] = COALESCE(@is_fictional,[is_fictional])
					,[connectable_number] = COALESCE(@connectable_number,[connectable_number])
					,[cell_num] = COALESCE(@cell_num ,[cell_num])
					,[is_disabled] = COALESCE(@is_disabled,[is_disabled])
					,[code_for_strip] = COALESCE(@code_for_strip,[code_for_strip])
					--,[application_set_id] = COALESCE(@application,[application_set_id])
					--,[created_at] = COALESCE(@created_at ,[created_at])
					--,[created_by] = COALESCE(@created_by ,[created_by])
					--,[updated_at] = COALESCE(@updated_at ,[updated_at])
					--,[updated_by] = COALESCE(@updated_by ,[updated_by])
					,[updated_at] = GETDATE() 
					,[updated_by] = @emp_id
					WHERE id = @id
			INSERT INTO [DWH].[mc_hist].[machines_hist]
				([category]
					,[id]
					,[headquarter_id]
					,[name]
					,[short_name1]
					,[short_name2]
					,[barcode]
					,[machine_model_id]
					,[cell_ip]
					,[machine_ip1]
					,[machine_ip2]
					,[terminal_ip]
					,[display_size]
					,[location_id]
					,[machine_arrived]
					,[serial_no]
					,[acc_location_id]
					,[machine_level]
					,[is_fictional]
					,[connectable_number]
					,[cell_num]
					,[is_disabled]
					,[code_for_strip]
					,[created_at]
					,[created_by]
					,[updated_at]
					,[updated_by])
			SELECT 2 
					,[id]
					,[headquarter_id]
					,[name]
					,[short_name1]
					,[short_name2]
					,[barcode]
					,[machine_model_id]
					,[cell_ip]
					,[machine_ip1]
					,[machine_ip2]
					,[terminal_ip]
					,[display_size]
					,[location_id]
					,[machine_arrived]
					,[serial_no]
					,[acc_location_id]
					,[machine_level]
					,[is_fictional]
					,[connectable_number]
					,[cell_num]
					,[is_disabled]
					,[code_for_strip]
					,[created_at]
					,[created_by]
					,[updated_at]
					,[updated_by]
				FROM  [DWH].[mc].[machines]
				WHERE  id = @id

				SELECT	  'TRUE'				AS Is_Pass
						, 'Successed !!'		AS Error_Message_ENG
						, N'บันทึกข้อมูลเรียบร้อย.'	AS Error_Message_THA	
						, ''					AS Handling

				COMMIT; 

				RETURN
		END 
		END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT	  'FALSE'				AS Is_Pass
				, ERROR_MESSAGE()		AS Error_Message_ENG
				, N'บันทึกข้อมูลผิดพลาด !!'	AS Error_Message_THA
				, ''					AS Handling
	END CATCH
END