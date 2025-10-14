-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_checkmaterial_set]
	-- Add the parameters for the stored procedure here
	 
		 @LotNo			NVARCHAR(20)  = NULL
	  ,  @QRCode		NVARCHAR(MAX)  = NULL -- 'G15,D0328W,2Y21JJ0632,1 Roll,2022/11/24'
	  ,  @McNo			NVARCHAR(20)
	  ,  @OpNO			NVARCHAR(20)
	  ,  @App_Name		NVARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	   
	DECLARE  @lot_id INT ,  @step_no_now   INT 

	  SELECT @lot_id =  id  FROM APCSProDB.trans.lots
	  WHERE lot_no =  @LotNo

CREATE TABLE #TEMP
(
		  LotNo			NVARCHAR(100) 
		, Qty			NVARCHAR(20)
		, Expire_Date	NVARCHAR(20)
		, Prod_name		NVARCHAR(100)
		, PN			NVARCHAR(20)
)
INSERT INTO #TEMP
  SELECT * FROM   
(
  SELECT ROW_NUMBER() OVER ( ORDER BY [value] ) row_num,  *  FROM STRING_SPLIT(@QRCode,',') 

) t 
PIVOT
(
  MAX([value])
    FOR row_num IN (
         [3] 
        ,[1]
		,[2]
		,[4] 
		,[5]    
     )
) AS pivot_table 
IF NOT EXISTS (SELECT id FROM    APCSProDB.material.productions 
WHERE  name = (SELECT Prod_name FROM  #TEMP))
BEGIN 

		DELETE FROM #TEMP

		INSERT INTO #TEMP
		 SELECT * FROM   
		(
		  SELECT ROW_NUMBER() OVER ( ORDER BY [value] ) row_num,  *  FROM STRING_SPLIT(@QRCode,',') 
		
		) t 
		PIVOT
		(
		  MAX([value])
		    FOR row_num IN (
		        [2]
		        ,[3]
				,[4]  
				,[5]
				,[1]  
		     )
		) AS pivot_table 
END 
 		 
 	SELECT @step_no_now = (
			CASE 
				WHEN [lots].[is_special_flow] = 1 then 
					(SELECT [step_no] FROM [APCSProDB].[trans].[special_flows] WITH (NOLOCK) WHERE [special_flows].[id] = [lots].[special_flow_id]) 
			   ELSE [lots].[step_no]
			END ) 
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		WHERE [lots].[id] = @lot_id

	 --SELECT *  FROM #TEMP
		--SELECT productions.name 
		--FROM APCSProDB.trans.lots
		--INNER JOIN APCSProDB.method.device_flows
		--ON lots.device_slip_id = device_flows.device_slip_id
		--AND  device_flows.step_no = @step_no_now
		--INNER JOIN APCSProDB.method.material_sets 
		--ON  material_sets.process_id = device_flows.act_process_id
		--AND device_flows.material_set_id = material_sets.id
		--INNER JOIN APCSProDB.method.material_set_list
		--ON material_sets.id =  material_set_list.id
		--INNER JOIN APCSProDB.material.productions
		--ON productions.id = material_set_list.material_group_id
		--WHERE lot_no =  @lot_no
		 

		IF  EXISTS (SELECT Prod_name FROM  #TEMP
				INNER JOIN (
				SELECT productions.name 
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
				ON REPLACE(UPPER(#TEMP.Prod_name),' ','')  = REPLACE(UPPER(production_name.name),' ','')
			)

		BEGIN 

				SELECT   'TRUE' AS Is_Pass
						 ,'' AS Error_Message_ENG
						 ,'' AS Error_Message_THA
						 ,'' AS Handling
						 ,'' AS Warning
						 , #TEMP.Prod_name		AS  [Type]
						 , @LotNo 				AS  Lot_NO
						 , #TEMP.Expire_Date	AS  Expire_Date
				FROM #TEMP
 
		END 
ELSE
		BEGIN 
		
				SELECT  'FALSE' AS Is_Pass,
						'('+(Prod_name)+') Unregistered !!' AS Error_Message_ENG,
						'('+(Prod_name)+N')  ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
						,'' AS Handling
						,N'กรุณาตรวจสอบข้อมูลที่ Web Jig' AS Warning
				FROM #TEMP 
		END 


DROP TABLE #TEMP


END
