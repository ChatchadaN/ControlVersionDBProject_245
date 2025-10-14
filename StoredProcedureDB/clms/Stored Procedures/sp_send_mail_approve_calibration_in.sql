-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description: อนุมัตืผลการสอบเทียบ
-- =============================================
CREATE PROCEDURE [clms].[sp_send_mail_approve_calibration_in]
AS
BEGIN
declare @IN_WAIT_APPR int,@IN_WAIT_APPRDO_USER int,@IN_WAIT_CONFIRM_USER int  ;
declare @MSG_IN_WAIT_APPR nvarchar(500),@MSG_IN_WAIT_APPRDO_USER nvarchar(500),@MSG_IN_WAIT_CONFIRM_USER nvarchar(500),@url nvarchar(500);
declare @do_user int ,@appr_do_user int ,@confirm_user int ;
declare @user_email varchar(50) ;
declare @Nmail_profile nvarchar(100) = 'Test external email';
--set @url ='http://10.28.33.113/CalibrationSystem/Account/Login?returnUrl=/Approve/ApproveCalibrationResult'; webserv.thematrix.net
set @url ='http://webserv.thematrix.net/CalibrationSystem/Account/Login?returnUrl=/Approve/ApproveCalibrationResult';

DECLARE sendmail_cursor CURSOR FOR 
SELECT   SUM(CASE WHEN (resp_main_status ='Y' and do_status <> 'y') THEN  1 ELSE 0 END ), --'WIAT_DO_USER' 
         SUM(CASE WHEN (do_status ='Y' and appr_do_status <> 'y') THEN  1 ELSE 0 END ), -- 'WAIT_APPROVE_USER' 
         SUM(CASE WHEN (appr_do_status ='Y' and confirm_status <> 'y') THEN  1 ELSE 0 END ), -- 'WAIT_LAST_COMFIRM_USER' 
         do_user,appr_do_user,confirm_user
		 FROM  APCSProDB.clms.req_chkeq
		 group by do_user,appr_do_user,confirm_user

		 
OPEN sendmail_cursor  
			FETCH NEXT FROM sendmail_cursor INTO @IN_WAIT_APPR,@IN_WAIT_APPRDO_USER,@IN_WAIT_CONFIRM_USER,
			@do_user,@appr_do_user,@confirm_user  ;

--SELECT   @IN_WAIT_APPR = SUM(CASE WHEN (ctr_status ='N') THEN  1 ELSE 0 END ), --'NOT_SEND' 
--         @IN_WAIT_APPRDO_USER = SUM(CASE WHEN (ctr_status  ='0' OR chk_status ='N')  THEN  1 ELSE 0 END ), -- 'WAIT_CTR_USER' 
--         @IN_WAIT_CONFIRM_USER = SUM(CASE WHEN (chk_status  ='0' OR resp_chk_status ='N') THEN  1 ELSE 0 END ) -- 'WAIT_CHK_USER' 
--         FROM  APCSProDB.clms.req_chkeq

WHILE @@FETCH_STATUS = 0  
	BEGIN  
				  if  @IN_WAIT_APPR + @IN_WAIT_APPRDO_USER + @IN_WAIT_CONFIRM_USER   > 0
					begin
					declare @mail_tpl nvarchar(4000),@email nvarchar(4000),@mail_subj nvarchar(150);

					IF @IN_WAIT_APPR > 0
					SET @MSG_IN_WAIT_APPR = concat(@url , N'?mode=CBIN_CTRL_USER', char(10) , N'รอจัดส่งอนุมัติจำนวน ' , @IN_WAIT_APPR , N' รายการ', char(10));

					IF @IN_WAIT_APPRDO_USER > 0
					SET @MSG_IN_WAIT_APPRDO_USER = concat(@url , N'?mode=CBIN_CHK_USER', char(10) , N'รอผู้อนุมัติจำนวน ' ,@IN_WAIT_APPRDO_USER , N' รายการ', char(10));

					IF @IN_WAIT_CONFIRM_USER > 0
					SET @MSG_IN_WAIT_CONFIRM_USER = concat(@url , N'?mode=CBIN_RESP_CHK_USER', char(10) , N'รอผู้ยืนยันจำนวน ' ,@IN_WAIT_CONFIRM_USER , N' รายการ', char(10));
				


	 
						IF @IN_WAIT_APPR  > 0
							begin
							 set @user_email = clms.get_user_email (@do_user) ;
							  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_IN_WAIT_APPR)
							  EXEC msdb.dbo.sp_send_dbmail
							 @recipients =@user_email,
							 --@profile_name ='RIST',
							 @profile_name = @Nmail_profile,
							 @subject =N'รอผู้จัดทำนุมัติผลการสอบเทียบภายใน',
							 @body =@mail_tpl ;
 
						end --IF @totchk > 0
--======================================================================
						IF @IN_WAIT_APPRDO_USER  > 0
						begin
						set @user_email = clms.get_user_email (@appr_do_user) ;
						  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_IN_WAIT_APPRDO_USER)
						  EXEC msdb.dbo.sp_send_dbmail
						 @recipients =@user_email,
					     --@profile_name ='RIST',
						 @profile_name = @Nmail_profile,
						 @subject =N'รอผู้อนุมัติผลการสอบเทียบภายใน',
						 @body =@mail_tpl ;

						end --IF @totappr > 0
						--======================================================================

--================================================================     
						IF @IN_WAIT_CONFIRM_USER > 0
						begin
						set @user_email = clms.get_user_email (@confirm_user) ;
						  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_IN_WAIT_CONFIRM_USER)
						  EXEC msdb.dbo.sp_send_dbmail
						 @recipients =@user_email,
						 --@profile_name ='RIST',
						 @profile_name = @Nmail_profile,
						 @subject =N'รอผู้ยืนยันอนุมัติผลการสอบเทียบภายใน',
						 @body =@mail_tpl ;

						end --IF @totqc > 0

			
				  
				
END 
  
  FETCH NEXT FROM sendmail_cursor INTO  @IN_WAIT_APPR,@IN_WAIT_APPRDO_USER,@IN_WAIT_CONFIRM_USER,
			@do_user,@appr_do_user,@confirm_user  ;



--======================================================================


END


CLOSE sendmail_cursor  ;
DEALLOCATE sendmail_cursor 	;

END
