-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_send_mail_approve_calibration_ext] 
AS
BEGIN
declare @EXT_WAIT_APPR_REQ int,@EXT_WAIT_APPR int,@EXT_WAIT_EXTDO_USER int,@EXT_WAIT_EXTRESP_MAIN_USER int ,@EXT_WAIT_EXT_HEADCTR_USER int ,@EXT_WAIT_EXTRESP_MAIN_USER2 int  ;
declare @MSG_EXT_WAIT_APPR_REQ nvarchar(500),@MSG_EXT_WAIT_APPR nvarchar(500),
@MSG_EXT_WAIT_EXTDO_USER nvarchar(500),@MSG_EXT_WAIT_EXTRESP_MAIN_USER nvarchar(500),@MSG_EXT_WAIT_EXT_HEADCTR_USER nvarchar(500),@MSG_EXT_WAIT_EXTRESP_MAIN_USER2 nvarchar(500),@url nvarchar(500);
declare @appr_do_user int ,@confirm_user int ,@exdo_user int , @extresp_main_user int ,@ext_headctr_user int ,@extresp_main_user2 int ;
declare @user_email varchar(50);
declare @Nmail_profile nvarchar(100) = 'Test external email';



--set @url ='http://10.28.33.113/CalibrationSystem/Account/Login?returnUrl=/Approve/ApproveCalibrationResult'; webserv.thematrix.net
set @url ='http://webserv.thematrix.net/CalibrationSystem/Account/Login?returnUrl=/Approve/ApproveCalibrationResult';

DECLARE sendmail_cursor CURSOR FOR 
SELECT   SUM(CASE WHEN resp_main_status ='Y' AND chk_locate ='EXT' AND (extdo_status <> 'Y' OR extresp_main_status <> 'Y') THEN  1 ELSE 0 END ), 
         SUM(CASE WHEN chk_locate ='EXT' AND resp_main_status ='Y' AND extresp_main_status ='Y' AND (ext_headctr_status <> 'Y' OR extresp_main_status2 <> 'Y')  THEN  1 ELSE 0 END ), 
         SUM(CASE WHEN chk_locate ='EXT' AND isnull(extdo_status,'') <>'Y' THEN  1 ELSE 0 END )  WAIT_EXTDO_USER,
         SUM(CASE WHEN chk_locate ='EXT' AND extdo_status ='Y' AND   isnull(extresp_main_status,'') <> 'Y' THEN  1 ELSE 0 END ) EXTRESP_MAIN_USER,  
         SUM(CASE WHEN chk_locate ='EXT' AND extresp_main_status = 'Y' AND isnull(ext_headctr_status,'') <> 'Y'  THEN  1 ELSE 0 END ) HEADCTR_USER,  
        SUM(CASE WHEN chk_locate ='EXT' AND ext_headctr_status = 'Y' AND isnull(extresp_main_status2,'') <> 'Y' THEN  1 ELSE 0 END ) RESP_MAIN_USER2 , 
         appr_do_user,
		 confirm_user,
		 extdo_user,
		 extresp_main_user,
		 ext_headctr_user,
		 extresp_main_user2
		 FROM  APCSProDB.clms.req_chkeq
		 GROUP bY appr_do_user,confirm_user,extdo_user,extresp_main_user,ext_headctr_user,extresp_main_user2;

