-- =============================================
-- Author:		SADANU
-- Create date: 2023/01/13
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_checkmaterial_set_003]
	-- Add the parameters for the stored procedure here
		 @LotNo				NVARCHAR(20)  = NULL
	  ,  @QRCode			NVARCHAR(MAX)  = NULL -- 'G15,D0328W,2Y21JJ0632,1 Roll,2022/11/24'
	  ,  @McNo				NVARCHAR(20)
	  ,  @OpNO				NVARCHAR(20)
	  ,  @App_Name			NVARCHAR(50)
	  ,  @Material_type		NVARCHAR(50)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	
	-- interfering with SELECT statements.
	   
	
	DECLARE  @lot_id		INT 
	,  @step_no_now			INT 
	,  @Expire_Date			DATETIME 
	,  @package_id			INT 
	,  @CheckCount			INT		= 0
	,  @CheckCount2			INT		= 0
	,  @material_set_id		INT     = NULL
	 
	  SELECT	  @lot_id		=  id 
				, @package_id	= act_package_id    
	  FROM APCSProDB.trans.lots
	  WHERE lot_no =  @LotNo
	  
SET @CheckCount = ( SELECT COUNT(*)  FROM STRING_SPLIT(@QRCode,',') )
SET @CheckCount2 = ( SELECT COUNT(*)  FROM STRING_SPLIT(@QRCode,';') )
 
 		INSERT INTO APIStoredProDB.[dbo].[exec_sp_history]
		   ([record_at]
		  , [record_class]
		  , [login_name]
		  , [hostname]
		  , [appname]
		  , [command_text]
		  , [lot_no])
		SELECT GETDATE()
			,'4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			,'PACKAGE_ID: '+CAST(@package_id AS nvarchar(MAX))  + ' ,LOT_ID: ' +  CAST(@lot_id AS nvarchar(MAX))
			, @LotNo


		--82	HTSSOP-B20          
		--87	HTSSOP-B40          
		--91	HTSSOP-C48          
		--246	SSOP-B28W           
	IF (@package_id IN  ( 87, 91, 246))	
		BEGIN
	


			IF (@CheckCount = 5)
					BEGIN
			PRINT @CheckCount
				
			-- PIVOT EMBOSS TAPE ( G15,D0328W,2Y21JJ0632,1 Roll,2022/11/24 )
					CREATE TABLE #TEMP
					(
							  Material_LotNo	NVARCHAR(100) 
							, Qty				NVARCHAR(100)
							, Expire_Date		NVARCHAR(100)
							, Prod_name			NVARCHAR(100)
							, PN				NVARCHAR(100)
					)
					INSERT INTO #TEMP
					SELECT * FROM   
					(
						SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@QRCode,',') 

					) t 
					PIVOT
					(
						MAX([value])
						FOR row_num IN (
								[3] 
							,[4]
							,[5]
							,[2] 
							,[1]    
							)
					) AS pivot_table 

 
			-- CHECK EMBOSS HAVE IN DB
					IF NOT EXISTS (SELECT id FROM    APCSProDB.material.productions WHERE  REPLACE(UPPER(name),' ','') = (SELECT REPLACE(UPPER(#TEMP.Prod_name),' ','') FROM  #TEMP)
																							AND productions.details =  @Material_type	)
						BEGIN 
			-- PIVOT COVER TAPE ( 9.5MM,LOTNO,2023/03/31,2024/03/31,00000 )
								DELETE FROM #TEMP
			
								INSERT INTO #TEMP
								SELECT * FROM   
								(
									SELECT ROW_NUMBER() OVER ( ORDER BY (SELECT 0) ) row_num,  *  FROM STRING_SPLIT(@QRCode,',') 
								) t 
								PIVOT
								(
									MAX([value])
									FOR row_num IN (
										 [2]
										,[4]
										,[3]  
										,[1]
										,[5]  
										)
								) AS pivot_table 
								

						END 
			-- CHECK COVER TAPE HAVE IN DB 
 					IF NOT EXISTS (SELECT id FROM    APCSProDB.material.productions WHERE REPLACE(REPLACE(UPPER(productions.name),' ',''),'MM','') = (SELECT  REPLACE(REPLACE(UPPER(#TEMP.Prod_name),' ',''),'MM','') FROM  #TEMP)
																							AND productions.details =  @Material_type	)
						BEGIN 
								DELETE FROM #TEMP

			-- PIVOT COVER TAPE ( 00000,9.5MM,2023/03/31,QQQQ,2024/03/31 )

								INSERT INTO #TEMP
								SELECT * FROM   
								(
									SELECT ROW_NUMBER() OVER ( ORDER BY (SELECT 0) ) row_num,  *  FROM STRING_SPLIT(@QRCode,',') 
								) t 
								PIVOT
								(
									MAX([value])
									FOR row_num IN (
											[4]
										,[1]
										,[5] 
										,[2]
										,[3]
										)
								) AS pivot_table 
								 
								 UPDATE #TEMP
								 SET  Expire_Date   = CONVERT(varchar,DATEADD(mm, DATEDIFF(mm,0,'01.'+Expire_Date), 0),111) 
									, Prod_name			= Prod_name+'MM'
								 FROM #TEMP

						END 	
					 
			-- CHECK COVER TAPE,EMBOSS TAPE AFTER PIVOT

					IF  EXISTS (SELECT id FROM  APCSProDB.material.productions WHERE REPLACE(UPPER(productions.name),' ','') = (SELECT REPLACE(UPPER(#TEMP.Prod_name),' ','') FROM  #TEMP))
					BEGIN 
			-- CHECK TYPE IN DB
						IF  EXISTS (SELECT id FROM    APCSProDB.material.productions WHERE REPLACE(UPPER(productions.name),' ','') = (SELECT  REPLACE(UPPER(#TEMP.Prod_name),' ','') FROM  #TEMP)
																							AND productions.details =  @Material_type	)
						BEGIN 
 										SELECT @step_no_now = (
											CASE 
												WHEN [lots].[is_special_flow] = 1 then 
													(SELECT [step_no] FROM [APCSProDB].[trans].[special_flows] WITH (NOLOCK) WHERE [special_flows].[id] = [lots].[special_flow_id]) 
												ELSE [lots].[step_no]
											END ) 
										
										FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
										WHERE [lots].[id] = @lot_id
 
						--SET @Expire_Date  = (SELECT Expire_Date FROM #TEMP) 
							--IF (@Expire_Date > GETDATE())
							--BEGIN

							SET @material_set_id = ( SELECT  device_flows.material_set_id   
												FROM APCSProDB.trans.lots  
												INNER JOIN APCSProDB.method.device_flows
												ON lots.device_slip_id = device_flows.device_slip_id
												AND  device_flows.step_no =  @step_no_now
												WHERE lots.id  =  @lot_id)
			
			-- CHECK MATERIAL SET ID IN DB

							IF @material_set_id IS NULL							 
							BEGIN 
									SELECT  'FALSE' AS Is_Pass
											,'Device slips this material has not been registered yet !!' AS Error_Message_ENG
											,N'Device slips นี้ยังไม่ถูกลงทะเบียน Material' AS Error_Message_THA
											,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
									FROM #TEMP 
							END 
							ELSE 
							BEGIN
			-- CHECK MATERIAL IS MATCHING WITH LOT
							IF  EXISTS (SELECT Prod_name FROM  #TEMP INNER JOIN ( SELECT productions.name 
																				  FROM APCSProDB.trans.lots
																				  INNER JOIN APCSProDB.method.device_flows
																				  ON lots.device_slip_id = device_flows.device_slip_id
																				  AND  device_flows.step_no = @step_no_now
																				  INNER JOIN APCSProDB.method.material_sets 
																				  ON  material_sets.process_id = device_flows.act_process_id
																				  AND device_flows.material_set_id = material_sets.id
																				  INNER JOIN APCSProDB.method.material_set_list
																				  ON material_sets.id =  material_set_list.id
																				  INNER JOIN APCSProDB.material.productions
																				  ON productions.id = material_set_list.material_group_id
																				  WHERE lots.id  =  @lot_id
																				) AS production_name
														ON REPLACE(REPLACE(UPPER(#TEMP.Prod_name),' ',''),'MM','')   = REPLACE(REPLACE(UPPER(production_name.name),' ',''),'MM','') 
													)
									BEGIN 

													SELECT       'TRUE' AS Is_Pass
																,'' AS Error_Message_ENG
																,'' AS Error_Message_THA
																,'' AS Handling
																, #TEMP.Prod_name		AS  [Type]
																, #TEMP.Material_LotNo AS  Material_LotNo
																, productions.details	AS  Material_Type
																, #TEMP.Expire_Date	AS  Expire_Date
													FROM #TEMP 
													INNER JOIN   APCSProDB.material.productions
													ON REPLACE(REPLACE(UPPER(productions.name),' ',''),'MM','') =  REPLACE(REPLACE(UPPER(#TEMP.Prod_name),' ',''),'MM','')
 
									END 
									ELSE
												BEGIN 

										 		SELECT  'FALSE' AS Is_Pass
										 				,'Material is not Matching !!' AS Error_Message_ENG
										 				,N'Material ('+(Prod_name)+N') ไม่สามารถใช้ผลิตกับ Lot นี้ได้ !!' AS Error_Message_THA
										 				,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
										 		FROM #TEMP 
												END 
									END
						
							END
						ELSE
							BEGIN 
								SELECT  'FALSE' AS Is_Pass
										,'Please scan QR Code ' +@Material_type +N' correctly. !!' AS Error_Message_ENG
										,N'กรุณายิง QR Code ' +@Material_type +N' ให้ถูกต้อง!!!' AS Error_Message_THA
										,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
								 
							END 
						END 
							 
					ELSE
						BEGIN 
								SELECT  'FALSE' AS Is_Pass
										,'Information not found !!' AS Error_Message_ENG
										,N'ไม่พบข้อมูล Material นี้ ' AS Error_Message_THA
										,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
								FROM #TEMP 
						END 
					 
					DROP TABLE #TEMP
			END
			ELSE IF (@CheckCount2 = 2)
			BEGIN 
								CREATE TABLE #TEMP1
						(
								  Material_LotNo	NVARCHAR(100) 
								, Prod_name			NVARCHAR(100)
						 
						)
						INSERT INTO #TEMP1
					 
						SELECT * FROM   
						(
						  SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@QRCode,';') 

						) t 
						PIVOT
						(
						  MAX([value])
							FOR row_num IN (
								 [1] 
								,[2]
							 )
						) AS pivot_table 

						IF  EXISTS (SELECT id FROM    APCSProDB.material.productions WHERE  REPLACE(UPPER(name),' ','') = (SELECT REPLACE(UPPER(#TEMP1.Prod_name),' ','') FROM  #TEMP1))
					
						BEGIN 
						
							IF  EXISTS (SELECT id FROM    APCSProDB.material.productions WHERE  REPLACE(UPPER(name),' ','') = (SELECT REPLACE(UPPER(#TEMP1.Prod_name),' ','') FROM  #TEMP1)
																								AND productions.details =  @Material_type	)
									
							BEGIN 
 											SELECT @step_no_now = (
												CASE 
													WHEN [lots].[is_special_flow] = 1 then 
														(SELECT [step_no] FROM [APCSProDB].[trans].[special_flows] WITH (NOLOCK) WHERE [special_flows].[id] = [lots].[special_flow_id]) 
													ELSE [lots].[step_no]
												END ) 
											FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
											WHERE [lots].[id] = @lot_id
 
							--SET @Expire_Date  = (SELECT Expire_Date FROM #TEMP) 
							 --IF (@Expire_Date > GETDATE())
							 --BEGIN
								IF NOT  EXISTS (  SELECT  device_flows.material_set_id   
												 FROM APCSProDB.trans.lots  
												 INNER JOIN APCSProDB.method.device_flows
												 ON lots.device_slip_id = device_flows.device_slip_id
												 AND  device_flows.step_no =  @step_no_now
												  WHERE lots.id  =  @lot_id
												)
								BEGIN 
										SELECT  'FALSE' AS Is_Pass
												,'Device slips this material has not been registered yet !!' AS Error_Message_ENG
												,N'Device slips นี้ยังไม่ถูกลงทะเบียน Material' AS Error_Message_THA
												,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
										FROM #TEMP1 
								END 
								ELSE 
								BEGIN
										IF  EXISTS (SELECT Prod_name FROM  #TEMP1 INNER JOIN ( SELECT productions.name FROM APCSProDB.trans.lots
																								  INNER JOIN APCSProDB.method.device_flows
																								  ON lots.device_slip_id = device_flows.device_slip_id
																								  AND  device_flows.step_no = @step_no_now
																								  INNER JOIN APCSProDB.method.material_sets 
																								  ON  material_sets.process_id = device_flows.act_process_id
																								  AND device_flows.material_set_id = material_sets.id
																								  INNER JOIN APCSProDB.method.material_set_list
																								  ON material_sets.id =  material_set_list.id
																								  INNER JOIN APCSProDB.material.productions
																								  ON productions.id = material_set_list.material_group_id
																								  WHERE lots.id  =  @lot_id
																						) AS production_name
															ON REPLACE(UPPER(#TEMP1.Prod_name),' ','')  = REPLACE(UPPER(production_name.name),' ','') 
														)
										BEGIN 

														SELECT   'TRUE' AS Is_Pass
																 ,'' AS Error_Message_ENG
																 ,'' AS Error_Message_THA
																 ,'' AS Handling
																 , #TEMP1.Prod_name		AS  [Type]
																 , #TEMP1.Material_LotNo AS  Material_LotNo
																 , productions.details	AS  Material_Type
																 , ''	AS  Expire_Date
														FROM #TEMP1 
														INNER JOIN   APCSProDB.material.productions
														ON REPLACE(UPPER(productions.name),' ','')  = REPLACE(UPPER(#TEMP1.Prod_name),' ','')
 
										END 
										ELSE
												 BEGIN 
										 			SELECT  'FALSE' AS Is_Pass
										 					,'Material is not Matching !!' AS Error_Message_ENG
										 					,N'Material ('+(Prod_name)+N') ไม่สามารถใช้ผลิตกับ Lot นี้ได้ !!' AS Error_Message_THA
										 					,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
										 			FROM #TEMP1 
												 END 
										END
						
								END
							ELSE
								BEGIN 
									SELECT  'FALSE' AS Is_Pass
											,'Please scan QR Code ' +@Material_type +N' correctly. !!' AS Error_Message_ENG
											,N'กรุณายิง QR Code ' +@Material_type +N' ให้ถูกต้อง!!!' AS Error_Message_THA
											,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
								 
								END 
							END 
							 
						ELSE
							BEGIN 
									SELECT  'FALSE' AS Is_Pass
											,'Information not found !!' AS Error_Message_ENG
											,N'ไม่พบข้อมูล Material นี้ ' AS Error_Message_THA
											,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
								 
							END 
					 
						DROP TABLE #TEMP1
			END 
			ELSE IF (@CheckCount =  1)
			BEGIN 
							  SELECT   'TRUE'		AS Is_Pass
										,''			AS Error_Message_ENG
										,''			AS Error_Message_THA
										,''			AS Handling
										,''			AS [Type]
										,@QRCode	AS Material_LotNo
										,''			AS Material_Type
										,''			AS Expire_Date
			END 
			ELSE 
			BEGIN 
						SELECT  'FALSE' AS Is_Pass
								,'Format QR Code is not Matching !!' AS Error_Message_ENG
								,N'Format QR Code material นี้ไม่ถูกต้อง !!' AS Error_Message_THA
								,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
				 
			END 
		END 



	ELSE 
			BEGIN
	
				SELECT   'TRUE'		AS Is_Pass
						,''			AS Error_Message_ENG
						,''			AS Error_Message_THA
						,''			AS Handling
						,''			AS  [Type]
						,@QRCode	AS  Material_LotNo
						,''			AS  Material_Type
						,''			AS  Expire_Date
	
		END 
		
END