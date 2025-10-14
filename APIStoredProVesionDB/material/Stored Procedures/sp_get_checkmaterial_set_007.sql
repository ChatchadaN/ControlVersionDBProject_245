-- =============================================
-- Author:		SADANU
-- Create date: 2023/01/13
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_checkmaterial_set_007]
	-- Add the parameters for the stored procedure here
		 @LotNo				NVARCHAR(20)   = NULL
	  ,  @QRCode			NVARCHAR(MAX)  = NULL  
	  ,  @McNo				NVARCHAR(20)
	  ,  @OpNO				NVARCHAR(20)
	  ,  @App_Name			NVARCHAR(50)
	  ,  @Material_type		NVARCHAR(50)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	
	-- interfering with SELECT statements.
	   
PRINT @QRCode

	DECLARE  @lot_id		INT 
	,  @step_no_now			INT 
	,  @Expire_Date			DATETIME 
	,  @package_id			INT 
	,  @CheckCount			INT		= 0
	,  @CheckCount2			INT		= 0
	,  @CheckCount3			INT		= 0
	,  @material_set_id		INT     = NULL
	,  @is_special_flow		INT		= NULL 
	,  @special_flow_id		INT		= NULL 

	  SELECT	  @lot_id		=  id 
				, @package_id	= act_package_id    
				, @is_special_flow = is_special_flow
				, @special_flow_id = special_flow_id

	  FROM APCSProDB.trans.lots
	  WHERE lot_no =  @LotNo
	  
