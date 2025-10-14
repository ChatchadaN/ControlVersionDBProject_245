-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_send_mail_approve_calibration_in_v2]
AS
BEGIN
	declare @IN_WAIT_APPR int,@IN_WAIT_APPRDO_USER int,@IN_WAIT_CONFIRM_USER int,@IN_WAIT_CHECK_USER int,@IN_WAIT_MAIN_USER int  ;
declare @MSG_IN_WAIT_APPR nvarchar(500),@MSG_IN_WAIT_CHK_USER nvarchar(500),@MSG_IN_WAIT_APPRDO_USER nvarchar(500),@MSG_IN_WAIT_CONFIRM_USER nvarchar(500),@url nvarchar(500),@MSG_IN_WAIT_MAIN_USER nvarchar(500);
declare @appr_do_user int ,@resp_chk_user int ,@ctr_user int ,@chk_user int ,@resp_main_user int ;
declare @user_email varchar(50) ;
declare @Nmail_profile nvarchar(100) = 'Test external email';
--set @url ='http://10.28.33.113/CalibrationSystem/Account/Login?returnUrl=/Approve/ApproveCalibrationResult'; 
set @url ='http://10.28.33.113/CalibrationSystem/Account/Login?returnUrl=/Calibrate/Index';
DECLARE sendmail_cursor CURSOR FOR 
		SELECT    SUM(CASE WHEN (ctr_status ='N') THEN  1 ELSE 0 END ), --'NOT_SEND' 
          SUM(CASE WHEN (ctr_status  <>'Y' AND chk_status <> 'Y')  THEN  1 ELSE 0 END ), -- 'WAIT_CTR_USER' 
          SUM(CASE WHEN ( ctr_status ='Y' AND (chk_status  ='0' OR resp_chk_status ='N')) THEN  1 ELSE 0 END ), -- 'WAIT_CHK_USER' 
		  SUM(CASE WHEN (chk_status ='Y' AND (isnull(resp_chk_status,'') <> 'Y' AND  isnull(do_status,'') <> 'Y')) THEN 1 ELSE 0 END ) ,
		   SUM(CASE WHEN (isnull(resp_main_status,'') <> 'Y' AND  isnull(resp_chk_status,'') = 'Y') THEN 1 ELSE 0 END ) ,
         ctr_user,appr_do_user,chk_user,resp_chk_user,resp_main_user
		 FROM  APCSProDB.clms.req_chkeq
		 WHERE chk_locate ='IN'
		 group by ctr_user,appr_do_user,resp_chk_user,chk_user,resp_main_user

OPEN sendmail_cursor  
			FETCH NEXT FROM sendmail_cursor INTO @IN_WAIT_APPR,@IN_WAIT_APPRDO_USER,@IN_WAIT_CHECK_USER,@IN_WAIT_CONFIRM_USER,@IN_WAIT_MAIN_USER,
			@ctr_user,@appr_do_user,@chk_user,@resp_chk_user,@resp_main_user  ;

