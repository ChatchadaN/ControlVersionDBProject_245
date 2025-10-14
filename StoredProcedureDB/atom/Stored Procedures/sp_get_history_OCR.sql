-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_history_OCR] 
	-- Add the parameters for the stored procedure here
	  @lot_id		INT 
	, @job_id		INT 

AS
BEGIN

	SET NOCOUNT ON;
 

 SELECT   lot_marking_verify_records.lot_id 
		, lots.lot_no	
		, jobs.name	AS job
		, lot_marking_verify_records.step_no
		, lot_marking_verify_records.recheck_count  
		, lot_marking_verify_records.value
		, item_labels.label_eng As[status] 
		, lot_marking_verify_picure.picture_data
		, lot_marking_verify_records.created_at AS createdat
		, users.emp_num AS createdby
		, lot_marking_verify_records.updated_at AS updatedat 
		, users.emp_num AS updatedby 
 FROM APCSProDB.trans.lot_marking_verify_records 
 LEFT JOIN APCSProDBFile.ocr.lot_marking_verify_picure 
 ON lot_marking_verify_records.marking_picture_id = lot_marking_verify_picure.id 
 LEFT JOIN APCSProDB.method.jobs 
 ON jobs.id = lot_marking_verify_records.job_id 
 LEFT JOIN APCSProDB.trans.item_labels 
 ON  item_labels.val = lot_marking_verify_records.is_pass 
 AND item_labels.name = 'lot_marking_verify.is_pass' 
 INNER JOIN APCSProDB.man.users 
 ON lot_marking_verify_records.created_by = users.id 
 INNER JOIN APCSProDB.trans.lots 
 ON lots.id			= lot_marking_verify_records.lot_id 
 where [lot_id]		=  @lot_id  
 AND lot_marking_verify_records.job_id = @job_id




END
