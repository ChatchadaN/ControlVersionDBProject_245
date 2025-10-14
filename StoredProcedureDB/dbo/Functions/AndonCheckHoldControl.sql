
 CREATE FUNCTION  [dbo].[AndonCheckHoldControl]
 (
	@lot_no AS VARCHAR(10) = NULL
	,@AppName AS VARCHAR(MAX) = NULL
 )
RETURNS  
	  @table_andon table (
		[status]   INT
	)
BEGIN 
			
		DECLARE  @lot_id AS INT
				,@andon_id AS INT
				,@normal AS INT 
				,@abnormal AS INT 

		SET @lot_id = (SELECT lots.id FROM APCSProDB.trans.lots where lot_no = @lot_no )
	
		 
			
			 IF NOT EXISTS (SELECT 'xxx' FROM   APCSProDB.trans.lot_andon_records 
						INNER JOIN  APCSProDB.trans.andon_controls 
						ON lot_andon_records.andon_control_id =  andon_controls.id
						WHERE lot_andon_records.lot_id = @lot_id
						 AND is_solved IS NULL
						)
			 BEGIN 
			  
			  -- UPDATE  is_held , 0    FROM   APCSProDB.trans.lot_hold_controls

					INSERT INTO @table_andon SELECT   CAST(1 AS BIT) AS [status]
			 
			 END 
			 ELSE
			 BEGIN 
			   --NO UPDATE  is_held = 0    FROM   APCSProDB.trans.lot_hold_controls

					INSERT INTO @table_andon SELECT   CAST(0 AS BIT) AS [status]
			 
			 END

  RETURN
 END 

 --SELECT * FROM   [dbo].[AndonCheckHoldControl] ('2229D3978V', 'andon') 





--DECLARE  @lot_id AS INT
--		,@andon_id AS INT
--		,@normal AS INT 
--		,@abnormal AS INT 
--		,@lot_no AS VARCHAR(10) = '1234A1234V' 
--		,@AppName AS VARCHAR(MAX) = 'Lot stop instruction'


--SET @lot_id = (SELECT lots.id FROM APCSProDB.trans.lots where lot_no = @lot_no )

--SELECT  'xxx' FROM   APCSProDB.trans.lot_hold_controls
--WHERE lot_id =  @lot_id


 --SELECT  * FROM APCSProDB.trans.lot_process_records 
 --INNER JOIN  APCSProDB.trans.lot_andon_records 
 --ON lot_process_records.lot_id =  lot_andon_records.lot_id
 ----AND lot_process_records.job_id =  lot_andon_records.job_id
 --INNER JOIN  APCSProDB.trans.andon_controls 
 --ON lot_andon_records.andon_control_id =  andon_controls.id
 --WHERE lot_andon_records.lot_id = 2 
 --AND   record_class =  42 

 --SELECT TOP 100  * FROM APCSProDB.trans.lot_process_records 
 --WHERE record_class =  48 
 --ORDER BY recorded_at DESC


 --SELECT * FROM APCSProDB.trans.lot_andon_records 
 -- WHERE lot_andon_records.lot_id = 920842 



 -- SELECT * FROM APCSProDB.man.users
 -- WHERE id = 5

 -- SELECT  is_held FROM   APCSProDB.trans.lot_hold_controls
 -- WHERE lot_id =  907196