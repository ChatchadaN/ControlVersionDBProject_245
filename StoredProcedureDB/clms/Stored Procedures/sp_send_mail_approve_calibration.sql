-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	ร้องขอการสอบเทียบ
-- =============================================
CREATE PROCEDURE [clms].[sp_send_mail_approve_calibration] 
AS
BEGIN
	declare @NOT_SEND int,@WAIT_CTR_USER int,@WAIT_CHK_USER int ,@WAIT_RESP_CHK_USER int ,@WAIT_RESP_MAIN_USER int;
declare @MSG_NOT_SEND nvarchar(500),@MSG_WAIT_CTR_USER nvarchar(500),@MSG_WAIT_CHK_USER nvarchar(500),@MSG_WAIT_RESP_CHK_USER nvarchar(500),@MSG_WAIT_RESP_MAIN_USER nvarchar(500),@url nvarchar(500);
declare @req_user int ,@ctr_user int,@chk_user int,@resp_chk_user int ,@resp_main_user int;
declare	@user_email varchar(50)
declare @Nmail_profile nvarchar(100) = 'Test external email';

--set @url ='http://10.28.33.113/CalibrationSystem/Account/Login?returnUrl=/Approve/ApproveCalibrationList';
set @url ='http://webserv.thematrix.net/CalibrationSystem/Account/Login?returnUrl=/Approve/ApproveCalibrationList';
DECLARE sendmail_cursor CURSOR FOR 
SELECT   SUM(CASE WHEN (ctr_status ='N') THEN  1 ELSE 0 END ) not_send, --'NOT_SEND' 
           --SUM(CASE WHEN (ctr_status  <>'Y' AND chk_status <> 'Y')  THEN  1 ELSE 0 END ) wait_ctr_user, -- 'WAIT_CTR_USER' 
		 SUM(CASE WHEN (ctr_status  <>'Y' AND isnull(chk_status,'') <> 'Y')  THEN  1 ELSE 0 END ) wait_ctr_user, -- 'WAIT_CTR_USER'  --update by aun 210326
         SUM(CASE WHEN ( ctr_status ='Y' AND (chk_status  ='0' OR resp_chk_status ='N')) THEN  1 ELSE 0 END ) wait_chk_user ,-- 'WAIT_CHK_USER' 
         SUM(CASE WHEN (chk_status ='Y' AND (isnull(resp_chk_status,'') <> 'Y' AND  isnull(do_status,'') <> 'Y')) THEN 1 ELSE 0 END ) wait_resp_chk_user, -- 'WAIT_RESP_CHK_USER' 
         SUM(CASE WHEN (isnull(resp_main_status,'') <> 'Y' AND  isnull(resp_chk_status,'') = 'Y') THEN 1 ELSE 0 END ) wait_resp_main_user,-- 'WAIT_RESP_MAIN_USER'
         req_user ,
		 ctr_user, 
		 resp_chk_user,
		 resp_main_user,
		 chk_user
		FROM   APCSProDB.clms.req_chkeq
		GROUP BY req_user,ctr_user,resp_chk_user,resp_main_user,chk_user;

--SELECT   @NOT_SEND = SUM(CASE WHEN ( ctr_status ='N') THEN  1 ELSE 0 END ), --'NOT_SEND' 
--         @WAIT_CTR_USER = SUM(CASE WHEN (ctr_status  ='0' OR chk_status ='N')  THEN  1 ELSE 0 END ), -- 'WAIT_CTR_USER' 
--         @WAIT_CHK_USER = SUM(CASE WHEN (chk_status  ='0' OR resp_chk_status ='N') THEN  1 ELSE 0 END ) ,-- 'WAIT_CHK_USER' 
--         @WAIT_RESP_CHK_USER = SUM(CASE WHEN (resp_chk_status ='0' OR resp_main_status ='N' ) THEN  1 ELSE 0 END ), -- 'WAIT_RESP_CHK_USER' 
--         @WAIT_RESP_MAIN_USER = SUM(CASE WHEN (resp_chk_status ='Y' and resp_main_status ='0') THEN 1 ELSE 0 END ) ,-- 'WAIT_RESP_MAIN_USER'
--         @req_user = req_user ,
--		 @ctr_user =ctr_user, 
--		 @resp_chk_user =resp_chk_user,
--		 @resp_main_user=resp_main_user,
--		 @chk_user = chk_user
--		FROM   APCSProDB.clms.req_chkeq
--		GROUP BY req_user,ctr_user,resp_chk_user,resp_main_user,chk_user

 
 OPEN sendmail_cursor  
			FETCH NEXT FROM sendmail_cursor INTO @NOT_SEND , 
         @WAIT_CTR_USER,
         @WAIT_CHK_USER  ,
         @WAIT_RESP_CHK_USER , 
         @WAIT_RESP_MAIN_USER ,
         @req_user ,
		 @ctr_user , 
		 @resp_chk_user ,
		 @resp_main_user,
		 @chk_user ;
 WHILE @@FETCH_STATUS = 0  
	BEGIN 

