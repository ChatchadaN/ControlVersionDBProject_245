

 CREATE FUNCTION  [dbo].[AndonCheckState]
 (
	@lot_no AS VARCHAR(10) = NULL 
	
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
	
		
			 IF EXISTS( SELECT  'xxx' FROM   APCSProDB.trans.lot_hold_controls WHERE is_held = 1 AND  lot_id =  @lot_id )
			 BEGIN 
				--NO UPDATE  is_held = 0    FROM   APCSProDB.trans.lot_hold_controls
				INSERT INTO @table_andon SELECT   CAST(0 AS BIT) AS [status]
			 
			 END 
			 ELSE
			 BEGIN 
				 -- UPDATE  is_held , 0    FROM   APCSProDB.trans.lot_hold_controls
				INSERT INTO @table_andon SELECT   CAST(1 AS BIT) AS [status]
			 END

  RETURN
 END 

  --SELECT * FROM   [dbo].[AndonCheckState] ('1234A1234V') 
