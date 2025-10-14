
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Condition sum capacity>
-- =============================================
CREATE PROCEDURE atom.add_next_step_no
	 
	 @lot_id int = null
AS

BEGIN
 


 BEGIN TRAN


CREATE TABLE #TEMP 
(	lot_id					NVARCHAR(MAX)
	,special_flow_id		NVARCHAR(MAX)
	,step_no_temp			NVARCHAR(MAX)
) 

CREATE TABLE #RESULT
(
	lot_id					NVARCHAR(MAX)
	,id						NVARCHAR(MAX)
	,special_flow_id		NVARCHAR(MAX)
	,step_no				NVARCHAR(MAX)
	,next_step_no			NVARCHAR(MAX)
	,act_process_id			NVARCHAR(MAX)
	,job_id					NVARCHAR(MAX)
	,act_package_flow_id	NVARCHAR(MAX)
	,step_next_result		NVARCHAR(MAX)
 )
INSERT INTO #TEMP
SELECT	special_flows.lot_id				
		,lot_special_flows.special_flow_id	
		,MAX(lot_special_flows.step_no)	
FROM		APCSProDB.trans.lot_special_flows
INNER JOIN	APCSProDB.trans.special_flows  on lot_special_flows.special_flow_id = special_flows.id
WHERE		lot_special_flows.special_flow_id in (
			select id from APCSProDB.trans.special_flows 
			where lot_id = @lot_id)
GROUP BY lot_special_flows.special_flow_id   ,special_flows.lot_id  
ORDER BY special_flow_id 
 
 

INSERT INTO #RESULT
select  special_flows.lot_id				
		,lot_special_flows.id					
		,lot_special_flows.special_flow_id	
		,lot_special_flows.step_no			
		,next_step_no		
		,act_process_id		
		,job_id				
		,act_package_flow_id
		,''
from APCSProDB.trans.lot_special_flows
inner join APCSProDB.trans.special_flows  on lot_special_flows.special_flow_id = special_flows.id
where lot_special_flows.special_flow_id in (
 select id from APCSProDB.trans.special_flows 
 where lot_id = @lot_id )
order by special_flow_id 

UPDATE #RESULT
SET step_next_result =  step_no_temp
 FROM #TEMP 
INNER JOIN #RESULT 
ON #RESULT.special_flow_id = #TEMP.special_flow_id
 AND  #RESULT.step_no	= #TEMP.step_no_temp

  



UPDATE R
SET step_next_result  = (SELECT R.step_no + 1) 
FROM #RESULT R
LEFT JOIN #TEMP T
ON R.special_flow_id =  T.special_flow_id 
WHERE step_next_result <> step_no_temp
 

SELECT lot_id,	id	,special_flow_id,	step_no	,step_next_result
FROM #RESULT
ORDER BY special_flow_id

 
ROLLBACK 

 


END
