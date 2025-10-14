-- =============================================
-- Author:		<NUCHA>
-- Create date: <2022/06/29>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [trans].[sp_get_material_type_006]
	  @barcode				AS VARCHAR(100)
	, @material_name		AS VARCHAR(250)
	, @mc_no				AS VARCHAR(250)
	, @lot_no				AS VARCHAR(10)
	, @opno					AS VARCHAR(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE   @material_id				AS INT
			, @material_type_id			AS INT
			, @Location_id				AS INT
			, @Mat_state				AS TINYINT
			, @qty						AS DECIMAL
			, @mat_record_id			AS INT
			, @mat_type					AS NVARCHAR(100)
			, @mat_lotno				AS VARCHAR(MAX)
			, @limitdate				AS DATETIME
			, @pack_std_qty				AS DECIMAL
			, @process_state			AS TINYINT
			, @type						AS VARCHAR(255)
			, @AGPasteType				AS NVARCHAR(MAX)
			, @AGPasteLotNo				AS NVARCHAR(MAX)
			, @StartTimeMix				AS DATETIME
			, @FinishTimeMix			AS DATETIME
			, @EndLot					AS DATETIME
			, @StockID					AS INT 
			, @STDLifeTimeUser			AS INT 
			, @PreformExp				AS DATETIME
			, @MANU_COND_PRIFORM		AS NVARCHAR(100)
			, @package					AS NVARCHAR(100)
			, @device					AS NVARCHAR(100)
			, @SolderWire				AS NVARCHAR(100)
			, @material_type			AS VARCHAR(MAX)
			, @used_date				AS VARCHAR(MAX)
			, @used_time				AS VARCHAR(MAX)
			, @expire_date				AS VARCHAR(MAX)
			, @expire_time				AS VARCHAR(MAX)
			, @req_date					AS VARCHAR(MAX)
			, @req_date_format			AS VARCHAR(MAX)
			, @used_format				AS DATETIME
			, @expire_format			AS DATETIME
			, @ResinBegin				AS VARCHAR(MAX)
			, @ResinEnd					AS VARCHAR(MAX)
			, @date_now					AS VARCHAR(MAX)
			, @STATE_RETURN				AS INT	= 0
			, @wafer_no					AS NVARCHAR(5)


	DECLARE @SplitData TABLE
	(
	    Barcode_split VARCHAR(MAX),
	    Position INT
	)
	 

	--check length and split @barcode
	IF LEN(@barcode) > 13
	BEGIN	
	
	INSERT INTO @SplitData (Barcode_split, Position)
	SELECT value, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Position
	FROM STRING_SPLIT(@barcode, ',')

	SET @barcode = (SELECT TOP 1 REVERSE(value) FROM STRING_SPLIT(REVERSE(@barcode),','))

	END
		SELECT	  @material_type_id		= material_production_id
				, @material_id			= m.id
				, @Location_id			= location_id
				, @Mat_state			= material_state 
				, @mat_type				= p.name --type name
				, @limitdate			= ISNULL(m.extended_limit_date,m.limit_date) --expire
				, @mat_lotno			= m.lot_no --lot_no
				, @qty					= m.quantity --quan
				, @pack_std_qty			= p.pack_std_qty 
				, @type					= c.name 
				, @process_state		= m.process_state
	FROM APCSProDB.trans.materials m 
	INNER JOIN APCSProDB.material.productions p 
	ON m.material_production_id = p.id
	INNER JOIN APCSProDB.material.categories c 
	ON c.id = p.category_id
	WHERE  m.barcode = @barcode

	 

	IF EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE lot_no = @lot_no)
	BEGIN
		IF EXISTS (SELECT 1 FROM   APCSProDB.trans.materials m  WHERE  m.barcode = @barcode)
		BEGIN 
		
				IF @type = 'BONDING WIRE' 
				BEGIN
					IF NOT EXISTS( select 1 from [APCSProDB].[material].[material_commons] 
					where material_production_id = @material_type_id and material_name = @material_name)
						BEGIN
						SELECT 'FALSE' as Is_Pass,
						'Material Type is not match. !!' AS Error_Message_ENG,
						N'Type Material ไม่ตรงกัน !!' AS Error_Message_THA,
						N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
						RETURN 
					END
					
					SET @STATE_RETURN = 1
					 
				END
				ELSE IF @type = 'FRAME' 
				BEGIN

					IF	(SELECT COUNT(machine_materials.idx) AS idx_number   FROM APCSProDB.trans.machine_materials 
							 INNER JOIN APCSProDB.mc.machines ON machines.id = machine_materials.machine_id
							 INNER JOIN APCSProDB.trans.materials ON materials.id = machine_materials.material_id
							 WHERE machines.name = @mc_no AND machine_materials.idx BETWEEN 11 AND 20 
							 ) >= 10
						BEGIN 
								SELECT 'FALSE' AS Is_Pass 
										,N'PLEASE CLEAR MATERIAL ON MACHINE !!' AS Error_Message_ENG
										, N'กรุณา CLEAR MATERIAL บน MACHINE ก่อน !!' AS Error_Message_THA
										, N'กรุณาติดต่อ System' AS Handling
							RETURN
						 
					END
					
					IF @material_name <> @mat_type 
					BEGIN
						IF NOT EXISTS( SELECT 1 FROM [APCSProDB].[material].[material_commons] 
											WHERE material_production_id = @material_type_id 
											AND  material_name  = @material_name )
							BEGIN 
 
									SELECT 'FALSE' as Is_Pass,
											'Material Type is not match.   !!' AS Error_Message_ENG,
											N'Type Material ไม่ตรงกัน !!' AS Error_Message_THA,
											N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
									RETURN
							END 
					END
					
					SET @STATE_RETURN = 1

				END 
				ELSE IF @type = 'SOLDER TAPE' OR @type = 'SOLDER BALL'  
				BEGIN
					IF	(SELECT COUNT(machine_materials.idx) AS idx_number   FROM APCSProDB.trans.machine_materials 
							 INNER JOIN APCSProDB.mc.machines ON machines.id = machine_materials.machine_id
							 INNER JOIN APCSProDB.trans.materials ON materials.id = machine_materials.material_id
							 WHERE machines.name = @mc_no AND machine_materials.idx BETWEEN 1 AND 5 
							 ) >= 10
						BEGIN 
								SELECT 'FALSE' AS Is_Pass 
										,N'PLEASE CLEAR MATERIAL ON MACHINE !!' AS Error_Message_ENG
										, N'กรุณา CLEAR MATERIAL บน MACHINE ก่อน !!' AS Error_Message_THA
										, N'กรุณาติดต่อ System' AS Handling
						RETURN
						 
					END
				 
						SELECT   @package	= packages.short_name 
								,@device	= device_names.assy_name  
						FROM APCSProDB.trans.lots
						INNER JOIN APCSProDB.method.packages
						ON packages.id = lots.act_package_id
						INNER JOIN APCSProDB.method.device_names
						ON lots.act_device_name_id =  device_names.id
						WHERE lot_no =  @lot_no
						
						SET @MANU_COND_PRIFORM =  (SELECT TRIM(MANU_COND_PRIFORM)   FROM  APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT
						WHERE LOT_NO_1 = @lot_no)
						 

  						IF  ( @MANU_COND_PRIFORM = 'SOLDER' )
						  BEGIN 
								 	SET @SolderWire = ( SELECT TOP 1 REPLACE(SolderWire, ' ','')  
											FROM	DBx.dbo.MasterPackageDevice 
											WHERE	Package =  @package
											OR		Device =   @device
											)

								IF NOT EXISTS( SELECT 1 FROM [APCSProDB].[material].[material_commons] 
												WHERE material_production_id = @material_type_id AND REPLACE(material_name, ' ','') = REPLACE(@SolderWire, ' ',''))
								BEGIN 
 
										SELECT 'FALSE' as Is_Pass,
												'Material Type is not match.   !!' AS Error_Message_ENG,
												N'Type Material ไม่ตรงกัน !! ' AS Error_Message_THA,
												N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
										RETURN
								END 
						END 
						
						IF  ( @MANU_COND_PRIFORM = '#7207ER' )
						  BEGIN 
								 
								IF NOT EXISTS( SELECT 1 FROM [APCSProDB].[material].[material_commons] 
												WHERE material_production_id = @material_type_id AND material_name = @material_name)
								BEGIN 
										SELECT 'FALSE' as Is_Pass,
												'Material Type is not match. !!' AS Error_Message_ENG,
												N'Type Material ไม่ตรงกัน !!' AS Error_Message_THA,
												N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
										RETURN
								END 
						END
						
						IF  ( @MANU_COND_PRIFORM <> '#7207ER' AND  @MANU_COND_PRIFORM <> 'SOLDER' )
						BEGIN 
							IF NOT EXISTS( SELECT 1 FROM [APCSProDB].[material].[material_commons] 
													WHERE material_production_id = @material_type_id AND material_name = @material_name)
									BEGIN 
									 
											SELECT 'FALSE' as Is_Pass,
													'Material Type is not match. !!' AS Error_Message_ENG,
													N'Type Material ไม่ตรงกัน !!' AS Error_Message_THA,
													N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
											RETURN
							END 
						END 
						 

						SET @STATE_RETURN = 1

						END 
				ELSE IF @type = 'PASTE' 
				BEGIN  
					IF	(SELECT COUNT(machine_materials.idx) AS idx_number   FROM APCSProDB.trans.machine_materials 
							 INNER JOIN APCSProDB.mc.machines ON machines.id = machine_materials.machine_id
							 INNER JOIN APCSProDB.trans.materials ON materials.id = machine_materials.material_id
							 WHERE machines.name = @mc_no AND machine_materials.idx BETWEEN 1 AND 5 
							 ) >= 10
					BEGIN 
								SELECT 'FALSE' AS Is_Pass 
										,N'PLEASE CLEAR MATERIAL ON MACHINE !!' AS Error_Message_ENG
										, N'กรุณา CLEAR MATERIAL บน MACHINE ก่อน !!' AS Error_Message_THA
										, N'กรุณาติดต่อ System' AS Handling
								RETURN
					END

					SELECT    @barcode				=  MixAGPaste.QRCode
							, @mat_type				=  (SELECT SUBSTRING(REPLACE(MixAGPaste.AGPasteType, '-', '') ,0,CASE WHEN CHARINDEX('/', MixAGPaste.AGPasteType) = 0 THEN LEN(REPLACE(MixAGPaste.AGPasteType, '-', ''))+1 ELSE CHARINDEX('/',REPLACE(MixAGPaste.AGPasteType, '-', ''))  END ))
							, @mat_lotno			=  MixAGPaste.AGPasteLotNo
							, @limitdate			= MixAGPaste.StartTimeMix + Material.STDLifeTimeUser 
							, @PreformExp			= MixAGPaste.StartTimeMix + Material.STDLifeTimeUser 
							, @EndLot				=  MixAGPaste.EndLot
							, @FinishTimeMix		=  MixAGPaste.FinishTimeMix
							, @AGPasteType			=  Material_Production
					FROM DBx.MAT.MixAGPaste 
					LEFT JOIN DBx.MAT.Material 
					ON  MixAGPaste.AGPasteType  = DBx.MAT.Material.Material_Production
					WHERE (MixAGPaste.QRCode = @barcode )   
					ORDER BY  MixAGPaste.FinishTimeMix ASC

			
					IF NOT EXISTS( select 1 from [APCSProDB].[material].[material_commons] 
						where material_production_id = @material_type_id and material_name = @material_name)
							BEGIN
							SELECT  'FALSE'									AS Is_Pass,
									'Material Type is not match. !!'		AS Error_Message_ENG,
									N'Type Material ไม่ตรงกัน !!'				AS Error_Message_THA,
									N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material'		AS Handling
							RETURN 
					END
					ELSE IF  (@AGPasteType IS NULL)  
					 BEGIN 
							SELECT    'FALSE'												AS Is_Pass 
									, 'Materials type is not match'							AS Error_Message_ENG
									, N'ไม่พบข้อมูล Material type นี้ ('+@material_name+')'		AS Error_Message_THA 
									, N''													AS Handling
									, ''													AS Warning
							RETURN

					END 
					ELSE IF  (@PreformExp < GETDATE())  
					BEGIN 
							SELECT    'FALSE'				AS Is_Pass 
									, 'Preform Expire'		AS Error_Message_ENG
									, N'Preform หมดอายุ'		AS Error_Message_THA 
									, N''					AS Handling
									, ''					AS Warning

							RETURN
					END 
					ELSE IF  (@EndLot IS NULL)  
					BEGIN 
							SELECT    'FALSE'																AS Is_Pass 
									, 'EndLot'																AS Error_Message_ENG
									, N'ยังไม่ได้ End Lot ออกจากเครื่อง Cellcon Mixer กรุณา End lot ก่อนใช้งาน'		AS Error_Message_THA 
									, N''																	AS Handling
									, ''																	AS Warning

							RETURN
					END  
					ELSE  IF   (@FinishTimeMix > GETDATE()) 
					BEGIN 
							SELECT    'FALSE'															AS Is_Pass 
									, 'In the process of mixing, please come back and mix again.'		AS Error_Message_ENG
									, N'อยู่ระหว่างการ mixing กรุณากลับมา mix ใหม่'								AS Error_Message_THA 
									, N''																AS Handling
									, ''																AS Warning

							RETURN
					END 
				
					SET @STATE_RETURN = 1

				 

				END 
				 
				ELSE IF @type = 'CHIP' 
				BEGIN  

						SELECT	  @mat_lotno = m.lot_no   
								, @wafer_no =  RIGHT('00' + CAST(wf_datas.idx  AS VARCHAR) , 2)  
						FROM APCSProDB.trans.materials m 
						LEFT JOIN APCSProDB.trans.wf_details
						ON m.id  = wf_details.material_id
						LEFT JOIN  APCSProDB.trans.wf_datas
						ON m.id  = wf_datas.material_id
						AND wf_datas.is_enable = 1
						INNER JOIN APCSProDB.material.productions p 
						ON m.material_production_id = p.id
						INNER JOIN APCSProDB.material.categories c 
						ON c.id = p.category_id  
						WHERE  m.barcode = @barcode

					DECLARE @T_PERETTO TABLE (arows int, adetail nvarchar(255))
					DECLARE @T_PERETTO_DETAIL TABLE (WaferLotNo nvarchar(255), WaferNo nvarchar(2) , wafertype NVARCHAR(100))
					 
						DECLARE @PERETTO NVARCHAR(MAX) = ''
						SELECT   @PERETTO = TRIM(REPLACE(TRIM(PERETTO_NO_1)
								+ SPACE(1) + TRIM(PERETTO_NO_2)	  
								+ SPACE(1) + TRIM(PERETTO_NO_3)	
								+ SPACE(1) + TRIM(PERETTO_NO_4)	
								+ SPACE(1) + TRIM(PERETTO_NO_5)	
								+ SPACE(1) + TRIM(PERETTO_NO_6)	
								+ SPACE(1) + TRIM(PERETTO_NO_7)	
								+ SPACE(1) + TRIM(PERETTO_NO_8)	
								+ SPACE(1) + TRIM(PERETTO_NO_9)	
								+ SPACE(1) + TRIM(PERETTO_NO_10)	
								+ SPACE(1) + TRIM(PERETTO_NO_11)	
								+ SPACE(1) + TRIM(PERETTO_NO_12)
								+ SPACE(1) ,'TORINOKOSHI WAFER ','') )    
								    --AS lll     	                        	                        	                        	                        	                        	                        	                        	                        	                        	                        
						FROM APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT
						WHERE LOT_NO_2 = @lot_no;

					
						INSERT INTO @T_PERETTO (arows, adetail)
						SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1))
							, VALUE 
						FROM  STRING_SPLIT(@PERETTO , ' ');

						DECLARE @i_end INT = (SELECT COUNT(arows) FROM @T_PERETTO);
						DECLARE @i_start INT = 1
						DECLARE @WaferLotNo NVARCHAR(20) = ''
						DECLARE @WaferNo NVARCHAR(20) = ''

						
						WHILE( @i_start <= @i_end)
						BEGIN 
							 
							 IF (SELECT  LEN( adetail ) FROM @T_PERETTO WHERE arows = @i_start) < 5 
							BEGIN 
								SELECT @WaferNo = adetail
								FROM @T_PERETTO
								WHERE arows = @i_start; 
								INSERT INTO @T_PERETTO_DETAIL (WaferLotNo, WaferNo , wafertype) VALUES (@WaferLotNo, REPLACE(REPLACE(@WaferNo,'*',''),'#','') 
								, CASE WHEN  @WaferNo LIKE '%#%' THEN 'WAFER Surpluses' ELSE 'WAFER' END );
							END
							ELSE IF (SELECT  LEN( adetail ) FROM @T_PERETTO WHERE arows = @i_start) > 5 
							BEGIN  
								SELECT @WaferLotNo = adetail
								FROM @T_PERETTO
								WHERE arows = @i_start;
							END 
							SET @i_start += 1
						END
						  
						 IF (@mat_type = 'WAFER Surpluses')
						 BEGIN 
					  
								 IF EXISTS (SELECT 1 FROM    @T_PERETTO_DETAIL  WHERE WaferLotNo =  @mat_lotno AND WaferNo = @wafer_no AND wafertype = @mat_type)
								 BEGIN 

								
												SET  @STATE_RETURN = 1
								 END 
						 END 
						 ELSE
						 BEGIN 
						 

								  SELECT @STATE_RETURN = (CASE WHEN EXISTS (SELECT 1 FROM    @T_PERETTO_DETAIL   
															WHERE  wafertype = @mat_type AND  NOT EXISTS (SELECT	  1 
																FROM APCSProDB.trans.materials m 
															LEFT JOIN APCSProDB.trans.wf_details
															ON m.id  = wf_details.material_id
															LEFT JOIN  APCSProDB.trans.wf_datas
															ON m.id  = wf_datas.material_id
															AND wf_datas.is_enable	= 1
															INNER JOIN APCSProDB.material.productions p 
															ON m.material_production_id = p.id
															INNER JOIN APCSProDB.material.categories c 
															ON c.id = p.category_id  
															WHERE  m.barcode = @barcode   
															AND 		   WaferLotNo = m.lot_no
																AND  WaferNo =  RIGHT('00' + CAST(wf_datas.idx  AS VARCHAR) , 2)  
																)
															)	THEN 0
																ELSE 1
																END )
						END 

						IF  @STATE_RETURN = 0
						BEGIN

								 SELECT 'FALSE'												AS Is_Pass
								 , 'Wafer no ( '+ @mat_lotno + ' ) mismatch Working slip ( '+ @PERETTO + ' )'	AS Error_Message_ENG
								 , N'Wafer no ( '+ @mat_lotno + N' ) ไม่ตรงกับ Working slip ( '+ @PERETTO + N' )'	AS Error_Message_THA
								 , N''														AS Handling
								RETURN 
						 
						END 


				END
		 		ELSE IF @type = 'RESIN' 
				BEGIN

					SET @material_type = (SELECT Barcode_split FROM @SplitData WHERE Position = 1);
					SET @used_date = (SELECT Barcode_split FROM @SplitData WHERE Position = 5);
					SET @used_time = (SELECT Barcode_split FROM @SplitData WHERE Position = 6);
					SET @expire_date = (SELECT Barcode_split FROM @SplitData WHERE Position = 7);
					SET @expire_time = (SELECT Barcode_split FROM @SplitData WHERE Position = 8);
					SET @req_date = (SELECT Barcode_split FROM @SplitData WHERE Position = 11);
					SET @req_date_format = CONVERT(VARCHAR(10), DATEADD(DAY, @req_date - 2, '1900-01-01'), 23);
					SET @date_now = CONVERT(VARCHAR(16), GETDATE(), 120);
					SET @used_format = CONVERT(DATETIME, CONCAT(CONVERT(VARCHAR(4), YEAR(@req_date_format)), '-', CONVERT(VARCHAR(2), MONTH(@req_date_format)), '-', @used_date, ' ', @used_time, ':00:00'));
					SET @expire_format = CONVERT(DATETIME, CONCAT(CONVERT(VARCHAR(4), YEAR(@req_date_format)), '-', CONVERT(VARCHAR(2), MONTH(@req_date_format)), '-', @expire_date, ' ', @expire_time, ':00:00'));
					SET @ResinBegin = FORMAT(@used_format, 'yyyy-MM-dd HH:mm');
					SET @ResinEnd = FORMAT(@expire_format, 'yyyy-MM-dd HH:mm');
					--SET @limitdate = @ResinEnd

					-- 1 check type m.aterial system
					IF NOT EXISTS( select 1 from [APCSProDB].[material].[material_commons] 
					where material_production_id = @material_type_id and material_name = @material_type)
					BEGIN 
					 
						SELECT 'FALSE' AS Is_Pass
						, 'Resin type is not match. !!' AS Error_Message_ENG
						, N'Resin Type ไม่ตรงกัน. !!' AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
						RETURN
					END
					 
					--2 expire supplier time material system				
					IF @limitdate < GETDATE()
					BEGIN
						SELECT 'FALSE' AS Is_Pass
						, 'Resin type has expired. !!' AS Error_Message_ENG
						, N'Resin Type หมดอายุ. !!' AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
						RETURN
					END
					 
					--3 check type PD qrcode with denpyo
					IF @material_name <> @material_type 
					BEGIN
						PRINT @material_name
						PRINT @material_type

						SELECT 'FALSE' AS Is_Pass
						, 'Resin type is not match. !!' AS Error_Message_ENG
						, N'Resin Type ไม่ตรงกัน. !!' AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
						RETURN
					END

					--3 check if @req_date_format > @ResinBegin then Add Month ถ้าวันที่เบิก มากกว่า วันที่เริ่มใช้
					IF @req_date_format > @ResinBegin
					BEGIN
					    SET @ResinBegin = CONVERT(VARCHAR(16), DATEADD(MONTH, 1, CAST(@ResinBegin AS DATETIME)), 120);
						SET @ResinEnd = CONVERT(VARCHAR(16), DATEADD(MONTH, 1, CAST(@ResinEnd AS DATETIME)), 120);
					END

					--4 check if @ResinBegin > @ResinEnd then Add Month ถ้าวันที่เริ่มใช้ มากกว่า วันที่หมดอายุ บวกเพิ่ม 1 เดือน
					IF @ResinBegin > @ResinEnd
					BEGIN
						SET @ResinEnd = CONVERT(VARCHAR(16), DATEADD(MONTH, 1, CAST(@ResinEnd AS DATETIME)), 120);
					END

					--5 use time
					IF @date_now < @ResinBegin  
					BEGIN
						SELECT 'FALSE' AS Is_Pass
						, 'Resin type is not usable. !!' AS Error_Message_ENG
						, N'Resin Type นี้นำมาใช้งานก่อนกำหนด !!' AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
						RETURN
					END
					 
					--6 expire time
					IF @date_now > @ResinEnd
					BEGIN 

						SELECT 'FALSE' AS Is_Pass
						, 'Resin type has expired. !!' AS Error_Message_ENG
						, N'Resin Type หมดอายุ. !!' AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
						RETURN
					END

					SELECT	  'TRUE' as Is_Pass
							, 'Pass' AS Error_Message_ENG
							, N'ผ่าน' AS Error_Message_THA
							, N'' AS Handling
							, @material_id as Material_id
							, @material_name as Material_type_name
							, @mat_lotno as mat_lot_no
							, @ResinEnd as limit
							, @qty as quantity
							, @material_name as slip_material_name
							, @pack_std_qty as pack_std_qty
 
					RETURN 

				END

				IF (@STATE_RETURN = 1)
				BEGIN 

				SELECT 'TRUE'							AS Is_Pass
					, 'Pass'							AS Error_Message_ENG
					, N'ผ่าน'								AS Error_Message_THA
					, N''								AS Handling
					, @material_id						AS Material_id
					, @mat_type							AS Material_type_name
					, @mat_lotno						AS mat_lot_no
					, CONVERT(VARCHAR,@limitdate,121)	AS limit
					, @qty								AS quantity
					, @material_name					AS slip_material_name
					, @pack_std_qty						AS pack_std_qty

					RETURN
				END
				ELSE
				BEGIN 
					 SELECT 'FALSE' as Is_Pass,
							'This QR Code Material Type is invalid. !!' AS Error_Message_ENG,
							N'QR Code Material Type นี้ไม่ถูกต้อง !!' AS Error_Message_THA,
							N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
					RETURN 

				END 
				 
		END 
		ELSE  IF EXISTS( SELECT 1 FROM  DBx.MAT.MixAGPaste  WHERE DBx.MAT.MixAGPaste.QRCode =  @barcode AND @barcode like 'MAT%')
		BEGIN 
				SELECT    @barcode				=  MixAGPaste.QRCode
						, @AGPasteType			=  (SELECT SUBSTRING(REPLACE(MixAGPaste.AGPasteType, '-', '') ,0,CASE WHEN CHARINDEX('/', MixAGPaste.AGPasteType) = 0 THEN LEN(REPLACE(MixAGPaste.AGPasteType, '-', ''))+1 ELSE CHARINDEX('/',REPLACE(MixAGPaste.AGPasteType, '-', ''))  END ))
						, @AGPasteLotNo			=  MixAGPaste.AGPasteLotNo
						, @StartTimeMix			=  MixAGPaste.StartTimeMix
						, @FinishTimeMix		=  MixAGPaste.FinishTimeMix
						, @EndLot				=  MixAGPaste.EndLot
						, @StockID				=  REPLACE(REPLACE(MixAGPaste.QRCode, 'MAT,', ''), '.', '') 
						, @STDLifeTimeUser		= Material.STDLifeTimeUser
						, @PreformExp			= MixAGPaste.StartTimeMix + Material.STDLifeTimeUser 
				FROM DBx.MAT.MixAGPaste 
				INNER JOIN DBx.MAT.Material 
				ON  MixAGPaste.AGPasteType =  DBx.MAT.Material.Material_Production 
				WHERE (MixAGPaste.QRCode = @barcode )   
				ORDER BY  MixAGPaste.FinishTimeMix ASC
 
				
				IF NOT EXISTS( select 1 from [APCSProDB].[material].[material_commons] 
					where material_production_id = @material_type_id and material_name = @material_name)
						BEGIN
						SELECT 'FALSE' as Is_Pass,
						'Material Type is not match. !!' AS Error_Message_ENG,
						N'Type Material ไม่ตรงกัน !!' AS Error_Message_THA,
						N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
						RETURN 
				END
				ELSE IF (SELECT TOP 1 VALUE  FROM STRING_SPLIT(@barcode,',')) <> 'MAT' 
				BEGIN
					SELECT    'FALSE'											AS Is_Pass 
							, 'This ('+ @barcode +') format is not correct !!'	AS Error_Message_ENG
							, N' ('+ @barcode +N') ฟอร์แมตไม่ถูกต้อง !!'				AS Error_Message_THA 
							, N''												AS Handling
							, ''												AS Warning

					RETURN
				END
				ELSE IF  (@PreformExp < GETDATE())  
				BEGIN 
						SELECT    'FALSE'				AS Is_Pass 
								, 'Preform Expire'		AS Error_Message_ENG
								, N'Preform หมดอายุ'		AS Error_Message_THA 
								, N''					AS Handling
								, ''					AS Warning

						RETURN
				END 
				ELSE IF  (@EndLot IS NULL)  
				BEGIN 
						SELECT    'FALSE'																AS Is_Pass 
								, 'EndLot'																AS Error_Message_ENG
								, N'ยังไม่ได้ End Lot ออกจากเครื่อง Cellcon Mixer กรุณา End lot ก่อนใช้งาน'		AS Error_Message_THA 
								, N''																	AS Handling
								, ''																	AS Warning

						RETURN
				END  
				ELSE  IF   (@FinishTimeMix > GETDATE()) 
				BEGIN 
						SELECT    'FALSE'															AS Is_Pass 
								, 'In the process of mixing, please come back and mix again.'		AS Error_Message_ENG
								, N'อยู่ระหว่างการ mixing กรุณากลับมา mix ใหม่'								AS Error_Message_THA 
								, N''																AS Handling
								, ''																AS Warning

						RETURN
				END 
			 

			 	SELECT    @barcode				=  MixAGPaste.QRCode
						, @mat_type				=  (SELECT SUBSTRING(REPLACE(MixAGPaste.AGPasteType, '-', '') ,0,CASE WHEN CHARINDEX('/', MixAGPaste.AGPasteType) = 0 THEN LEN(REPLACE(MixAGPaste.AGPasteType, '-', ''))+1 ELSE CHARINDEX('/',REPLACE(MixAGPaste.AGPasteType, '-', ''))  END ))
						, @mat_lotno			=  MixAGPaste.AGPasteLotNo
						, @material_id			=  REPLACE(REPLACE(MixAGPaste.QRCode, 'MAT,', ''), '.', '') 
						, @limitdate			= MixAGPaste.StartTimeMix + Material.STDLifeTimeUser 
				FROM DBx.MAT.MixAGPaste 
				INNER JOIN DBx.MAT.Material 
				ON  MixAGPaste.AGPasteType =  DBx.MAT.Material.Material_Production 
				WHERE (MixAGPaste.QRCode = @barcode )   
				ORDER BY  MixAGPaste.FinishTimeMix ASC

				SELECT   'TRUE'								AS Is_Pass
						, 'Pass'							AS Error_Message_ENG
						, N'ผ่าน'								AS Error_Message_THA
						, N''								AS Handling
						, @material_id						AS Material_id
						, @mat_type							AS Material_type_name
						, @mat_lotno						AS mat_lot_no
						, CONVERT(VARCHAR,@limitdate,121)	AS limit
						, @qty								AS quantity
						, @material_name					AS slip_material_name
						, @pack_std_qty						AS pack_std_qty

				END 
		 
		 
		ELSE 
		BEGIN 
			 SELECT 'FALSE' as Is_Pass,
					'This material could not be found. !!' AS Error_Message_ENG,
					N'ไม่พบข้อมูล Type Material นี้ !!' AS Error_Message_THA,
					N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
			  RETURN 
		END
	END
	ELSE 
		BEGIN 
				 SELECT 'FALSE' as Is_Pass,
						'This Lot No. could not be found. !!' AS Error_Message_ENG,
						N'ไม่พบข้อมูล Lot No. นี้ !!' AS Error_Message_THA,
						N'ไม่พบข้อมูล Lot No. นี้' AS Handling
				  RETURN 
		
		END
END

