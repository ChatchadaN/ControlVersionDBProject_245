-- =============================================
-- Author:		Nutchanat K.
-- Create date: 30/07/2025
-- Description:	Add new Machine
-- =============================================
CREATE PROCEDURE [mc].[sp_set_model_ver_001]
	   @method AS INT --(1: Insert , 2: Update)
	  ,@id AS INT = 0
	  ,@name AS  varchar (30)
      ,@short_name AS  nvarchar (20)
      ,@headquarter_id AS INT
      ,@maker_id AS INT = NULL
      ,@process_type AS tinyint = NULL
      ,@map_using AS tinyint = NULL
      ,@map_type AS tinyint = NULL
      ,@bin_type AS tinyint = NULL
      ,@is_linked_with_work AS tinyint = NULL
      ,@enable_lot_max AS tinyint = NULL
      ,@ppid_type1  AS tinyint = NULL
      ,@ppid_type2  AS tinyint = NULL
      ,@is_carrier_register  AS tinyint = NULL
      ,@is_carrier_transfer  AS tinyint = NULL
      ,@is_carrier_verification_setup AS tinyint = NULL
      ,@is_carrier_verification_end   AS tinyint = NULL
      ,@limit_sec_for_carrierinput    AS INT = NULL
      ,@allowed_control_condition    AS tinyint = NULL
      ,@is_magazine_register AS tinyint = NULL
      ,@is_magazine_transfer AS tinyint = NULL
      ,@is_magazine_verification_setup AS tinyint = NULL
      ,@is_magazine_verification_end AS tinyint = NULL
      ,@limit_sec_for_magazineinput AS INT = NULL
      ,@wafer_map_using AS tinyint = NULL
      ,@wafer_map_type AS tinyint = NULL
      ,@wafer_map_bin_type AS tinyint = NULL
	  ,@emp_code AS varchar (6)  = NULL

	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @emp_id INT


	SELECT @emp_id = id FROM [10.29.1.230].[DWH].[man].[employees] WHERE emp_code = @emp_code

	IF (@method =  1) --Insert
	BEGIN

    -- Insert statements for procedure here
 	BEGIN TRANSACTION
	BEGIN TRY

	IF EXISTS (SELECT  'xx' FROM  [DWH].[mc].[models] WHERE  [headquarter_id] = @headquarter_id and [name] = @name )
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

				INSERT INTO [DWH].[mc].[models]
				   ([name]
					 ,[short_name]
					 ,[headquarter_id]
					 ,[maker_id]
					 ,[process_type]
					 ,[map_using]
					 ,[map_type]
					 ,[bin_type]
					 ,[is_linked_with_work]
					 ,[enable_lot_max]
					 ,[ppid_type1]
					 ,[ppid_type2]
					 ,[is_carrier_register]
					 ,[is_carrier_transfer]
					 ,[is_carrier_verification_setup]
					 ,[is_carrier_verification_end]
					 ,[limit_sec_for_carrierinput]
					 ,[allowed_control_condition]
					 ,[is_magazine_register]
					 ,[is_magazine_transfer]
					 ,[is_magazine_verification_setup]
					 ,[is_magazine_verification_end]
					 ,[limit_sec_for_magazineinput]
					 ,[wafer_map_using]
					 ,[wafer_map_type]
					 ,[wafer_map_bin_type]
					 ,[created_at]
					 ,[created_by]
					--,[updated_at]
					--,[updated_by]
					)
				VALUES (
				@name
				,@short_name
				,@headquarter_id 
				,@maker_id  
				,@process_type  
				,@map_using  
				,@map_type  
				,@bin_type  
				,@is_linked_with_work  
				,@enable_lot_max  
				,@ppid_type1 
				,@ppid_type2 
				,@is_carrier_register 
				,@is_carrier_transfer 
				,@is_carrier_verification_setup  
				,@is_carrier_verification_end  
				,@limit_sec_for_carrierinput 
				,@allowed_control_condition 
				,@is_magazine_register  
				,@is_magazine_transfer  
				,@is_magazine_verification_setup  
				,@is_magazine_verification_end  
				,@limit_sec_for_magazineinput  
				,@wafer_map_using  
				,@wafer_map_type  
				,@wafer_map_bin_type  
				,GETDATE()
				,@emp_id
				--,GETDATE()
				--,@updated_by
				)

		SET @new_id = SCOPE_IDENTITY();

			INSERT INTO [DWH].[mc_hist].[models_hist]
			([category]
           ,[id]
           ,[name]
           ,[short_name]
           ,[headquarter_id]
           ,[maker_id]
           ,[process_type]
           ,[map_using]
           ,[map_type]
           ,[bin_type]
           ,[is_linked_with_work]
           ,[enable_lot_max]
           ,[ppid_type1]
           ,[ppid_type2]
           ,[is_carrier_register]
           ,[is_carrier_transfer]
           ,[is_carrier_verification_setup]
           ,[is_carrier_verification_end]
           ,[limit_sec_for_carrierinput]
           ,[allowed_control_condition]
           ,[is_magazine_register]
           ,[is_magazine_transfer]
           ,[is_magazine_verification_setup]
           ,[is_magazine_verification_end]
           ,[limit_sec_for_magazineinput]
           ,[wafer_map_using]
           ,[wafer_map_type]
           ,[wafer_map_bin_type]
           ,[created_at]
           ,[created_by])
			
			VALUES 
			(1 
				,@new_id,@name
				,@short_name
				,@headquarter_id 
				,@maker_id  
				,@process_type  
				,@map_using  
				,@map_type  
				,@bin_type  
				,@is_linked_with_work  
				,@enable_lot_max  
				,@ppid_type1 
				,@ppid_type2 
				,@is_carrier_register 
				,@is_carrier_transfer 
				,@is_carrier_verification_setup  
				,@is_carrier_verification_end  
				,@limit_sec_for_carrierinput 
				,@allowed_control_condition 
				,@is_magazine_register  
				,@is_magazine_transfer  
				,@is_magazine_verification_setup  
				,@is_magazine_verification_end  
				,@limit_sec_for_magazineinput  
				,@wafer_map_using  
				,@wafer_map_type  
				,@wafer_map_bin_type 
				,GETDATE()
				,@emp_id)


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

	ELSE

	IF (@method =  2) --Update
	BEGIN



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
			
						UPDATE [DWH].[mc].[models]
						SET	 
							[name]=COALESCE(@name,[name])
							,[short_name]=COALESCE(@short_name ,[short_name])
							,[headquarter_id]=COALESCE(@headquarter_id ,[headquarter_id])
							,[maker_id]=COALESCE(@maker_id ,[maker_id])
							,[process_type]=COALESCE(@process_type ,[process_type])
							,[map_using]=COALESCE(@map_using ,[map_using])
							,[map_type]=COALESCE(@map_type ,[map_type])
							,[bin_type]=COALESCE(@bin_type ,[bin_type])
							,[is_linked_with_work]=COALESCE(@is_linked_with_work ,[is_linked_with_work])
							,[enable_lot_max]=COALESCE(@enable_lot_max ,[enable_lot_max])
							,[ppid_type1]=COALESCE(@ppid_type1 ,[ppid_type1])
							,[ppid_type2]=COALESCE(@ppid_type2 ,[ppid_type2])
							,[is_carrier_register]=COALESCE(@is_carrier_register ,[is_carrier_register])
							,[is_carrier_transfer]=COALESCE(@is_carrier_transfer ,[is_carrier_transfer])
							,[is_carrier_verification_setup]=COALESCE(@is_carrier_verification_setup ,[is_carrier_verification_setup])
							,[is_carrier_verification_end]=COALESCE(@is_carrier_verification_end ,[is_carrier_verification_end])
							,[limit_sec_for_carrierinput]=COALESCE(@limit_sec_for_carrierinput ,[limit_sec_for_carrierinput])
							,[allowed_control_condition]=COALESCE(@allowed_control_condition ,[allowed_control_condition])
							,[is_magazine_register]=COALESCE(@is_magazine_register ,[is_magazine_register])
							,[is_magazine_transfer]=COALESCE(@is_magazine_transfer ,[is_magazine_transfer])
							,[is_magazine_verification_setup]=COALESCE(@is_magazine_verification_setup ,[is_magazine_verification_setup])
							,[is_magazine_verification_end]=COALESCE(@is_magazine_verification_end ,[is_magazine_verification_end])
							,[limit_sec_for_magazineinput]=COALESCE(@limit_sec_for_magazineinput ,[limit_sec_for_magazineinput])
							,[wafer_map_using]=COALESCE(@wafer_map_using ,[wafer_map_using])
							,[wafer_map_type]=COALESCE(@wafer_map_type ,[wafer_map_type])
							,[wafer_map_bin_type]=COALESCE(@wafer_map_bin_type ,[wafer_map_bin_type])
							,[updated_at] = GETDATE() 
							,[updated_by] = @emp_id
							WHERE id = @id

					INSERT INTO [DWH].[mc_hist].[models_hist]
						([category]
							 ,[id]
							 ,[name]
							 ,[short_name]
							 ,[headquarter_id]
							 ,[maker_id]
							 ,[process_type]
							 ,[map_using]
							 ,[map_type]
							 ,[bin_type]
							 ,[is_linked_with_work]
							 ,[enable_lot_max]
							 ,[ppid_type1]
							 ,[ppid_type2]
							 ,[is_carrier_register]
							 ,[is_carrier_transfer]
							 ,[is_carrier_verification_setup]
							 ,[is_carrier_verification_end]
							 ,[limit_sec_for_carrierinput]
							 ,[allowed_control_condition]
							 ,[is_magazine_register]
							 ,[is_magazine_transfer]
							 ,[is_magazine_verification_setup]
							 ,[is_magazine_verification_end]
							 ,[limit_sec_for_magazineinput]
							 ,[wafer_map_using]
							 ,[wafer_map_type]
							 ,[wafer_map_bin_type]
							 ,[created_at]
							 ,[created_by]
							 ,[updated_at]
							 ,[updated_by])
					SELECT 2 
							,[id]
							,[name]
							,[short_name]
							,[headquarter_id]
							,[maker_id]
							,[process_type]
							,[map_using]
							,[map_type]
							,[bin_type]
							,[is_linked_with_work]
							,[enable_lot_max]
							,[ppid_type1]
							,[ppid_type2]
							,[is_carrier_register]
							,[is_carrier_transfer]
							,[is_carrier_verification_setup]
							,[is_carrier_verification_end]
							,[limit_sec_for_carrierinput]
							,[allowed_control_condition]
							,[is_magazine_register]
							,[is_magazine_transfer]
							,[is_magazine_verification_setup]
							,[is_magazine_verification_end]
							,[limit_sec_for_magazineinput]
							,[wafer_map_using]
							,[wafer_map_type]
							,[wafer_map_bin_type]
							,[created_at]
							,[created_by]
							,[updated_at]
							,[updated_by]
						FROM  [DWH].[mc].[models]
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
END