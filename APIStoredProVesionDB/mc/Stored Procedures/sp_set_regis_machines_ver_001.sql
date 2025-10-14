-- =============================================
-- Author:		Nutchanat K.
-- Create date: 30/07/2025
-- Description:	Add new Machine
-- =============================================
CREATE PROCEDURE [mc].[sp_set_regis_machines_ver_001] 
			@headquarter_id AS INT
			,@name AS  varchar (30)
			,@short_name1 AS varchar (20)
			,@short_name2 AS varchar (20) =NULL
			,@barcode AS varchar (20) =NULL
			,@machine_model_id AS INT =NULL
			,@cell_ip AS varchar (15) =NULL
			,@machine_ip1 AS varchar (15) =NULL
			,@machine_ip2 AS varchar (15) =NULL
			,@terminal_ip AS varchar (15) =NULL
			,@display_size AS varchar (10) =NULL
			,@location_id AS INT =NULL
			,@machine_arrived AS date 
			,@serial_no  AS nvarchar (20) =NULL
			,@acc_location_id AS INT =NULL
			,@machine_level AS int =NULL
			,@is_fictional AS BIT =NULL
			,@connectable_number AS tinyint =NULL
			,@cell_num  AS tinyint =NULL
			,@is_disabled AS BIT =NULL
			,@code_for_strip char(2) =NULL
			,@application_set_id AS INT =NULL
			,@emp_code AS varchar (6) =NULL
			--,@updated_at AS datetime =NULL
			--,@updated_by AS INT =NULL
 --     @is_disabled AS BIT
	--,@update_by AS varchar(6)
	--,@headquarter_id AS INT
	--,@name AS varchar(30)
	--,@machine_model_id AS INT
	--,@cell_ip AS varchar(15)
	--,@machine_ip1 AS varchar(15)
	--,@is_automotive AS BIT
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @emp_id INT


	SELECT @emp_id = id FROM [10.29.1.230].[DWH].[man].[employees] WHERE emp_code = @emp_code


    -- Insert statements for procedure here
 	BEGIN TRANSACTION
	BEGIN TRY

	IF EXISTS (SELECT  'xx' FROM  [DWH].[mc].[machines] WHERE  [headquarter_id] = @headquarter_id and [name] = @name )
	BEGIN  

				SELECT	  'FALSE'		AS Is_Pass
				, 'Data Duplicate'		AS Error_Message_ENG
				, N'ข้อมูลนี้ลงทะเบียนแล้ว'		AS Error_Message_THA	
				, ''					AS Handling

				RETURN

	END 
	ELSE
	

		BEGIN

			DECLARE @new_id INT;
			
				INSERT INTO [DWH].[mc].[machines]
				   ([headquarter_id]
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
					,[application_set_id]
					,[created_at]
					,[created_by]
					--,[updated_at]
					--,[updated_by]
					)
				VALUES (
				 @headquarter_id 
				,@name 
				,@short_name1 
				,@short_name2 
				,@barcode 
				,@machine_model_id 
				,@cell_ip 
				,@machine_ip1 
				,@machine_ip2 
				,@terminal_ip 
				,@display_size 
				,@location_id 
				,@machine_arrived 
				,@serial_no  
				,@acc_location_id 
				,@machine_level 
				,@is_fictional 
				,@connectable_number 
				,@cell_num  
				,@is_disabled 
				,@code_for_strip 
				,@application_set_id 
				,GETDATE()
				,@emp_id
				--,GETDATE()
				--,@updated_by
				)

			SET @new_id = SCOPE_IDENTITY();

			INSERT INTO [DWH].[mc_hist].[machines_hist]
			([category],[id],[headquarter_id],[name],[short_name1],[short_name2],[barcode],[machine_model_id] ,[cell_ip],[machine_ip1],[machine_ip2],[terminal_ip],[display_size] ,[location_id],[machine_arrived] ,[serial_no] ,[acc_location_id] ,[machine_level] ,[is_fictional],[connectable_number]
			,[cell_num],[is_disabled] ,[code_for_strip],[application_set_id],[created_at] ,[created_by])
			
			VALUES 
			(1,@new_id,@headquarter_id ,@name ,@short_name1 ,@short_name2 ,@barcode ,@machine_model_id ,@cell_ip ,@machine_ip1 ,@machine_ip2 ,@terminal_ip ,@display_size,@location_id ,@machine_arrived ,@serial_no ,@acc_location_id ,@machine_level 
			,@is_fictional ,@connectable_number ,@cell_num ,@is_disabled ,@code_for_strip ,@application_set_id ,GETDATE(),@emp_id)


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