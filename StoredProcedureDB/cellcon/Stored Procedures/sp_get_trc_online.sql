-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_trc_online] 
	-- Add the parameters for the stored procedure here
	@Lotno varchar(10) = ''

	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @lot_id  INT  
		
		SET @lot_id = (SELECT id FROM APCSProDB.trans.lots WHERE lot_no = @Lotno)
SELECT 
--control_records.id  , control_records.lot_id    
--, trc_picture_id , trc_picture.picture_data , trc_controls.is_held
--,trc_control_records.created_by
--, trc_control_records.created_at 
		  machines.[name] as 'McReques'
						  ,trc_controls.created_at as 'RequestInspectionTime'
						  ,0 as 'IdPicture'--trc_picture.id as 'IdPicture'
						  ,trc_controls.qty_insp as 'Quantity'
						  ,jobs.[name] as 'Process'
						  ,trc_controls.insp_type as 'InspType'
						  ,abnormal1.[name] as 'RequestMode'
						  ,abnormal2.[name] as 'RequestMode2'
						  ,abnormal3.[name] as 'RequestMode3'
						  ,'[RequestCode1]' as 'RequestCode1'
						  ,'[RequestCode2]' as 'RequestCode2'
						  ,'[RequestCode3]' as 'RequestCode3'
						  ,trc_controls.insp_item as 'InspectionItem'
						  ,trc_controls.qty_insp as 'QuantityAdjust'
						  ,trc_controls.ng_random as 'NgRandom'
						  ,users.[emp_num] as 'OpNo'
						  ,'[Abnormal]' as 'Abnormal'
						  ,trc_controls.comment
						  ,trc_picture.picture_data as Picture  --trc_picture.picture_data as Picture 
						  ,days.date_value as ShipmentDate
						  ,trc_controls.id as Trc_Id
						  ,lb_item.label_eng as 'InspectionItemName'
						  ,lb_type.label_eng as 'InspTypeName'
						  ,trc_controls.aqi_no
		FROM  (SELECT   trc_controls.id , trc_control_records.lot_id   , MAX(trc_control_records.lot_process_record_id ) AS lot_process_record_id 
		   , MAX(trc_picture.id ) AS trc_picture_id    
				FROM APCSProDB.trans.trc_controls
				INNER JOIN APCSProDB.trans.trc_control_records ON trc_control_records.trc_id = trc_controls.id AND  trc_controls.lot_id = @lot_id
				INNER JOIN   APCSProDBFile.trans.trc_picture ON trc_controls.id = trc_picture.trc_id
				--AND picture_data IS NOT NULL   
				GROUP BY trc_controls.id ,	trc_control_records.lot_id   
		)AS  control_records  
		 INNER JOIN  APCSProDBFile.trans.trc_picture ON trc_picture_id = trc_picture.id
		INNER JOIN APCSProDB.trans.trc_controls ON trc_controls.id =  control_records.id 
		INNER JOIN APCSProDB.trans.trc_control_records ON trc_control_records.lot_process_record_id = control_records.lot_process_record_id  
		AND trc_control_records.trc_id = control_records.id
		INNER JOIN   APCSProDB.trans.lots on control_records.lot_id = lots.id
		inner join APCSProDB.man.users on users.id = trc_control_records.created_by
		left join APCSProDB.trans.[days] on [days].id = lots.ship_date_id
		left join APCSProDB.trans.lot_process_records as record on record.id = control_records.lot_process_record_id
		left join APCSProDB.mc.machines on machines.id = record.machine_id
		left join APCSProDB.method.jobs on jobs.id = record.job_id
		LEFT join APCSProDB.trans.abnormal_detail as abnormal1 on abnormal1.id = trc_controls.abnormal_mode_id1
		LEFT join APCSProDB.trans.abnormal_detail as abnormal2 on abnormal2.id = trc_controls.abnormal_mode_id2
		LEFT join APCSProDB.trans.abnormal_detail as abnormal3 on abnormal3.id = trc_controls.abnormal_mode_id3 
		LEFT JOIN APCSProDB.trans.item_labels as lb_item on lb_item.name = 'trc_controls.insp_item' and lb_item.val = trc_controls.insp_item
		LEFT JOIN APCSProDB.trans.item_labels as lb_type on lb_type.name = 'trc_controls.insp_type' and lb_type.val = trc_controls.insp_type
  
		WHERE control_records.lot_id  = @lot_id and trc_controls.is_held = 1 
		order by trc_control_records.created_at


			--SELECT 	machines.[name] as 'McReques'
			--	  ,trc.created_at as 'RequestInspectionTime'
			--	  ,0 as 'IdPicture'--trc_picture.id as 'IdPicture'
			--	  ,trc.qty_insp as 'Quantity'
			--	  ,jobs.[name] as 'Process'
			--	  ,trc.insp_type as 'InspType'
			--	  ,abnormal1.[name] as 'RequestMode'
			--	  ,abnormal2.[name] as 'RequestMode2'
			--	  ,abnormal3.[name] as 'RequestMode3'
			--	  ,'[RequestCode1]' as 'RequestCode1'
			--	  ,'[RequestCode2]' as 'RequestCode2'
			--	  ,'[RequestCode3]' as 'RequestCode3'
			--	  ,trc.insp_item as 'InspectionItem'
			--	  ,trc.qty_insp as 'QuantityAdjust'
			--	  ,trc.ng_random as 'NgRandom'
			--	  ,users.[emp_num] as 'OpNo'
			--	  ,'[Abnormal]' as 'Abnormal'
			--	  ,trc.comment
			--	  ,trc_picture.picture_data as Picture  --trc_picture.picture_data as Picture 
			--	  ,days.date_value as ShipmentDate
			--	  ,trc.trc_id as Trc_Id
			--	  ,lb_item.label_eng as 'InspectionItemName'
			--	  ,lb_type.label_eng as 'InspTypeName'
			--	  ,trcCurrent.aqi_no

			--from APCSProDB.trans.lots
			--inner join APCSProDB.trans.trc_control_records as trc on trc.lot_id = lots.id
			--inner join  APCSProDB.trans.trc_controls as trcCurrent on trcCurrent.id = trc_id
			--inner join APCSProDB.man.users on users.id = trc.created_by
			--left join APCSProDB.trans.[days] on [days].id = lots.ship_date_id
			--left join APCSProDB.trans.lot_process_records as record on record.id = trc.lot_process_record_id
			--left join APCSProDB.mc.machines on machines.id = record.machine_id
			--left join APCSProDB.method.jobs on jobs.id = record.job_id
			--LEFT join APCSProDB.trans.abnormal_detail as abnormal1 on abnormal1.id = trc.abnormal_mode_id1
			--LEFT join APCSProDB.trans.abnormal_detail as abnormal2 on abnormal2.id = trc.abnormal_mode_id2
			--LEFT join APCSProDB.trans.abnormal_detail as abnormal3 on abnormal3.id = trc.abnormal_mode_id3
			--LEFT JOIN APCSProDBFile.trans.trc_picture on trc_picture.trc_id = trc.id
			--LEFT JOIN APCSProDB.trans.item_labels as lb_item on lb_item.name = 'trc_controls.insp_item' and lb_item.val = trc.insp_item
			--LEFT JOIN APCSProDB.trans.item_labels as lb_type on lb_type.name = 'trc_controls.insp_type' and lb_type.val = trc.insp_type
			--where lots.lot_no =  @Lotno and trcCurrent.is_held = 1
			--order by trc.created_at 
END