--SELECT   @EXT_WAIT_APPR_REQ = SUM(CASE WHEN resp_main_status ='Y' AND chk_locate ='EXT' AND (extdo_status <> 'Y' OR extresp_main_status <> 'Y') THEN  1 ELSE 0 END ), 
--         @EXT_WAIT_APPR = SUM(CASE WHEN chk_locate ='EXT' AND resp_main_status ='Y' AND extresp_main_status ='Y' AND (ext_headctr_status <> 'Y' OR extresp_main_status2 <> 'Y')  THEN  1 ELSE 0 END ), 
--         @EXT_WAIT_EXTDO_USER = SUM(CASE WHEN chk_locate ='EXT' AND isnull(extdo_status,'') <>'Y' THEN  1 ELSE 0 END ) ,
--         @EXT_WAIT_EXTRESP_MAIN_USER = SUM(CASE WHEN chk_locate ='EXT' AND extdo_status ='Y' AND   isnull(extresp_main_status,'') <> 'Y' THEN  1 ELSE 0 END ),  
--         @EXT_WAIT_EXT_HEADCTR_USER = SUM(CASE WHEN chk_locate ='EXT' AND extresp_main_status = 'Y' AND isnull(ext_headctr_status,'') <> 'Y'  THEN  1 ELSE 0 END ),  
--         @EXT_WAIT_EXTRESP_MAIN_USER2 = SUM(CASE WHEN chk_locate ='EXT' AND ext_headctr_status = 'Y' AND isnull(extresp_main_status2,'') <> 'Y' THEN  1 ELSE 0 END ) , 
--         @appr_do_user=appr_do_user,
--		 @confirm_user =confirm_user,
--		 @exdo_user=extdo_user,
--		 @extresp_main_user =extresp_main_user,
--		 @ext_headctr_user=ext_headctr_user,
--		 @extresp_main_user2=extresp_main_user2
--		 FROM  APCSProDB.clms.req_chkeq
--		 GROUP bY appr_do_user,confirm_user,extdo_user,extresp_main_user,ext_headctr_user,extresp_main_user2;



OPEN sendmail_cursor  
			FETCH NEXT FROM sendmail_cursor INTO @EXT_WAIT_APPR_REQ , 
						 @EXT_WAIT_APPR , 
						 @EXT_WAIT_EXTDO_USER,
						 @EXT_WAIT_EXTRESP_MAIN_USER ,  
						 @EXT_WAIT_EXT_HEADCTR_USER ,  
						 @EXT_WAIT_EXTRESP_MAIN_USER2 , 
						 @appr_do_user,
						 @confirm_user ,
						 @exdo_user,
						 @extresp_main_user ,
						 @ext_headctr_user,
						 @extresp_main_user2;

WHILE @@FETCH_STATUS = 0  
	BEGIN  


if @EXT_WAIT_APPR_REQ + @EXT_WAIT_APPR + @EXT_WAIT_EXTDO_USER + @EXT_WAIT_EXTRESP_MAIN_USER +  @EXT_WAIT_EXT_HEADCTR_USER + @EXT_WAIT_EXTRESP_MAIN_USER2  > 0
begin
declare @mail_tpl nvarchar(4000),@email nvarchar(4000),@mail_subj nvarchar(150);
IF @EXT_WAIT_APPR_REQ > 0
SET @MSG_EXT_WAIT_APPR_REQ =concat( @url ,N'?mode=CBEXT_APPR_REQ' ,char(10) , N'รออนุมัติร้องขอสอบเทียบภายนอก จำนวน', @EXT_WAIT_APPR_REQ, N' รายการ', char(10));

IF @EXT_WAIT_APPR > 0
SET @MSG_EXT_WAIT_APPR = concat(@url , N'?mode=CBEXT_APPR', char(10) , N'รออนุมัติผลสอบเทียบภายนอก จำนวน ' , @EXT_WAIT_APPR , N' รายการ', char(10));

IF @EXT_WAIT_EXTDO_USER > 0
SET @MSG_EXT_WAIT_EXTDO_USER = concat(@url , N'?mode=CBEXT_EXTDO_USER', char(10) , N'รออนุมัติร้องขอสอบเทียบภายนอก ผู้ปฎิบัติ จำนวน ' ,@EXT_WAIT_EXTDO_USER , N' รายการ', char(10));

IF @EXT_WAIT_EXTRESP_MAIN_USER > 0
SET @MSG_EXT_WAIT_EXTRESP_MAIN_USER = concat(@url , N'?mode=CBEXT_EXTRESP_MAIN', char(10) , N'รออนุมัติร้องขอสอบเทียบภายนอก ผู้รับผิดชอบโดยรวม [PM Division] จำนวน ' ,@EXT_WAIT_EXTRESP_MAIN_USER , N' รายการ', char(10));

IF @EXT_WAIT_EXT_HEADCTR_USER > 0
SET @MSG_EXT_WAIT_EXT_HEADCTR_USER = concat(@url , N'?mode=CBEXT_EXTHEADCTR_USER', char(10) , N'รออนุมัติผลสอบเทียบภายนอก หัวหน้าสังกัด [ผู้รับผิดชอบควบคุมเครื่องมือวัด] จำนวน ' ,@EXT_WAIT_EXT_HEADCTR_USER , N' รายการ', char(10));

