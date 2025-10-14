-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_send_mail_approve_change_equip]

AS
BEGIN
	declare @NOT_SEND int,@WAIT_CTRL int,@WAIT_CTR_HD int ,@WAIT_TFRCTR int ,@WAIT_TFRCTR_HD int,@WAIT_DIVMGR int,@WAIT_PEDIV int ;
declare @MSG_NOT_SEND nvarchar(500),@MSG_WAIT_CTRL nvarchar(500),@MSG_WAIT_CTR_HD nvarchar(500),@MSG_WAIT_TFRCTR nvarchar(500),@MSG_WAIT_TFRCTR_HD nvarchar(500),@MSG_WAIT_DIVMGR nvarchar(500),@MSG_WAIT_PEDIV nvarchar(500),@url nvarchar(500);
declare @created_by int ,@ctr_user int ,@head_user int ,@ctr_trnf_user int ,@head_trnf_user int,@resp_user int,@appr_user int ;
declare @user_email varchar(50) ;
declare @Nmail_profile nvarchar(100) = 'Test external email';
--set @url ='http://10.28.33.113/CalibrationSystem/Account/Login?returnUrl=/Approve/ApproveEquipmantChangeStatus'; webserv.thematrix.net
set @url ='http://webserv.thematrix.net/CalibrationSystem/Account/Login?returnUrl=/Approve/ApproveEquipmantChangeStatus';

DECLARE sendmail_cursor CURSOR FOR 
SELECT   SUM(CASE WHEN (send_status ='N' OR ctr_status ='N') THEN  1 ELSE 0 END ), --'NOT_SEND' 
         SUM(CASE WHEN (send_status ='Y' and (ctr_status  ='0' OR head_status ='N'))  THEN  1 ELSE 0 END ), -- 'WAIT_CTRL' 
         SUM(CASE WHEN (ctr_status ='Y' and (head_status ='0' OR resp_status ='N' )) THEN  1 ELSE 0 END ) ,-- 'WAIT_CTR_HD' 
         SUM(CASE WHEN (chg_type ='MOVE' AND (head_status ='Y' and (ctr_trnf_status ='0' OR head_trnf_status ='N' ))) THEN  1 ELSE 0 END ), -- 'WAIT_TFRCTR' 
        SUM(CASE WHEN (chg_type ='MOVE' AND (ctr_trnf_status ='Y' and (head_trnf_status ='0' OR resp_status ='N' ))) THEN  1 ELSE 0 END ), -- 'WAIT_TFRCTR_HD'
         SUM(CASE WHEN ((head_status ='Y' OR head_trnf_status ='Y') and (resp_status  ='0' OR appr_status ='N')) THEN  1 ELSE 0 END ), -- 'WAIT_DIVMGR'
         SUM(CASE WHEN resp_status ='Y' and appr_status ='0' THEN  1 ELSE 0 END ), -- 'WAIT_PEDIV'
		 created_by,
		 ctr_user,
		 head_user,
		 ctr_trnf_user,
		 head_trnf_user,
		 resp_user,
		 appr_user
          FROM   APCSProDB.clms.req_chgeq_status
		  group by created_by,ctr_user,head_user,ctr_trnf_user,head_trnf_user,resp_user,appr_user

		 -- SELECT   @NOT_SEND = SUM(CASE WHEN (send_status ='N' OR ctr_status ='N') THEN  1 ELSE 0 END ), --'NOT_SEND' 
   --      @WAIT_CTRL = SUM(CASE WHEN (send_status ='Y' and (ctr_status  ='0' OR head_status ='N'))  THEN  1 ELSE 0 END ), -- 'WAIT_CTRL' 
   --      @WAIT_CTR_HD = SUM(CASE WHEN (ctr_status ='Y' and (head_status ='0' OR resp_status ='N' )) THEN  1 ELSE 0 END ) ,-- 'WAIT_CTR_HD' 
   --      @WAIT_TFRCTR = SUM(CASE WHEN (chg_type ='MOVE' AND (head_status ='Y' and (ctr_trnf_status ='0' OR head_trnf_status ='N' ))) THEN  1 ELSE 0 END ), -- 'WAIT_TFRCTR' 
   --      @WAIT_TFRCTR_HD = SUM(CASE WHEN (chg_type ='MOVE' AND (ctr_trnf_status ='Y' and (head_trnf_status ='0' OR resp_status ='N' ))) THEN  1 ELSE 0 END ), -- 'WAIT_TFRCTR_HD'
   --      @WAIT_DIVMGR = SUM(CASE WHEN ((head_status ='Y' OR head_trnf_status ='Y') and (resp_status  ='0' OR appr_status ='N')) THEN  1 ELSE 0 END ), -- 'WAIT_DIVMGR'
   --      @WAIT_PEDIV = SUM(CASE WHEN resp_status ='Y' and appr_status ='0' THEN  1 ELSE 0 END ), -- 'WAIT_PEDIV'
		 --@created_by =created_by,
		 --@ctr_user=ctr_user,
		 --@head_user=head_user,
		 --@ctr_trnf_user =ctr_trnf_user,
		 --@head_trnf_user=head_trnf_user,
		 --@resp_user=resp_user,
		 --@appr_user=appr_user
   --       FROM   APCSProDB.clms.req_chgeq_status
		 -- group by created_by,ctr_user,head_user,ctr_trnf_user,head_trnf_user,resp_user,appr_user

