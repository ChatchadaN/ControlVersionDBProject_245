-- =============================================
-- Author:		NUCHA
-- Create date: 2022/06/29
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_regist_e_slip] 
	-- Add the parameters for the stored procedure here
	@lot_no AS VARCHAR(50),
	@e_slip_id AS VARCHAR(20) = NULL,
	@carrier_no AS VARCHAR(20) = NULL,
	@op_no AS VARCHAR(6)= NULL,
	@mc_no AS VARCHAR(50)= NULL,
	@app_name AS VARCHAR(255),
	@lot_type AS TINYINT -- 1 : D-Lot, 2 : Outsurce ,  99 : Get data lot

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
		DECLARE @assy_lot_no AS VARCHAR(20),
				@lot_outsource AS VARCHAR(20)

		DECLARE @device_name AS VARCHAR(50),
				@qty AS INT,
				@is_pass AS VARCHAR(10)

		INSERT INTO APIStoredProDB.[dbo].[exec_sp_history]
		   ([record_at]
		  , [record_class]
		  , [login_name]
		  , [hostname]
		  , [appname]
		  , [command_text]
		  , [lot_no])
		SELECT GETDATE()
			,4 --1 Insert,2 Update,3 Delete,4 StoredProcedure
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			,'EXEC [trans].[sp_set_regist_e_slip] @lot_no = ''' + ISNULL(CAST(@lot_no AS varchar),'') + ''', @e_slip_id = ''' + ISNULL(CAST(@e_slip_id AS varchar),'') + ''', @carrier_no = ''' 
				+ ISNULL(CAST(@carrier_no AS varchar),'') + ''', @op_no = ''' + ISNULL(CAST(@op_no AS varchar),'') +''', @mc_no = ''' + ISNULL(CAST(@mc_no AS varchar),'') 
				 + '''' + ''', @app_name = ''' + ISNULL(CAST(@app_name AS varchar),'') + ''''
				 + '''' + ''', @lot_type = ''' + ISNULL(CAST(@lot_type AS varchar),'') + ''''
			, @lot_no		


	IF (LEN(@e_slip_id) = 17 )
	BEGIN

		--CHECK Lot Tpye
		IF @lot_type = 2 BEGIN -- Lot Tpye Outsource
			SET @device_name = TRIM(SUBSTRING(@lot_no,0,CHARINDEX(' ',@lot_no) ))
			SET @lot_outsource = SUBSTRING(TRIM(SUBSTRING(@lot_no,CHARINDEX(' ',@lot_no), LEN(@lot_no))),0,CHARINDEX(' ',TRIM(SUBSTRING(@lot_no,CHARINDEX(' ',@lot_no), LEN(@lot_no) ))))
			--SET	@qty = CONVERT(INT, TRIM(RIGHT(@lot_no,CHARINDEX(' ',REVERSE(@lot_no) ))))	

				IF EXISTS (SELECT 1 FROM OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144; User ID=ship;Password=ship;' ).[Half_Product].[dbo].[Half_Product_Order_List] hp
					WHERE  OutSourceLotNo = @lot_no )
				BEGIN
				--///////////////////////////////////////////////
					SET @lot_outsource = @lot_no
				END

				ELSE IF EXISTS (SELECT 1 FROM OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144; User ID=ship;Password=ship;' ).[Half_Product].[dbo].[Half_Product_Order_List] hp
					WHERE  OutSourceLotNo = @lot_outsource)
				BEGIN 
				--///////////////////////////////////////////////
					SET @lot_outsource = @lot_outsource
				END

				ELSE BEGIN
					SELECT  'FALSE' AS Is_Pass
						, 'Can not found data lot outsource !!' AS Error_Message_ENG
						, N'ไม่พบข้อมูล lot outsource !!' AS Error_Message_THA 
						, N'กรุณาตรวจสอบข้อมูล lot outsource ที่เว็บ Half Product' AS Handling
					RETURN
				END

			--GET Matching Lot Outsource
			EXEC APIStoredProDB.trans.get_matching_lotoutsource 
				 @lot_outsource = @lot_outsource, 
				 @device_name = @device_name,
				 @is_pass = @is_pass OUTPUT, 
				 @assy_lot_no = @assy_lot_no OUTPUT

			IF @is_pass = 'FALSE' BEGIN
				SELECT 'FALSE' as Is_Pass,
				'Can not found Lot data. ('+ TRIM(@lot_outsource) +') or this already registed !!' AS Error_Message_ENG,
				N'ไม่พบข้อมูล Lot นี้ ('+ TRIM(@lot_outsource) + N') หรือ Lot นี้ลงทะเบียนครบแล้ว !!' AS Error_Message_THA,
				N'กรุณาตรวจสอบข้อมูล Lot นี้ที่เว็บ Half Product หรือ เว็บ ATOM !!' AS Handling 

				RETURN
			END

			--SELECT @lot_outsource, @device_name, @qty, @is_pass, @assy_lot_no
		
			-- ########## VERSION 001 ##########
			EXEC [APIStoredProVersionDB].trans.sp_set_regist_e_slip_001
				@lot_no = @assy_lot_no,
				@lot_outsource = @lot_outsource,
				@e_slip_id = @e_slip_id,
				--@carrier_no = @carrier_no,
				@op_no = @op_no,
				@mc_no = @mc_no,
				@app_name = @app_name
			-- ########## VERSION 001 ##########
		END
		ELSE IF @lot_type = 1 
		BEGIN
			
		 
			--IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE lot_no =  @lot_no) BEGIN
			--	SELECT 'FALSE' as Is_Pass,
			--	'Can not found Lot data. !! ('+ @lot_outsource +')' AS Error_Message_ENG,
			--	N'ไม่พบข้อมูล Lot นี้ !! ('+ @lot_outsource +')' AS Error_Message_THA,
			--	N'กรุณาตรวจสอบข้อมูล Lot นี้ที่เว็บ ATOM !!' AS Handling 

			--	RETURN
			--END
			-- ########## VERSION 001 ##########
			EXEC [APIStoredProVersionDB].trans.sp_set_regist_e_slip_001
				@lot_no = @lot_no,
				--@lot_outsource = @lot_outsource,
				@e_slip_id = @e_slip_id,
				--@carrier_no = @carrier_no,
				@op_no = @op_no,
				@mc_no = @mc_no,
				@app_name = @app_name
			-- ########## VERSION 001 ##########
		END
		---------------------------------------------------
		---- @lot_type = 99 Get special flow 
		---------------------------------------------------
		ELSE IF @lot_type = 99 
		BEGIN
			-- ########## VERSION 001 ##########
			IF (len(@lot_no) = 10)
			BEGIN
				-- Lot Assy
				SELECT 'TRUE' AS [Is_Pass]
					, '' AS [Error_Message_ENG]
					, N'' AS [Error_Message_THA]
					, N'' AS [Handling]
					, [lots].[id] AS [LotId]
					, ISNULL(TRIM([lots].[lot_no]),'') AS [LotNo]
					, ISNULL(TRIM(lots.carrier_no),'')  AS [Carrier]
					, ISNULL(TRIM([packages].[name]),'') AS [Package]
					, ISNULL(TRIM([device_names].[name]),'') AS [Device]
					, ISNULL(TRIM([device_names].[tp_rank]),'')  AS [tp_rank]					
					, CASE WHEN [lots].[is_special_flow] =  1 THEN ISNULL(TRIM(jobspecial.name),'') ELSE ISNULL(TRIM(jobmaster.name),'') END AS [JobName]
					, [lots].[qty_in] AS [qty]
					, 0 AS [lot_count]
					, ISNULL([lots].[e_slip_id],'') AS [e_slip_id]
					, CASE WHEN [lots].[is_special_flow] =  1 THEN ISNULL(lot_special_flows.step_no,'') ELSE ISNULL(lots.step_no,'') END AS [StepNo]
					, ISNULL([locations].[name],'') AS [rack_location]
					, [days].[date_value] as [shipment_date]
				FROM [APCSProDB].[trans].[lots]  
				INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
				INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
				LEFT JOIN APCSProDB.trans.special_flows ON [lots].[is_special_flow] = 1 
					AND [lots].[special_flow_id] = [special_flows].[id]
				LEFT JOIN APCSProDB.trans.lot_special_flows ON [special_flows].[id] = [lot_special_flows].[special_flow_id] 
					AND [special_flows].[step_no] = [lot_special_flows].[step_no]
				INNER JOIN APCSProDB.method.jobs AS [jobmaster] ON [lots].[act_job_id] = [jobmaster].[id]
				LEFT JOIN APCSProDB.method.jobs AS [jobspecial] ON [lot_special_flows].[job_id] = [jobspecial].[id]
				LEFT JOIN [APCSProDB].[trans].[locations] ON [lots].[location_id] = [locations].[id]
				LEFT JOIN [APCSProDB].[trans].[days] on [lots].[modify_out_plan_date_id] = [days].[id] 
				WHERE [lots].lot_no = @lot_no
				ORDER BY [lots].[lot_no];
			END
			ELSE BEGIN
				-- Lot OutSource
				SET @device_name = TRIM(SUBSTRING(@lot_no,0,CHARINDEX(' ',@lot_no) ));
				SET @lot_outsource = SUBSTRING(TRIM(SUBSTRING(@lot_no,CHARINDEX(' ',@lot_no), LEN(@lot_no))),0,CHARINDEX(' ',TRIM(SUBSTRING(@lot_no,CHARINDEX(' ',@lot_no), LEN(@lot_no) ))));
			
				EXEC APIStoredProDB.trans.get_matching_lotoutsource 
					 @lot_outsource = @lot_outsource, @device_name = @device_name,
					 @is_pass = @is_pass OUTPUT, @assy_lot_no = @assy_lot_no OUTPUT

				IF (@is_pass = 'FALSE') 
				BEGIN
					SELECT 'FALSE' as Is_Pass
						, 'Can not found Lot data. ('+ @lot_outsource +') or this already registed !!' AS Error_Message_ENG
						, N'ไม่พบข้อมูล Lot นี้ ('+ @lot_outsource + N') หรือ Lot นี้ลงทะเบียนครบแล้ว !!' AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูล Lot นี้ที่เว็บ Half Product หรือ เว็บ ATOM !!' AS Handling 

					RETURN
				END

				SELECT 'TRUE' AS [Is_Pass]
					, '' AS [Error_Message_ENG]
					, N'' AS [Error_Message_THA]
					, N'' AS [Handling]
					, [lots].[id] AS [LotId]
					, ISNULL(TRIM([lots].[lot_no]),'') AS [LotNo]
					, ISNULL(TRIM(lots.carrier_no),'')  AS [Carrier]
					, ISNULL(TRIM([packages].[name]),'') AS [Package]
					, ISNULL(TRIM([device_names].[name]),'') AS [Device]
					, ISNULL(TRIM([device_names].[tp_rank]),'')  AS [tp_rank]					
					, CASE WHEN [lots].[is_special_flow] =  1 THEN ISNULL(TRIM(jobspecial.name),'') ELSE ISNULL(TRIM(jobmaster.name),'') END AS [JobName]
					, [lots].[qty_in] AS [qty]
					, ISNULL([outsource_count].[lot_count],0) as [lot_count]
					, ISNULL([lots].[e_slip_id],'') AS [e_slip_id]
					, CASE WHEN [lots].[is_special_flow] =  1 THEN ISNULL(lot_special_flows.step_no,'') ELSE ISNULL(lots.step_no,'') END AS [StepNo]
					, ISNULL([locations].[name],'') AS [rack_location]
					, [days].[date_value] as [shipment_date]
				FROM [APCSProDB].[trans].[lots]  
				INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
				INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
				LEFT JOIN APCSProDB.trans.special_flows ON [lots].[is_special_flow] = 1 
					AND [lots].[special_flow_id] = [special_flows].[id]
				LEFT JOIN APCSProDB.trans.lot_special_flows ON [special_flows].[id] = [lot_special_flows].[special_flow_id] 
					AND [special_flows].[step_no] = [lot_special_flows].[step_no]
				INNER JOIN APCSProDB.method.jobs AS [jobmaster] ON [lots].[act_job_id] = [jobmaster].[id]
				LEFT JOIN APCSProDB.method.jobs AS [jobspecial] ON [lot_special_flows].[job_id] = [jobspecial].[id]
				LEFT JOIN [APCSProDB].[trans].[locations] ON [lots].[location_id] = [locations].[id]
				LEFT JOIN [APCSProDB].[trans].[days] on [lots].[modify_out_plan_date_id] = [days].[id] 
				outer apply (
					select count([OutSourceLotNo]) as [lot_count] 
					from (
						select [LotNo],[OutSourceLotNo]
						from openrowset ('SQLNCLI', 'Server= 10.28.1.144;Database=Half_Product;Uid=ship;Pwd=ship', 
							'SELECT [LotNo],[OutSourceLotNo]
							FROM [Half_Product].[dbo].[Half_Product_Order_List]
							ORDER BY Qty DESC, LotNo ASC')
					) as [hp]
					inner join [APCSProDB].[trans].[lots] on [lots].[lot_no] = [hp].[LotNo]
					WHERE [hp].[OutSourceLotNo] = @lot_outsource
						and [lots].e_slip_id is null
					group by [OutSourceLotNo]
				) AS [outsource_count]
				WHERE [lots].lot_no = @assy_lot_no
				ORDER BY [lots].[lot_no]
			END
			-- ########## VERSION 001 ##########
		END
		---------------------------------------------------
		ELSE BEGIN
			SELECT 'FALSE' as Is_Pass,
				'Please Input Lot Type !!' AS Error_Message_ENG,
				N'กรุณาระบุ Lot Type ให้ถูกต้อง' AS Error_Message_THA,
				N'กรุณาตรวจสอบข้อมูล Lot นี้ที่เว็บ ATOM !!' AS Handling 
		END
			END 
		
	ELSE BEGIN
			SELECT 'FALSE' as Is_Pass,
				N'Invalid format e-slip  !!' AS Error_Message_ENG,
				N'Format e-slip  ไม่ถูกต้อง' AS Error_Message_THA,
				N'กรุณาตรวจสอบข้อมูล e-slip ให้ถูกต้อง !!' AS Handling 
	END
END