SET @CheckCount = ( SELECT COUNT(*)  FROM STRING_SPLIT(@QRCode,',') ) --000949,25.5MM,2NS013-0246,2023/09/14,2024/11/01
SET @CheckCount2 = ( SELECT COUNT(*)  FROM STRING_SPLIT(@QRCode,';') ) --M30617413604-05;A0254
SET @CheckCount3 = ( SELECT COUNT(*)  FROM STRING_SPLIT(@QRCode,' ') ) --C1010BS 130502-1557
 
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

		--OPEN 2023/05/30
		--80	HTSSOP-A44          
		--81	HTSSOP-A44R         
		--88	HTSSOP-B54          
		--89	HTSSOP-B54R   
		--232	SSOP-A54_2
		--233	SSOP-A54_3
		--242	SSOP-B20W 
		
		--OPEN 2023/10/17
		--121   QFP32
		--505	VQFP48C             
		--103	MSOP8   
		--53	HRP5    
		--54	HRP7      

		--OPEN 2023/10/24
		--218	SSON004R1010        
		--219	SSON004X1010      
		
		--OPEN 2032/12/22
		--53	HRP5                
		--54	HRP7                
		--62	HSON8-HF            
		--63	HSON-A8             
		--68	HSOP-M36            
		--87	HTSSOP-B40          
		--102	MSOP10              
		--103	MSOP8               
		--104	MSOP8-HF            
		--175	SOP20               
		--176	SOP22               
		--177	SOP24               
		--196	SOT223-4            
		--197	SOT223-4F           
		--225	SSOP-A20            
		--227	SSOP-A24            
		--230	SSOP-A32            
		--243	SSOP-B24            
		--245	SSOP-B28            
		--265	TO252-3             
		--266	TO252-5             
		--267	TO252-J3            
		--268	TO252-J5            
		--270	TO252S-3            
		--272	TO252S-5            
		--275	TO263-3             
		--276	TO263-3F            
		--277	TO263-5             
		--278	TO263-5F            
		--279	TO263-7             
		--301	TSSOP-B8J           
		--601	TO263-7L            


		
	IF(@Material_type = 'REEL') --20230706 CHECK REEL 
	BEGIN 
				
 			SET @material_set_id = (SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].material_set_id 
																ELSE device_flows.material_set_id   END 
																FROM APCSProDB.trans.lots  
																INNER JOIN APCSProDB.method.device_flows
																ON lots.device_slip_id = device_flows.device_slip_id
																AND  device_flows.step_no =  lots.step_no
																LEFT JOIN [APCSProDB].[trans].[special_flows] 
																ON [special_flows].lot_id = lots.id 
																AND [special_flows].id	  = lots.special_flow_id
																AND lots.is_special_flow  = 1
																LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
																ON [special_flows].id = [lot_special_flows].special_flow_id
																AND [lot_special_flows].step_no =  [special_flows].step_no
																WHERE  lots.id  =   @lot_id )

			IF @material_set_id IS NULL	 			 
				BEGIN 
						SELECT  'FALSE' AS Is_Pass
								,'Device slips this material has not been registered yet !!' AS Error_Message_ENG
								,N'Device slips นี้ยังไม่ถูกลงทะเบียน Material' AS Error_Message_THA
								,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
						RETURN			 
				END 
				ELSE 
				BEGIN
						IF  EXISTS ( SELECT productions.name  FROM 
										(SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].material_set_id 
												 ELSE device_flows.material_set_id   END  AS material_set_id  
												 ,  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].act_process_id 
												 ELSE device_flows.act_process_id   END  AS act_process_id 
										FROM APCSProDB.trans.lots  
										INNER JOIN APCSProDB.method.device_flows
										ON lots.device_slip_id = device_flows.device_slip_id
										AND  device_flows.step_no =  lots.step_no
										LEFT JOIN [APCSProDB].[trans].[special_flows] 
										ON [special_flows].lot_id = lots.id 
										AND [special_flows].id	  = lots.special_flow_id
										AND lots.is_special_flow  = 1
										LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
										ON [special_flows].id = [lot_special_flows].special_flow_id
										AND [lot_special_flows].step_no =  [special_flows].step_no
										WHERE  lots.id  =   @lot_id )   AS sp_material
										INNER JOIN APCSProDB.method.material_sets 
										ON  material_sets.process_id = sp_material.act_process_id
										AND sp_material.material_set_id = material_sets.id
										INNER JOIN APCSProDB.method.material_set_list
										ON material_sets.id =  material_set_list.id
										INNER JOIN APCSProDB.material.productions
										ON productions.id = material_set_list.material_group_id
										WHERE  productions.name = @QRCode
										)
						BEGIN 

										SELECT     'TRUE' AS Is_Pass
												 , '' AS Error_Message_ENG
												 , '' AS Error_Message_THA
												 , '' AS Handling
												 , productions.details		AS  [Type]
												 , '' AS  Material_LotNo
												 , productions.name	AS  Material_Type
												 , ''	AS  Expire_Date
										FROM   APCSProDB.material.productions
										WHERE  productions.name  = @QRCode
										RETURN
														
						END 
						ELSE
						BEGIN 
									SELECT  'FALSE' AS Is_Pass
										 	,'Material is not Matching !!' AS Error_Message_ENG
										 	,N'Material ('+(@QRCode)+N') ไม่สามารถใช้ผลิตกับ Lot นี้ได้ !!' AS Error_Message_THA
										 	,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
										 					 
									RETURN
						END 
			END
						
	END	

	IF (@package_id IN  (80,81,88,89,82, 87, 91,232,233, 246 ,242, 121, 505, 103  ,218 , 219  ,269 
						 ,53,54,62,63,68,87,102,103,104,175,176,177,196,197,225,227,230,243,245,265,266,267,268,270,272,275,276,277,278,279,301,601 ))	
		BEGIN

			IF (@CheckCount = 5)
			BEGIN
			 
				IF EXISTS (SELECT 'xxx' FROM APCSProDB.man.users  WHERE emp_num = 	(SELECT TOP 1    *  FROM STRING_SPLIT(@QRCode,',')))
				BEGIN 
	    		CREATE TABLE #TEMP_RIST
						(
								  Material_LotNo	NVARCHAR(100) 
								, Qty				NVARCHAR(100)
								, Expire_Date		NVARCHAR(100)
								, Prod_name			NVARCHAR(100)
								, PN				NVARCHAR(100)
						)
						INSERT INTO #TEMP_RIST
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
						IF NOT EXISTS (SELECT id FROM    APCSProDB.material.productions WHERE  REPLACE(UPPER(name),' ','') = (SELECT REPLACE(UPPER(#TEMP_RIST.Prod_name),' ','') FROM  #TEMP_RIST)
																								AND productions.details =  @Material_type	)
							BEGIN 
				-- PIVOT COVER TAPE ( 9.5MM,LOTNO,2023/03/31,2024/03/31,00000 )
									DELETE FROM #TEMP_RIST
			
									INSERT INTO #TEMP_RIST
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
 						IF NOT EXISTS (SELECT id FROM    APCSProDB.material.productions WHERE REPLACE(REPLACE(UPPER(productions.name),' ',''),'MM','') = (SELECT  REPLACE(REPLACE(UPPER(#TEMP_RIST.Prod_name),' ',''),'MM','') FROM  #TEMP_RIST)
																								AND productions.details =  @Material_type	)
							BEGIN 
									DELETE FROM #TEMP_RIST

				-- PIVOT COVER TAPE ( 00000,9.5MM,2023/03/31,QQQQ,2024/03/31 )

									INSERT INTO #TEMP_RIST
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
							
							 

								IF (( SELECT CASE WHEN ISDATE(Expire_Date) = 1   THEN 1 ELSE 0 END  FROM #TEMP_RIST) =  0)
								BEGIN 
										 UPDATE #TEMP_RIST
									 SET  Expire_Date   = CONVERT(varchar,DATEADD(mm, DATEDIFF(mm,0,'01.'+ Expire_Date), 0),111) 
										, Prod_name			= Prod_name+'MM'
									 FROM #TEMP_RIST
								END  
							 

							END 	
					  
				-- CHECK COVER TAPE,EMBOSS TAPE AFTER PIVOT

						IF  EXISTS (SELECT id FROM  APCSProDB.material.productions WHERE REPLACE(UPPER(productions.name),' ','') = (SELECT REPLACE(UPPER(#TEMP_RIST.Prod_name),' ','') FROM  #TEMP_RIST))
						BEGIN 
				-- CHECK TYPE IN DB
							IF  EXISTS (SELECT id FROM    APCSProDB.material.productions WHERE REPLACE(UPPER(productions.name),' ','') = (SELECT  REPLACE(UPPER(#TEMP_RIST.Prod_name),' ','') FROM  #TEMP_RIST)
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

									--SET @material_set_id = ( SELECT  device_flows.material_set_id   
									--				FROM APCSProDB.trans.lots  
									--				INNER JOIN APCSProDB.method.device_flows
									--				ON lots.device_slip_id = device_flows.device_slip_id
									--				AND  device_flows.step_no =  @step_no_now
									--				WHERE  lots.id  =  @lot_id )

								SET @material_set_id = (SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].material_set_id 
														ELSE device_flows.material_set_id   END 
														FROM APCSProDB.trans.lots  
														INNER JOIN APCSProDB.method.device_flows
														ON lots.device_slip_id = device_flows.device_slip_id
														AND  device_flows.step_no =  lots.step_no
														LEFT JOIN [APCSProDB].[trans].[special_flows] 
														ON [special_flows].lot_id = lots.id 
														AND [special_flows].id	  = lots.special_flow_id
														AND lots.is_special_flow  = 1
														LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
														ON [special_flows].id = [lot_special_flows].special_flow_id
														AND [lot_special_flows].step_no =  [special_flows].step_no
														WHERE  lots.id  =   @lot_id )
			
								 
				-- CHECK MATERIAL SET ID IN DB
							
								IF @material_set_id IS NULL	 			 
								BEGIN 
										

										SELECT  'FALSE' AS Is_Pass
												,'Device slips this material has not been registered yet !!' AS Error_Message_ENG
												,N'Device slips นี้ยังไม่ถูกลงทะเบียน Material' AS Error_Message_THA
												,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
												, @material_set_id AS  material_set_id
										FROM #TEMP_RIST 
										RETURN
								END 
								ELSE 
								BEGIN
				-- CHECK MATERIAL IS MATCHING WITH LOT
								IF  EXISTS (SELECT Prod_name FROM  #TEMP_RIST INNER JOIN (SELECT productions.name  FROM 
																						(SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].material_set_id 
																						ELSE device_flows.material_set_id   END  AS material_set_id  
																						,  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].act_process_id 
																						ELSE device_flows.act_process_id   END  AS act_process_id 
																						FROM APCSProDB.trans.lots  
																						INNER JOIN APCSProDB.method.device_flows
																						ON lots.device_slip_id = device_flows.device_slip_id
																						AND  device_flows.step_no =  lots.step_no
																						LEFT JOIN [APCSProDB].[trans].[special_flows] 
																						ON [special_flows].lot_id = lots.id 
																						AND [special_flows].id	  = lots.special_flow_id
																						AND lots.is_special_flow  = 1
																						LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
																						ON [special_flows].id = [lot_special_flows].special_flow_id
																						AND [lot_special_flows].step_no =  [special_flows].step_no
																						WHERE  lots.id  = @lot_id)   AS sp_material
																						INNER JOIN APCSProDB.method.material_sets 
																						ON  material_sets.process_id = sp_material.act_process_id
																						AND sp_material.material_set_id = material_sets.id
																						INNER JOIN APCSProDB.method.material_set_list
																						ON material_sets.id =  material_set_list.id
																						INNER JOIN APCSProDB.material.productions
																						ON productions.id = material_set_list.material_group_id
																					) AS production_name
															ON REPLACE(REPLACE(UPPER(#TEMP_RIST.Prod_name),' ',''),'MM','')   = REPLACE(REPLACE(UPPER(production_name.name),' ',''),'MM','') 
														)
										BEGIN 

														SELECT       'TRUE' AS Is_Pass
																	,'' AS Error_Message_ENG
																	,'' AS Error_Message_THA
																	,'' AS Handling
																	, #TEMP_RIST.Prod_name		AS  [Type]
																	, #TEMP_RIST.Material_LotNo AS  Material_LotNo
																	, productions.details	AS  Material_Type
																	, #TEMP_RIST.Expire_Date	AS  Expire_Date
														FROM #TEMP_RIST 
														INNER JOIN   APCSProDB.material.productions
														ON REPLACE(REPLACE(UPPER(productions.name),' ',''),'MM','') =  REPLACE(REPLACE(UPPER(#TEMP_RIST.Prod_name),' ',''),'MM','')
 

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
															,'TRUE'  + ' , ' +CAST( #TEMP_RIST.Prod_name  AS nvarchar(MAX))+ ' , ' + CAST(#TEMP_RIST.Material_LotNo AS nvarchar(MAX))+ ' , ' + CAST(productions.details AS nvarchar(MAX)) + ' , ' + CAST( #TEMP_RIST.Expire_Date AS nvarchar(MAX))
															, @LotNo
														FROM #TEMP_RIST 
														INNER JOIN   APCSProDB.material.productions
														ON REPLACE(REPLACE(UPPER(productions.name),' ',''),'MM','') =  REPLACE(REPLACE(UPPER(#TEMP_RIST.Prod_name),' ',''),'MM','')



										END 
										ELSE
													BEGIN 

										 			SELECT  'FALSE' AS Is_Pass
										 					,'Material is not Matching !!' AS Error_Message_ENG
										 					,N'Material ('+(Prod_name)+N') ไม่สามารถใช้ผลิตกับ Lot นี้ได้ !!' AS Error_Message_THA
										 					,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
										 			FROM #TEMP_RIST 
													RETURN
													END 
										END
						
								END


							ELSE
								BEGIN 
									SELECT  'FALSE' AS Is_Pass
											,'Please scan QR Code ' +@Material_type +N' correctly. !!' AS Error_Message_ENG
											,N'กรุณายิง QR Code ' +@Material_type +N' ให้ถูกต้อง!!!' AS Error_Message_THA
											,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
											RETURN
								 
								END 
							END 
							 
						ELSE
							BEGIN 
									SELECT  'FALSE' AS Is_Pass
											,'Information not found !!' AS Error_Message_ENG
											,N'ไม่พบข้อมูล Material นี้ ' AS Error_Message_THA
											,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
									FROM #TEMP_RIST 
									RETURN
							END 
					 
						 DROP TABLE #TEMP_RIST
		 END 
				ELSE
				BEGIN 
				
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
					 
					-- CHECK COVER HAVE IN DB
							IF  EXISTS (SELECT id FROM    APCSProDB.material.productions WHERE  REPLACE(UPPER(name),' ','') = (SELECT REPLACE(UPPER(#TEMP.Prod_name),' ','') FROM  #TEMP)
																									AND productions.details =  'COVER TAPE'	)
								BEGIN 
					-- PIVOT COVER TAPE (Z7400,13.5MM,500,2DS0971A15,Dec.2024)
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
												 [4]
												,[1]
												,[5] 
												,[2]
												,[3]
												)
										) AS pivot_table 

								IF (( SELECT CASE WHEN ISDATE(Expire_Date) = 1   THEN 1 ELSE 0 END  FROM #TEMP) =  0)
								BEGIN 

										 UPDATE #TEMP
										 SET  Expire_Date   = CONVERT(varchar,DATEADD(mm, DATEDIFF(mm,0,'01.'+Expire_Date), 0),111) 
										 FROM #TEMP
								END
								 
							END 

 					-- PIVOT COVER TAPE ( Z7400,13.5,500,2DS0971A15,Dec.2024 )
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
								 
								 
										IF (( SELECT CASE WHEN ISDATE(Expire_Date) = 1   THEN 1 ELSE 0 END FROM #TEMP) = 0)
										BEGIN 
										 UPDATE #TEMP
										 SET  Expire_Date   = CONVERT(varchar,DATEADD(mm, DATEDIFF(mm,0,'01.'+ Expire_Date), 0),111) 
											, Prod_name			= Prod_name+'MM'
										 FROM #TEMP
										END 
								  
								END 	

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
												 [4]
												,[1]
												,[5] 
												,[2]
												,[3]
												)
										) AS pivot_table 


										IF (( SELECT CASE WHEN ISDATE(Expire_Date) = 1   THEN 1 ELSE 0 END FROM #TEMP) = 0)
										BEGIN 
										 UPDATE #TEMP
										 SET  Expire_Date   = CONVERT(varchar,DATEADD(mm, DATEDIFF(mm,0,'01.'+ Expire_Date), 0),111) 
											, Prod_name			= Prod_name+'MM'
										 FROM #TEMP
										END 
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
									--SET @material_set_id = ( SELECT  device_flows.material_set_id   
									--													FROM APCSProDB.trans.lots  
									--													INNER JOIN APCSProDB.method.device_flows
									--													ON lots.device_slip_id = device_flows.device_slip_id
									--													AND  device_flows.step_no =  @step_no_now
									--													WHERE lots.id  =  @lot_id)

									SET @material_set_id = (SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].material_set_id 
																ELSE device_flows.material_set_id   END 
																FROM APCSProDB.trans.lots  
																INNER JOIN APCSProDB.method.device_flows
																ON lots.device_slip_id = device_flows.device_slip_id
																AND  device_flows.step_no =  lots.step_no
																LEFT JOIN [APCSProDB].[trans].[special_flows] 
																ON [special_flows].lot_id = lots.id 
																AND [special_flows].id	  = lots.special_flow_id
																AND lots.is_special_flow  = 1
																LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
																ON [special_flows].id = [lot_special_flows].special_flow_id
																AND [lot_special_flows].step_no =  [special_flows].step_no
																WHERE  lots.id  =   @lot_id )
			
			
					-- CHECK MATERIAL SET ID IN DB

									IF @material_set_id IS NULL							 
									BEGIN 
											SELECT  'FALSE' AS Is_Pass
													,'Device slips this material has not been registered yet !!' AS Error_Message_ENG
													,N'Device slips นี้ยังไม่ถูกลงทะเบียน Material' AS Error_Message_THA
													,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
													, @material_set_id AS  material_set_id
											FROM #TEMP 
											RETURN
									END 
									ELSE 
									BEGIN
 
					-- CHECK MATERIAL IS MATCHING WITH LOT
									IF  EXISTS (SELECT Prod_name FROM  #TEMP INNER JOIN (SELECT productions.name  FROM 
																						(SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].material_set_id 
																						ELSE device_flows.material_set_id   END  AS material_set_id  
																						,  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].act_process_id 
																						ELSE device_flows.act_process_id   END  AS act_process_id 
																						FROM APCSProDB.trans.lots  
																						INNER JOIN APCSProDB.method.device_flows
																						ON lots.device_slip_id = device_flows.device_slip_id
																						AND  device_flows.step_no =  lots.step_no
																						LEFT JOIN [APCSProDB].[trans].[special_flows] 
																						ON [special_flows].lot_id = lots.id 
																						AND [special_flows].id	  = lots.special_flow_id
																						AND lots.is_special_flow  = 1
																						LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
																						ON [special_flows].id = [lot_special_flows].special_flow_id
																						AND [lot_special_flows].step_no =  [special_flows].step_no
																						WHERE  lots.id  = @lot_id)   AS sp_material
																						INNER JOIN APCSProDB.method.material_sets 
																						ON  material_sets.process_id = sp_material.act_process_id
																						AND sp_material.material_set_id = material_sets.id
																						INNER JOIN APCSProDB.method.material_set_list
																						ON material_sets.id =  material_set_list.id
																						INNER JOIN APCSProDB.material.productions
																						ON productions.id = material_set_list.material_group_id
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
														,'TRUE'  + ' , ' +CAST( #TEMP.Prod_name  AS nvarchar(MAX))+ ' , ' + CAST(#TEMP.Material_LotNo AS nvarchar(MAX))+ ' , ' + CAST(productions.details AS nvarchar(MAX)) + ' , ' + CAST(#TEMP.Expire_Date AS nvarchar(MAX))
														, @LotNo
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
														RETURN
														END 
											END
						
									END
								ELSE
									BEGIN 
										SELECT  'FALSE' AS Is_Pass
												,'Please scan QR Code ' +@Material_type +N' correctly. !!' AS Error_Message_ENG
												,N'กรุณายิง QR Code ' +@Material_type +N' ให้ถูกต้อง!!!' AS Error_Message_THA
												,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
												RETURN
								 
									END 
								END 
							 
							ELSE
								BEGIN 
										SELECT  'FALSE' AS Is_Pass
												,'Information not found !!' AS Error_Message_ENG
												,N'ไม่พบข้อมูล Material นี้ ' AS Error_Message_THA
												,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
										FROM #TEMP 
										RETURN
								END 
					 
							 DROP TABLE #TEMP
						END

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


										SET @material_set_id = (SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].material_set_id 
																	ELSE device_flows.material_set_id   END 
																	FROM APCSProDB.trans.lots  
																	INNER JOIN APCSProDB.method.device_flows
																	ON lots.device_slip_id = device_flows.device_slip_id
																	AND  device_flows.step_no =  lots.step_no
																	LEFT JOIN [APCSProDB].[trans].[special_flows] 
																	ON [special_flows].lot_id = lots.id 
																	AND [special_flows].id	  = lots.special_flow_id
																	AND lots.is_special_flow  = 1
																	LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
																	ON [special_flows].id = [lot_special_flows].special_flow_id
																	AND [lot_special_flows].step_no =  [special_flows].step_no
																	WHERE  lots.id  =   @lot_id )
			
			
						-- CHECK MATERIAL SET ID IN DB

										IF @material_set_id IS NULL							 
										BEGIN 
												SELECT  'FALSE' AS Is_Pass
														,'Device slips this material has not been registered yet !!' AS Error_Message_ENG
														,N'Device slips นี้ยังไม่ถูกลงทะเบียน Material' AS Error_Message_THA
														,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
												FROM #TEMP1
												RETURN
										END 
										ELSE 
										BEGIN
												IF  EXISTS (SELECT Prod_name FROM  #TEMP1 INNER JOIN ( SELECT productions.name  FROM 
																						(SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].material_set_id 
																						ELSE device_flows.material_set_id   END  AS material_set_id  
																						,  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].act_process_id 
																						ELSE device_flows.act_process_id   END  AS act_process_id 
																						FROM APCSProDB.trans.lots  
																						INNER JOIN APCSProDB.method.device_flows
																						ON lots.device_slip_id = device_flows.device_slip_id
																						AND  device_flows.step_no =  lots.step_no
																						LEFT JOIN [APCSProDB].[trans].[special_flows] 
																						ON [special_flows].lot_id = lots.id 
																						AND [special_flows].id	  = lots.special_flow_id
																						AND lots.is_special_flow  = 1
																						LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
																						ON [special_flows].id = [lot_special_flows].special_flow_id
																						AND [lot_special_flows].step_no =  [special_flows].step_no
																						WHERE  lots.id  = @lot_id)   AS sp_material
																						INNER JOIN APCSProDB.method.material_sets 
																						ON  material_sets.process_id = sp_material.act_process_id
																						AND sp_material.material_set_id = material_sets.id
																						INNER JOIN APCSProDB.method.material_set_list
																						ON material_sets.id =  material_set_list.id
																						INNER JOIN APCSProDB.material.productions
																						ON productions.id = material_set_list.material_group_id
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
																RETURN
														
												END 
												ELSE
														 BEGIN 
										 					SELECT  'FALSE' AS Is_Pass
										 							,'Material is not Matching !!' AS Error_Message_ENG
										 							,N'Material ('+(Prod_name)+N') ไม่สามารถใช้ผลิตกับ Lot นี้ได้ !!' AS Error_Message_THA
										 							,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
										 					FROM #TEMP1 
															RETURN
														 END 
												END
						
										END
									ELSE
										BEGIN 
											SELECT  'FALSE' AS Is_Pass
													,'Please scan QR Code ' +@Material_type +N' correctly. !!' AS Error_Message_ENG
													,N'กรุณายิง QR Code ' +@Material_type +N' ให้ถูกต้อง!!!' AS Error_Message_THA
													,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
													RETURN
								 
										END 
									END 
							 
								ELSE
									BEGIN 
											SELECT  'FALSE' AS Is_Pass
													,'Information not found !!' AS Error_Message_ENG
													,N'ไม่พบข้อมูล Material นี้ ' AS Error_Message_THA
													,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
													RETURN
								 
									END 
					 
								 
				END 
			
			ELSE IF (@CheckCount3 =  2)	--'C1010BS 130502-1557'
			BEGIN 
										CREATE TABLE #TEMP2
								(
										  Prod_name					NVARCHAR(100) 
										, Material_LotNo			NVARCHAR(100)
						 
								)
								INSERT INTO #TEMP2
								SELECT * FROM   
								(
								  SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@QRCode,' ') 

								) t 
								PIVOT
								(
								  MAX([value])
									FOR row_num IN (
										  [1] 
										, [2]
										 
									 )
								) AS pivot_table 

								IF  EXISTS (SELECT id FROM    APCSProDB.material.productions WHERE  REPLACE(UPPER(name),' ','') = (SELECT REPLACE(UPPER(#TEMP2.Prod_name),' ','') FROM  #TEMP2))
					
								BEGIN 
						
									IF  EXISTS (SELECT id FROM    APCSProDB.material.productions WHERE  REPLACE(UPPER(name),' ','') = (SELECT REPLACE(UPPER(#TEMP2.Prod_name),' ','') FROM  #TEMP2)
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


										SET @material_set_id = (SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].material_set_id 
																	ELSE device_flows.material_set_id   END 
																	FROM APCSProDB.trans.lots  
																	INNER JOIN APCSProDB.method.device_flows
																	ON lots.device_slip_id = device_flows.device_slip_id
																	AND  device_flows.step_no =  lots.step_no
																	LEFT JOIN [APCSProDB].[trans].[special_flows] 
																	ON [special_flows].lot_id = lots.id 
																	AND [special_flows].id	  = lots.special_flow_id
																	AND lots.is_special_flow  = 1
																	LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
																	ON [special_flows].id = [lot_special_flows].special_flow_id
																	AND [lot_special_flows].step_no =  [special_flows].step_no
																	WHERE  lots.id  =   @lot_id )
			
						-- CHECK MATERIAL SET ID IN DB

										IF @material_set_id IS NULL							 
										BEGIN 
												SELECT  'FALSE' AS Is_Pass
														,'Device slips this material has not been registered yet !!' AS Error_Message_ENG
														,N'Device slips นี้ยังไม่ถูกลงทะเบียน Material' AS Error_Message_THA
														,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
												FROM #TEMP2
												RETURN
										END 
										ELSE 
										BEGIN
												IF  EXISTS (SELECT Prod_name FROM  #TEMP2 INNER JOIN ( SELECT productions.name  FROM 
																						(SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].material_set_id 
																						ELSE device_flows.material_set_id   END  AS material_set_id  
																						,  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].act_process_id 
																						ELSE device_flows.act_process_id   END  AS act_process_id 
																						FROM APCSProDB.trans.lots  
																						INNER JOIN APCSProDB.method.device_flows
																						ON lots.device_slip_id = device_flows.device_slip_id
																						AND  device_flows.step_no =  lots.step_no
																						LEFT JOIN [APCSProDB].[trans].[special_flows] 
																						ON [special_flows].lot_id = lots.id 
																						AND [special_flows].id	  = lots.special_flow_id
																						AND lots.is_special_flow  = 1
																						LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
																						ON [special_flows].id = [lot_special_flows].special_flow_id
																						AND [lot_special_flows].step_no =  [special_flows].step_no
																						WHERE  lots.id  = @lot_id)   AS sp_material
																						INNER JOIN APCSProDB.method.material_sets 
																						ON  material_sets.process_id = sp_material.act_process_id
																						AND sp_material.material_set_id = material_sets.id
																						INNER JOIN APCSProDB.method.material_set_list
																						ON material_sets.id =  material_set_list.id
																						INNER JOIN APCSProDB.material.productions
																						ON productions.id = material_set_list.material_group_id
																					) AS production_name
																	ON REPLACE(UPPER(#TEMP2.Prod_name),' ','')  = REPLACE(UPPER(production_name.name),' ','') 
																)
												BEGIN 

																SELECT   'TRUE' AS Is_Pass
																		 ,'' AS Error_Message_ENG
																		 ,'' AS Error_Message_THA
																		 ,'' AS Handling
																		 , #TEMP2.Prod_name		AS  [Type]
																		 , #TEMP2.Material_LotNo AS  Material_LotNo
																		 , productions.details	AS  Material_Type
																		 , ''	AS  Expire_Date
																FROM #TEMP2 
																INNER JOIN   APCSProDB.material.productions
																ON REPLACE(UPPER(productions.name),' ','')  = REPLACE(UPPER(#TEMP2.Prod_name),' ','')
																RETURN
														
												END 
												ELSE
														 BEGIN 
										 					SELECT  'FALSE' AS Is_Pass
										 							,'Material is not Matching !!' AS Error_Message_ENG
										 							,N'Material ('+(Prod_name)+N') ไม่สามารถใช้ผลิตกับ Lot นี้ได้ !!' AS Error_Message_THA
										 							,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
										 					FROM #TEMP2 
															RETURN
														 END 
												END
						
										END
									ELSE
										BEGIN 
											SELECT  'FALSE' AS Is_Pass
													,'Please scan QR Code ' +@Material_type +N' correctly. !!' AS Error_Message_ENG
													,N'กรุณายิง QR Code ' +@Material_type +N' ให้ถูกต้อง!!!' AS Error_Message_THA
													,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
													RETURN
								 
										END 
									END 
							 
								ELSE
									BEGIN 
											SELECT  'FALSE' AS Is_Pass
													,'Information not found !!' AS Error_Message_ENG
													,N'ไม่พบข้อมูล Material นี้ ' AS Error_Message_THA
													,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
													RETURN
								 
									END 
					 
								 
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
							 
						RETURN
			END 
		END 
		ELSE 
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
		
END