WHILE @@FETCH_STATUS = 0  
	BEGIN  
				  if  @IN_WAIT_APPR + @IN_WAIT_APPRDO_USER + @IN_WAIT_CONFIRM_USER+@IN_WAIT_CHECK_USER+@IN_WAIT_MAIN_USER   > 0
					begin
					declare @mail_tpl nvarchar(4000),@email nvarchar(4000),@mail_subj nvarchar(150);

					IF @IN_WAIT_APPR > 0
					SET @MSG_IN_WAIT_APPR = concat(@url , N'?mode=CBIN_CTRL_USER', char(10) , N'รอจัดส่งอนุมัติจำนวน ' , @IN_WAIT_APPR , N' รายการ', char(10));

					IF @IN_WAIT_CHECK_USER > 0
					begin
					set @url ='http://10.28.33.113/CalibrationSystem/Account/Login?returnUrl=/Calibrate/Index';
					SET @MSG_IN_WAIT_CHK_USER = concat(@url , N'?mode=CHK_USER', char(10) , N'รอผู้สอบเทียบ อนุมัติจำนวน ' ,@IN_WAIT_CHECK_USER , N' รายการ', char(10));
					end 

					IF @IN_WAIT_APPRDO_USER > 0
					SET @MSG_IN_WAIT_APPRDO_USER = concat(@url , N'?mode=CBIN_CHK_USER', char(10) , N'รอผู้อนุมัติจำนวน ' ,@IN_WAIT_APPRDO_USER , N' รายการ', char(10));

					IF @IN_WAIT_CONFIRM_USER > 0
					SET @MSG_IN_WAIT_CONFIRM_USER = concat(@url , N'?mode=CBIN_RESP_CHK_USER', char(10) , N'รอผู้รับผิดชอบ ตรวจสอบและอนุมัติจำนวน ' ,@IN_WAIT_CONFIRM_USER , N' รายการ', char(10));

					IF @IN_WAIT_MAIN_USER > 0
					SET @MSG_IN_WAIT_MAIN_USER = concat(@url , N'?mode=CBIN_RESP_MAIN_USER', char(10) , N'รอผู้รับผิดชอบโดยรวม ' ,@IN_WAIT_MAIN_USER , N' รายการ', char(10));


	 
						IF @IN_WAIT_APPR  > 0
							begin
							 set @user_email = clms.get_user_email (@appr_do_user) ;
							  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_IN_WAIT_APPR)
							  EXEC msdb.dbo.sp_send_dbmail
							 @recipients =@user_email,
							 --@profile_name ='RIST',
							 @profile_name = @Nmail_profile,
							 @subject =N'รอจัดส่งอนุมัติผลการสอบเทียบภายใน',
							 @body =@mail_tpl ;
 
						end --IF @totchk > 0
--======================================================================
						IF @IN_WAIT_APPRDO_USER  > 0
						begin
						set @user_email = clms.get_user_email (@ctr_user) ;
						  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_IN_WAIT_APPRDO_USER)
						  EXEC msdb.dbo.sp_send_dbmail
						 @recipients =@user_email,
						 --@profile_name ='RIST',
						 @profile_name = @Nmail_profile,
						 @subject =N'รอควบคุมอนุมัติผลการสอบเทียบภายใน',
						 @body =@mail_tpl ;

						end --IF @totappr > 0
						--======================================================================

					IF @IN_WAIT_CHECK_USER  > 0
							begin
							 set @user_email = clms.get_user_email (@chk_user) ;
							  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_IN_WAIT_CHK_USER)
							  EXEC msdb.dbo.sp_send_dbmail
							 @recipients =@user_email,
							 --@profile_name ='RIST',
							 @profile_name = @Nmail_profile,
							 @subject =N'รอผู้สอบเทียบอนุมัติสอบเทียบภายใน',
							 @body =@mail_tpl ;
 
						end --IF @totchk > 0

--================================================================     
						IF @IN_WAIT_CONFIRM_USER > 0
						begin
						set @user_email = clms.get_user_email (@resp_chk_user) ;
						  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_IN_WAIT_CONFIRM_USER)
						  EXEC msdb.dbo.sp_send_dbmail
						 @recipients =@user_email,
						 --@profile_name ='RIST',
						 @profile_name = @Nmail_profile,
						 @subject =N'รอผู้รับผิดชอบตรวจสอบและอนุมัติผลการสอบเทียบภายใน',
						 @body =@mail_tpl ;

						end --IF @totqc > 0

						IF @IN_WAIT_MAIN_USER > 0
						begin
						set @user_email = clms.get_user_email (@resp_main_user) ;
						  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_IN_WAIT_MAIN_USER)
						  EXEC msdb.dbo.sp_send_dbmail
						 @recipients =@user_email,
						 --@profile_name ='RIST',
						 @profile_name = @Nmail_profile,
						 @subject =N'รอผู้รับผิดชอบอนุมัติผลการสอบเทียบภายใน',
						 @body =@mail_tpl ;

						end --IF @totqc > 0
				  
				
END 
  
  FETCH NEXT FROM sendmail_cursor INTO @IN_WAIT_APPR,@IN_WAIT_APPRDO_USER,@IN_WAIT_CHECK_USER,@IN_WAIT_CONFIRM_USER,@IN_WAIT_MAIN_USER,
			@ctr_user,@appr_do_user,@chk_user,@resp_chk_user,@resp_main_user  ;



--======================================================================


END
CLOSE sendmail_cursor  ;
DEALLOCATE sendmail_cursor 	;
END