if @NOT_SEND + @WAIT_CTR_USER + @WAIT_CHK_USER + @WAIT_RESP_CHK_USER +  @WAIT_RESP_MAIN_USER  > 0
begin
declare @mail_tpl nvarchar(4000),@email nvarchar(4000),@mail_subj nvarchar(150);
IF @NOT_SEND > 0
SET @MSG_NOT_SEND =concat( @url ,N'?mode=DO' ,char(10) , N'ยังไม่ส่งอนุมัติ', @NOT_SEND, N' รายการ', char(10));

IF @WAIT_CTR_USER > 0
SET @MSG_WAIT_CTR_USER = concat(@url , N'?mode=CTRL', char(10) , N'รอผู้ควบคุมอนุมัติจำนวน ' , @WAIT_CTR_USER , N' รายการ', char(10));

IF @WAIT_CHK_USER > 0
SET @MSG_WAIT_CHK_USER = concat(@url , N'?mode=CHK_USER', char(10) , N'รอผู้สอบเทียบตรวจสอบอนุมัติจำนวน ' ,@WAIT_CHK_USER , N' รายการ', char(10));

IF @WAIT_RESP_CHK_USER > 0
SET @MSG_WAIT_RESP_CHK_USER = concat(@url , N'?mode=RESP_CHK_USER', char(10) , N'รอผู้รับผิดชอบอนุมัติจำนวน ' ,@WAIT_RESP_CHK_USER , N' รายการ', char(10));

IF @WAIT_RESP_MAIN_USER > 0
SET @MSG_WAIT_RESP_MAIN_USER = concat(@url , N'?mode=RESP_MAIN_USER', char(10) , N'รอผู้รับผิดชอบโดยรวมอนุมัติจำนวน ' ,@WAIT_RESP_MAIN_USER , N' รายการ', char(10));



set @user_email = clms.get_user_email(@req_user) 

 set @mail_tpl = concat(@MSG_NOT_SEND,@MSG_WAIT_CTR_USER,@MSG_WAIT_CHK_USER,@MSG_WAIT_RESP_CHK_USER,@MSG_WAIT_RESP_MAIN_USER)
 EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'ติดตามสถานะการดำเนินการร้องขอการสอบเทียบ',
 @body =@mail_tpl ;

        

--==========================================================
IF @WAIT_CTR_USER  > 0
begin
set @user_email = clms.get_user_email(@ctr_user)  

  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_CTR_USER)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients = @user_email,
  --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'ผู้ควบคุมอนุมัติร้องขอการสอบเทียบ',
 @body =@mail_tpl ;

end --IF @totchk > 0
--======================================================================
IF @WAIT_CHK_USER  > 0
begin
set @user_email = clms.get_user_email(@chk_user)  
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_CHK_USER)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
  --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'ผู้สอบเทียบตรวจสอบร้องขอการสอบเทียบ',
 @body =@mail_tpl ;

end --IF @totappr > 0
--======================================================================
IF @WAIT_RESP_CHK_USER > 0
begin
set @user_email = clms.get_user_email(@resp_chk_user)  

  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_RESP_CHK_USER)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
  --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'ผู้รับผิดชอบร้องขอการสอบเทียบ',
 @body =@mail_tpl ;

end --IF @totqc > 0
--======================================================================
IF @WAIT_RESP_MAIN_USER > 0
begin
 set @user_email = clms.get_user_email(@resp_main_user)
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_RESP_MAIN_USER)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
  --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'ผู้รับผิดชอบโดยรวมร้องขอการสอบเทียบ',
 @body =@mail_tpl ;

end --IF @totqc > 0

END


FETCH NEXT FROM sendmail_cursor INTO @NOT_SEND , 
         @WAIT_CTR_USER,
         @WAIT_CHK_USER  ,
         @WAIT_RESP_CHK_USER , 
         @WAIT_RESP_MAIN_USER ,
         @req_user ,
		 @ctr_user , 
		 @resp_chk_user ,
		 @resp_main_user,
		 @chk_user
--======================================================================


END
CLOSE sendmail_cursor  ;
DEALLOCATE sendmail_cursor 	;
END
