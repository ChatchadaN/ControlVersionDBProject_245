-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_lapis_outsource_lot]
	-- Add the parameters for the stored procedure here
	@lotno AS VARCHAR(10),
	@package AS VARCHAR(255),
	@device AS VARCHAR(255),
	@qty AS INT,
	@frameqty AS INT,
	@carrier AS VARCHAR(255),
	@mag1 AS VARCHAR(255),
	@mag2 AS VARCHAR(255) = NULL,
	@opno AS VARCHAR(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @act_package_id AS INT,
			@act_device_name_id AS INT,
			@device_slip_id AS INT,
			@mag AS VARCHAR(255)

	WAITFOR DELAY '00:00:02';	
	--Check LotNo Exists
	IF EXISTS(SELECT 1 FROM APCSProDB.trans.lots WHERE lot_no = @lotno)BEGIN
		SELECT 'FALSE' AS Is_Pass,'LotNo is registered already succeeded. Can not register. !!' AS Error_Message_ENG,N'LotNo นี้ถูกลงทะเบียนนเรียบร้อยแล้ว ไม่สามารถลงทะเบียนซ้ำกันได้ !!' AS Error_Message_THA
		RETURN
	END

	--Check Package Not Exists
	IF NOT EXISTS (SELECT TOP 1 id FROM APCSProDB.method.packages WHERE external_package_code = @package) 
	AND NOT EXISTS (SELECT TOP 1 id FROM APCSProDB.method.packages WHERE name = @package) BEGIN
		SELECT 'FALSE' AS Is_Pass,'This package has not been registered. !!' AS Error_Message_ENG,N'Package นี้ยังไม่ได้ลงทะเบียน !!' AS Error_Message_THA
		RETURN
	END

	--Check QTY
	IF @qty < 0  BEGIN
		SELECT 'FALSE' AS Is_Pass,'Please check QTY input. !!' AS Error_Message_ENG,N'กรุณาตรวจสอบจำนวนงานเข้า !!' AS Error_Message_THA
		RETURN
	END

	IF @frameqty < 0 BEGIN
		SELECT 'FALSE' AS Is_Pass,'Please check QTY frame. !!' AS Error_Message_ENG,N'กรุณาตรวจสอบจำนวนงานเฟรม !!' AS Error_Message_THA
		RETURN
	END

	--Check Device Not Exists
	--IF NOT EXISTS (SELECT TOP 1 id FROM APCSProDB.method.device_names WHERE name = @device) BEGIN
	--	SELECT 'FALSE' AS Is_Pass,'This device has not been registered. !!' AS Error_Message_ENG,N'Device นี้ยังไม่ได้ลงทะเบียน !!' AS Error_Message_THA
	--	RETURN
	--END

	--Check Device Slip Not Exists
	IF EXISTS (SELECT 1 FROM  APCSProDB.method.packages p INNER JOIN
			  APCSProDB.method.device_names d ON p.id = d.package_id INNER JOIN
			  APCSProDB.method.device_versions dv ON d.id = dv.device_name_id AND dv.device_type = 8 INNER JOIN 
			  APCSProDB.method.device_slips ds ON dv.device_id = ds.device_id AND dv.version_num = ds.version_num AND ds.is_released = 1
			  WHERE p.external_package_code = @package) --and d.name = @device) 
	BEGIN
			SELECT @act_package_id = p.id,
				   @act_device_name_id = d.id,
				   @device_slip_id = ds.device_slip_id
			FROM  APCSProDB.method.packages p INNER JOIN
				  APCSProDB.method.device_names d ON p.id = d.package_id INNER JOIN
				  APCSProDB.method.device_versions dv ON d.id = dv.device_name_id AND dv.device_type = 8 INNER JOIN 
				  APCSProDB.method.device_slips ds ON dv.device_id = ds.device_id AND dv.version_num = ds.version_num AND ds.is_released = 1
			WHERE p.external_package_code = @package 
	END
	ELSE IF EXISTS (SELECT 1 FROM  APCSProDB.method.packages p INNER JOIN
			  APCSProDB.method.device_names d ON p.id = d.package_id INNER JOIN
			  APCSProDB.method.device_versions dv ON d.id = dv.device_name_id AND dv.device_type = 8 INNER JOIN 
			  APCSProDB.method.device_slips ds ON dv.device_id = ds.device_id AND dv.version_num = ds.version_num AND ds.is_released = 1
			  WHERE d.name = @device) 
	BEGIN
			SELECT @act_package_id = p.id,
				   @act_device_name_id = d.id,
				   @device_slip_id = ds.device_slip_id
			FROM  APCSProDB.method.packages p INNER JOIN
				  APCSProDB.method.device_names d ON p.id = d.package_id INNER JOIN
				  APCSProDB.method.device_versions dv ON d.id = dv.device_name_id AND dv.device_type = 8 INNER JOIN 
				  APCSProDB.method.device_slips ds ON dv.device_id = ds.device_id AND dv.version_num = ds.version_num AND ds.is_released = 1
			WHERE d.name = @device
	END

	ELSE BEGIN
		SELECT 'FALSE' AS Is_Pass,'Device Slip not found. !!' AS Error_Message_ENG,N'ไม่พบ device slip !!' AS Error_Message_THA
		RETURN
	END



		--SET @act_package_id = (SELECT TOP 1 id FROM APCSProDB.method.packages WHERE external_package_code = @package)
		SET @mag = CASE WHEN (@mag1 IS NULL) AND (@mag2 IS NULL ) THEN NULL 
				   WHEN (LEN(@mag1) IS NULL OR LEN(@mag1) <= 0) AND (LEN(@mag2) IS NULL OR LEN(@mag2) <= 0) THEN NULL 
				   WHEN @mag2 IS NULL THEN @mag1 ELSE CONCAT( @mag1,'|',@mag2) END 

	BEGIN TRANSACTION
	BEGIN TRY
		DECLARE @lot_id AS INT
		SET @lot_id = (SELECT id + 1 FROM [APCSProDB].[trans].[numbers] WHERE [name] = 'lots.id')

		INSERT INTO [APCSProDB].[trans].[lots]
           ([id]
           ,[lot_no]
           ,[product_family_id]
           ,[act_package_id]
           ,[act_device_name_id]
           ,[device_slip_id]
           ,[order_id]
           ,[step_no]
           ,[act_process_id]
           ,[act_job_id]
           ,[qty_in]
           ,[qty_pass]
           ,[qty_fail]
           ,[qty_out]
           ,[is_exist_work]
           ,[in_plan_date_id]
           ,[out_plan_date_id]
           ,[master_lot_id]
           ,[depth]
           ,[sequence]
           ,[wip_state]
           ,[process_state]
           ,[quality_state]
           ,[first_ins_state]
           ,[final_ins_state]
           ,[is_special_flow]
           ,[special_flow_id]
           ,[is_temp_devided]
           ,[temp_devided_count]
           ,[product_class_id]
           ,[priority]
           ,[finish_date_id]
           ,[finished_at]
           ,[in_date_id]
           ,[in_at]
           ,[ship_date_id]
           ,[ship_at]
           ,[modify_out_plan_date_id]
           ,[container_no]
           ,[start_step_no]
		   ,[external_lot_no]
           ,[created_at]
           ,[created_by]
           ,[carrier_no]
		   ,[qty_frame_in]
		   ,[qty_frame_pass]
		   )
     VALUES
           (@lot_id
           ,UPPER(@lotno)
           ,1
           ,@act_package_id
           ,@act_device_name_id
           ,@device_slip_id
           ,NULL
           ,100
           ,6
           ,83
           ,@qty
           ,@qty
           ,0
           ,0  --qty_out
           ,0
           ,(SELECT id FROM APCSProDB.trans.days WHERE date_value = CAST(GETDATE()AS date))
           ,(SELECT id FROM APCSProDB.trans.days WHERE date_value = DATEADD(DD,7, CAST(GETDATE() AS date)))
           ,@lot_id
           ,0
           ,0
           ,20
           ,0
           ,0
           ,0
           ,0
           ,0
           ,NULL
           ,0
           ,NULL
           ,0
           ,50
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,(SELECT id FROM APCSProDB.trans.days WHERE date_value = DATEADD(DD,7, CAST(GETDATE() AS date)))
           ,UPPER(@mag)
           ,100 
		   ,UPPER(@lotno)
           ,GETDATE()
           ,(SELECT TOP(1) id FROM APCSProDB.man.users WHERE emp_num = @opno)            
           ,UPPER(TRIM(@carrier)) 
		   ,@frameqty
		   ,@frameqty
		   );
		   

		   --update lots_id count
		   DECLARE @r AS INT
		   set @r = @@ROWCOUNT
		   UPDATE APCSProDB.trans.numbers
		   SET id = id + @r
		   WHERE name = 'lots.id';

		   SELECT 'TRUE' AS Is_Pass ,'' AS Error_Message_ENG,N'' AS Error_Message_THA
		COMMIT; 
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Register fail. !!' AS Error_Message_ENG,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA
	END CATCH

END