IF @EXT_WAIT_EXTRESP_MAIN_USER2 > 0
SET @MSG_EXT_WAIT_EXTRESP_MAIN_USER2 = concat(@url , N'?mode=CBEXT_EXTRESP_MAIN2', char(10) , N'รออนุมัติผลสอบเทียบภายนอก ผู้รับผิดชอบโดยรวม [PM Division] จำนวน ' ,@EXT_WAIT_EXTRESP_MAIN_USER2 , N' รายการ', char(10));


        

--==========================================================
--IF @EXT_WAIT_APPR_REQ >  0 AND @appr_do_user IS NOT NULL
--begin
--	set @user_email = clms.get_user_email(@appr_do_user);
--  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_EXT_WAIT_APPR_REQ)
--  EXEC msdb.dbo.sp_send_dbmail
-- @recipients =@user_email,
-- @profile_name ='RIST',
-- @subject =N'อนุมัติผลการสอบเทียบ [หน่วยงานจัดทำ]',
-- @body =@mail_tpl ;

--end --IF @totchk > 0

----==========================================================
--IF @EXT_WAIT_APPR > 0 AND @confirm_user IS NOT NULL
--begin
--set @user_email = clms.get_user_email(@confirm_user);
--  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_EXT_WAIT_APPR)
--  EXEC msdb.dbo.sp_send_dbmail
-- @recipients =@user_email,
-- @profile_name ='RIST',
-- @subject =N'อนุมัติผลการสอบเทียบ [ผู้ยืนยัน]',
-- @body =@mail_tpl ;

--end --IF @totchk > 0
--===================================================
IF @EXT_WAIT_EXTDO_USER > 0 AND @exdo_user IS NOT NULL
begin
set @user_email = clms.get_user_email(@exdo_user);
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_EXT_WAIT_EXTDO_USER)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'อนุมัติผลสอบเทียบภายนอก ผู้ปฎิบัติ',
 @body =@mail_tpl ;
 
end --IF @totchk > 0
--=================================================================
IF @EXT_WAIT_EXTRESP_MAIN_USER > 0 AND @extresp_main_user IS NOT NULL
begin
set @user_email = clms.get_user_email(@extresp_main_user);
 
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_EXT_WAIT_EXTRESP_MAIN_USER)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
  --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'อนุมัติผลสอบเทียบภายนอก ผู้รับผิดชอบโดยรวม',
 @body =@mail_tpl ;
 
end --IF @totchk > 0

--=================================================================
IF @EXT_WAIT_EXT_HEADCTR_USER > 0 AND @ext_headctr_user IS NOT NULL
begin
set @user_email = clms.get_user_email(@ext_headctr_user);
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_EXT_WAIT_EXT_HEADCTR_USER)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
  --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'อนุมัติผลสอบเทียบภายนอก หัวหน้าสังกัด [ผู้รับผิดชอบควบคุมเครื่องมือวัด]',
 @body =@mail_tpl ;

end --IF @totchk > 0

--=================================================================
IF @EXT_WAIT_EXTRESP_MAIN_USER2 > 0 AND @extresp_main_user2 IS NOT NULL
begin

set @user_email = clms.get_user_email(@extresp_main_user2);
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_EXT_WAIT_EXTRESP_MAIN_USER2)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
  --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'อนุมัติผลสอบเทียบภายนอก ผู้รับผิดชอบโดยรวม [PM Division]',
 @body =@mail_tpl ;
 
end --IF @totchk > 0
END

FETCH NEXT FROM sendmail_cursor INTO @EXT_WAIT_APPR_REQ , 
						 @EXT_WAIT_APPR , 
						 @EXT_WAIT_EXTDO_USER,
						 @EXT_WAIT_EXTRESP_MAIN_USER ,  
						 @EXT_WAIT_EXT_HEADCTR_USER ,  
						 @EXT_WAIT_EXTRESP_MAIN_USER2 , 
						 @appr_do_user,
						 @confirm_user ,
						 @exdo_user,
						 @extresp_main_user ,
						 @ext_headctr_user,
						 @extresp_main_user2;
END
CLOSE sendmail_cursor  ;
DEALLOCATE sendmail_cursor 	;

END
