-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_send_mail_approve_new_equip]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
declare @NOT_SEND int,@WAIT_CTRL int,@WAIT_CONF int ,@WAIT_RESP int ,@WAIT_APPROVE int ;
declare @MSG_NOT_SEND nvarchar(500),@MSG_WAIT_CTRL nvarchar(500),@MSG_WAIT_CONF nvarchar(500),@MSG_WAIT_RESP nvarchar(500),@MSG_WAIT_APPROVE nvarchar(500),@url nvarchar(500);
declare @created_by int ,@appr_by int ,@ctr_user int ,@confirm_user int,@resp_user int ;
declare @user_email varchar(50);
declare @Nmail_profile nvarchar(100) = 'Test external email';

 --set @url ='http://10.28.33.113/CalibrationSystem/Account/Login?returnUrl=/Approve/ApproveNewCalibration';webserv.thematrix.net
 set @url ='http://webserv.thematrix.net/CalibrationSystem/Account/Login?returnUrl=/Approve/ApproveNewCalibration';

DECLARE sendmail_cursor CURSOR FOR 
SELECT   SUM(CASE WHEN send_status ='N' OR ctr_status ='N' THEN 1 ELSE 0 END),--'NOT_SEND' 
         SUM(CASE WHEN ctr_status  ='0' OR confirm_status ='N'  THEN 1 ELSE 0 END), --'WAIT_CTRL' 
         SUM(CASE WHEN confirm_status ='0' OR resp_status ='N'  THEN 1 ELSE 0 END ) ,--'WAIT_CONF' 
         SUM(CASE WHEN resp_status  ='0' OR appr_status ='N' THEN 1 ELSE 0 END), --'WAIT_RESP'
         SUM( CASE WHEN appr_status  ='0' THEN 1 ELSE 0 END ), --'WAIT_APPROVE'
		 created_by,
		 appr_by,
		 ctr_user,
		 resp_user,
		 confirm_user
         FROM  APCSProDB.clms.cb_equip
		 group by created_by,appr_by,ctr_user,ctr_user,resp_user,confirm_user

--SELECT   @NOT_SEND =SUM(CASE WHEN send_status ='N' OR ctr_status ='N' THEN 1 ELSE 0 END),--'NOT_SEND' 
--         @WAIT_CTRL=SUM(CASE WHEN ctr_status  ='0' OR confirm_status ='N'  THEN 1 ELSE 0 END), --'WAIT_CTRL' 
--         @WAIT_CONF=SUM(CASE WHEN confirm_status ='0' OR resp_status ='N'  THEN 1 ELSE 0 END ) ,--'WAIT_CONF' 
--         @WAIT_RESP = SUM(CASE WHEN resp_status  ='0' OR appr_status ='N' THEN 1 ELSE 0 END), --'WAIT_RESP'
--         @WAIT_APPROVE = SUM( CASE WHEN appr_status  ='0' THEN 1 ELSE 0 END ), --'WAIT_APPROVE'
--		 @created_by=created_by,
--		 @appr_by=appr_by,
--		 @ctr_user=ctr_user,
--		 @resp_user=resp_user,
--		 @confirm_user=confirm_user
--         FROM  APCSProDB.clms.cb_equip
--		 group by created_by,appr_by,ctr_user,ctr_user,resp_user,confirm_user

OPEN sendmail_cursor  
			FETCH NEXT FROM sendmail_cursor INTO @NOT_SEND ,
         @WAIT_CTRL, 
         @WAIT_CONF, 
         @WAIT_RESP,
         @WAIT_APPROVE,
		 @created_by,
		 @appr_by,
		 @ctr_user,
		 @resp_user,
		 @confirm_user ;

WHILE @@FETCH_STATUS = 0  
	BEGIN 

if @NOT_SEND + @WAIT_CTRL + @WAIT_CONF + @WAIT_RESP +  @WAIT_APPROVE > 0
begin
declare @mail_tpl nvarchar(4000),@email nvarchar(4000),@mail_subj nvarchar(150);

IF @NOT_SEND > 0
SET @MSG_NOT_SEND =concat( @url ,N'?mode=NEWEQ_DO' ,char(10) , N'ยังไม่ส่งอนุมัติ', @NOT_SEND, N' รายการ', char(10));

IF @WAIT_CTRL > 0
SET @MSG_WAIT_CTRL = concat(@url , N'?mode=NEWEQ_CTRL_USER', char(10) , N'รอผู้ควบคุมอนุมัติจำนวน ' , @WAIT_CTRL , N' รายการ', char(10));

IF @WAIT_CONF > 0
SET @MSG_WAIT_CONF = concat(@url , N'?mode=NEWEQ_CONFIRM_USER', char(10) , N'รอผู้ยืนยันอนุมัติจำนวน ' ,@WAIT_CONF , N' รายการ', char(10));

IF @WAIT_RESP > 0
SET @MSG_WAIT_RESP = concat(@url , N'?mode=NEWEQ_RESP_USER', char(10) , N'รอผู้รับผิดชอบอนุมัติจำนวน ' ,@WAIT_RESP , N' รายการ', char(10));

IF @WAIT_APPROVE > 0
SET @MSG_WAIT_APPROVE = concat(@url , N'?mode=NEWEQ_APPR_USER', char(10) , N'รอPE Division อนุมัติจำนวน ' ,@WAIT_APPROVE , N' รายการ', char(10));
        
set @user_email = clms.get_user_email(@created_by)+ ';Nucha.pra@Rist.Local';
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_NOT_SEND,@MSG_WAIT_CTRL,@WAIT_CONF,@MSG_WAIT_RESP,@MSG_WAIT_APPROVE)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'ติดตามสถานะ ขึ้นทะเบียนเครื่องมือวัด',
 @body =@mail_tpl ;
 
--==========================================================
IF @WAIT_CTRL > 0
begin
 set @user_email = clms.get_user_email(@ctr_user)+ ';Nucha.pra@Rist.Local';
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_CTRL)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'ผู้ควบคุมอนุมัติ ขึ้นทะเบียนเครื่องมือวัด',
 @body =@mail_tpl ;
 
end --IF @totchk > 0
--======================================================================
IF @WAIT_CONF > 0
begin
set @user_email = clms.get_user_email(@confirm_user)+ ';Nucha.pra@Rist.Local';
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_CONF)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'ผู้ยืนยันอนุมัติ ขึ้นทะเบียนเครื่องมือวัด',
 @body =@mail_tpl ;
 
end --IF @totappr > 0
--======================================================================
IF @WAIT_RESP > 0
begin
 set @user_email = clms.get_user_email(@resp_user)+ ';Nucha.pra@Rist.Local';
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_RESP)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'ผู้รับผิดชอบอนุมัติ ขึ้นทะเบียนเครื่องมือวัด',
 @body =@mail_tpl ;
 
end --IF @totqc > 0

--======================================================================
IF @WAIT_APPROVE > 0
begin
set @user_email = clms.get_user_email(@appr_by)+ ';Nucha.pra@Rist.Local';
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_APPROVE)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'PE Division อนุมัติ ขึ้นทะเบียนเครื่องมือวัด',
 @body =@mail_tpl ;

end --IF @totqc > 0
END

 FETCH NEXT FROM sendmail_cursor INTO @NOT_SEND ,
         @WAIT_CTRL, 
         @WAIT_CONF, 
         @WAIT_RESP,
         @WAIT_APPROVE,
		 @created_by,
		 @appr_by,
		 @ctr_user,
		 @resp_user,
		 @confirm_user  



--======================================================================


END
CLOSE sendmail_cursor  ;
DEALLOCATE sendmail_cursor 	;
END
