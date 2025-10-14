-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_update_trc_online]
	-- Add the parameters for the stored procedure here
	@Lotno varchar(50) = ''
	,@McReq varchar(20) = ''
	,@McInsp varchar(50) = ''
		,@NgMode varchar(50) = ''
		,@InspectionQty int = 0
		 ,@NgQty int = 0
      ,@NgRate int = 0
      ,@InspTime int = 0
      ,@HowToInsp varchar(50) = ''
      ,@NgMode1 int = 0
      ,@NgMode2 int = 0
      ,@NgMode3 int = 0
      ,@Comment varchar(150)
      ,@NgQtyJudgment varchar(50) = ''
      ,@Action1 varchar(50) = ''
      ,@InspTimeJudgment datetime
      ,@Action2 varchar(50) = ''
      ,@HowToInspJudgment varchar(50) = ''
      ,@Action3 varchar(50) = ''
      ,@NgModeJudgment varchar(50) = ''
      ,@Action4 varchar(50) = ''
      ,@InspLeader int = 0
      ,@RequestInspection varchar(50) = ''               
	  ,@RequestInspectionTime datetime
	  ,@InspStartTime  datetime 
	  ,@InspEndTime datetime
	  ,@RequestCode1 varchar(50) = ''
	  ,@RequestCode2 varchar(50) = ''
	  ,@RequestCode3 varchar(50) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
UPDATE DBx.INS.TRC
	SET    [McInsp]				        =	@McInsp
		  ,[NgMode]					    =	@NgMode
		  ,[InspectionQty]				=	@InspectionQty
		  ,[NgQty]						=	@NgQty
		  ,[NgRate]					    =	@NgRate
		  ,[InspStartTime]			    =	@InspStartTime
		  ,[InspEndTime]				=	@InspEndTime
		  ,[InspTime]					=	@InspTime
		  ,[HowToInsp]				    =	@HowToInsp
		  ,[NgMode1]					=	@NgMode1
		  ,[NgMode2]					=	@NgMode2
		  ,[NgMode3]					=	@NgMode3
		  ,[comment]					=	@Comment
		  ,[NgQtyJudgment]			    =	@NgQtyJudgment
		  ,[action1]					=	@Action1
		  ,[InspTimeJudgment]			=	@InspTimeJudgment
		  ,[action2]					=	@Action2
		  ,[HowToInspJudgment]		    =	@HowToInspJudgment
		  ,[action3]					=	@Action3
		  ,[NgModeJudgment]			    =	@NgModeJudgment
		  ,[action4]				  	=	@Action4
		  ,[InspLeader]				    =	@InspLeader
		  ,[RequestInspection]			=   @RequestInspection 
		  ,[RequestInspectionTime]      =	@RequestInspectionTime     
		  ,[RequestCode1]               =	@RequestCode1		  
		  ,[RequestCode2]               =	@RequestCode2
		  ,[RequestCode3]               =	@RequestCode3
	  
WHERE LotNo = @lotno AND McReques = @McReq

-- declare @op_no varchar(10),@lot_no varchar(10),@trc_id int,@lot_id int
--SELECT @lot_id = id FROM APCSProDB.trans.lots where lot_no = @lot_no
--UPDATE APCSProDB.trans.trc_controls
--	SET    is_held				        =	0
--		  ,updated_at					    =	GETDATE()
--		  ,updated_by				=	@op_no
--WHERE lot_id = @lot_id AND id = @trc_id


----INSERT INTO APCSProDB.trans.lot_process_records (recorded_at,operated_by,record_class,lot_id)
----INSERT INTO APCSProDB.trans.trc_control_records 
----(trc_id,lot_id,lot_process_record_id
END