OPEN sendmail_cursor  
			FETCH NEXT FROM sendmail_cursor INTO  @NOT_SEND ,
         @WAIT_CTRL,
         @WAIT_CTR_HD,
         @WAIT_TFRCTR ,
         @WAIT_TFRCTR_HD ,
         @WAIT_DIVMGR ,
         @WAIT_PEDIV ,
		 @created_by ,
		 @ctr_user,
		 @head_user,
		 @ctr_trnf_user ,
		 @head_trnf_user, 
		 @resp_user,
		 @appr_user ;

WHILE @@FETCH_STATUS = 0  
	BEGIN  

if @NOT_SEND + @WAIT_CTRL + @WAIT_CTR_HD + @WAIT_TFRCTR +  @WAIT_TFRCTR_HD + @WAIT_DIVMGR + @WAIT_PEDIV > 0
begin
declare @mail_tpl nvarchar(4000),@email nvarchar(4000),@mail_subj nvarchar(150);
IF @NOT_SEND > 0
SET @MSG_NOT_SEND =concat( @url ,N'?mode=EQ_CHANGE_DO' ,char(10) , N'ยังไม่ส่งอนุมัติ', @NOT_SEND, N' รายการ', char(10));

IF @WAIT_CTRL > 0
SET @MSG_WAIT_CTRL = concat(@url , N'?mode=EQCHG_CTRL_USER', char(10) , N'รอผู้ควบคุมอนุมัติจำนวน ' , @WAIT_CTRL , N' รายการ', char(10));

IF @WAIT_CTR_HD > 0
SET @MSG_WAIT_CTR_HD = concat(@url , N'?mode=EQCHG_CTRL_HD_USER', char(10) , N'รอหัวหน้าผู้ควบคุมอนุมัติจำนวน ' ,@WAIT_CTR_HD , N' รายการ', char(10));

IF @WAIT_TFRCTR > 0
SET @MSG_WAIT_TFRCTR = concat(@url , N'?mode=EQCHG_CTRL_USER', char(10) , N'รอผู้ควบคุม(หน่วยงานรับโอน)อนุมัติจำนวน ' ,@WAIT_TFRCTR , N' รายการ', char(10));

IF @WAIT_TFRCTR_HD > 0
SET @MSG_WAIT_TFRCTR_HD = concat(@url , N'?mode=EQCHG_CTRL_HD_USER', char(10) , N'รอหัวหน้าผู้ควบคุม(หน่วยงานรับโอน)อนุมัติจำนวน ' ,@WAIT_TFRCTR_HD , N' รายการ', char(10));

IF @WAIT_DIVMGR > 0
SET @MSG_WAIT_DIVMGR = concat(@url , N'?mode=EQCHG_DIVMGR_USER', char(10) , N'รอDivision Manager อนุมัติจำนวน ' ,@WAIT_DIVMGR , N' รายการ', char(10));

IF @WAIT_PEDIV > 0
SET @MSG_WAIT_PEDIV = concat(@url , N'?mode=EQCHG_PEDIV_USER', char(10) , N'รอPE Division อนุมัติจำนวน ' ,@WAIT_PEDIV , N' รายการ', char(10));

  
set @user_email = clms.get_user_email(@created_by);

set @mail_tpl = concat(@mail_tpl,char(10),@MSG_NOT_SEND,@MSG_WAIT_CTRL,@MSG_WAIT_CTR_HD,@MSG_WAIT_TFRCTR,@MSG_WAIT_TFRCTR_HD,@MSG_WAIT_DIVMGR,@MSG_WAIT_PEDIV)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'ติดตามสถานะการอนุมัติการเปลี่ยนสถานะเครื่องมือวัด',
 @body =@mail_tpl ;
 
--==========================================================
IF @WAIT_CTRL  > 0
begin
 set @user_email = clms.get_user_email(@ctr_user);
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_CTRL,@MSG_WAIT_TFRCTR)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'ผู้ควบคุมอนุมัติการเปลี่ยนสถานะเครื่องมือวัด',
 @body =@mail_tpl ;
 
end --IF @WAIT_CTRL > 0
--==========================================================
IF  @WAIT_TFRCTR > 0
begin
 set @user_email = clms.get_user_email(@ctr_trnf_user);
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_CTRL,@MSG_WAIT_TFRCTR)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'ผู้ควบคุมอนุมัติการเปลี่ยนสถานะเครื่องมือวัด [หน่วยงานรับโอน]',
 @body =@mail_tpl ;
 
end --IF @totchk > 0
--======================================================================
IF @WAIT_CTR_HD  > 0
begin
  set @user_email = clms.get_user_email(@head_user);
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_CTR_HD,@MSG_WAIT_TFRCTR_HD)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'หัวหน้าผู้ควบคุมอนุมัติการเปลี่ยนสถานะเครื่องมือวัด ',
 @body =@mail_tpl ;
 
end --IF @@WAIT_CTR_HD > 0
--======================================================================
IF  @WAIT_TFRCTR_HD > 0
begin
  set @user_email = clms.get_user_email(@head_trnf_user);
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_CTR_HD,@MSG_WAIT_TFRCTR_HD)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'หัวหน้าผู้ควบคุมอนุมัติการเปลี่ยนสถานะเครื่องมือวัด [หน่วยงานรับโอน]',
 @body =@mail_tpl ;
 
end --IF @@WAIT_CTR_HD > 0
--======================================================================
IF @WAIT_DIVMGR > 0
begin
 set @user_email = clms.get_user_email(@resp_user);
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_DIVMGR)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'Division Manager อนุมัติการเปลี่ยนสถานะเครื่องมือวัด',
 @body =@mail_tpl ;
 
end --IF @totqc > 0

--======================================================================
IF @WAIT_PEDIV > 0
begin
  set @user_email = clms.get_user_email(@appr_user);
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_PEDIV)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'PE Division อนุมัติการเปลี่ยนสถานะเครื่องมือวัด',
 @body =@mail_tpl ;
 
end --IF @totqc > 0
END
 FETCH NEXT FROM sendmail_cursor INTO @NOT_SEND ,
         @WAIT_CTRL,
         @WAIT_CTR_HD,
         @WAIT_TFRCTR ,
         @WAIT_TFRCTR_HD ,
         @WAIT_DIVMGR ,
         @WAIT_PEDIV ,
		 @created_by ,
		 @ctr_user,
		 @head_user,
		 @ctr_trnf_user ,
		 @head_trnf_user, 
		 @resp_user,
		 @appr_user ; 



--======================================================================


END
CLOSE sendmail_cursor  ;
DEALLOCATE sendmail_cursor 	;
END
