-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_send_mail_approve_grr]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
declare @WAIT_DO_USER int,@WAIT_HEAD_DIV_USER int,@WAIT_RESP_USER int ,@WAIT_HEAD_AFF_USER int ,@WAIT_HEAD_QC_USER int,@WAIT_PE_DIV_USER int ;
declare @MSG_WAIT_DO_USER nvarchar(500),@MSG_WAIT_HEAD_DIV_USER nvarchar(500),@MSG_WAIT_RESP_USER nvarchar(500),@MSG_WAIT_HEAD_AFF_USER nvarchar(500),@MSG_WAIT_HEAD_QC_USER nvarchar(500),@MSG_WAIT_PE_DIV_USER nvarchar(500),@url nvarchar(500);
declare @do_user int ,@head_div_user int ,@resp_user int ,@head_aff_user int ,@head_qc_user int ,@pe_div_user int ;
declare @user_email varchar(50);
declare @Nmail_profile nvarchar(100) = 'Test external email';
--set @url ='http://10.28.33.113/CalibrationSystem/Account/Login?returnUrl=/Approve/ApproveGaugeRandR';webserv.thematrix.net
set @url ='http://webserv.thematrix.net/CalibrationSystem/Account/Login?returnUrl=/Approve/ApproveGaugeRandR';

DECLARE sendmail_cursor CURSOR FOR 
SELECT 
      SUM( CASE WHEN (do_status ='0' OR head_div_status ='N') THEN 1 ELSE 0 END), 
     SUM( CASE WHEN (head_div_status  ='0' OR resp_status ='N')  THEN 1 ELSE 0 END), 
        SUM( CASE WHEN (result_status ='Y' and (resp_status ='0' OR head_aff_status ='N') ) THEN 1 ELSE 0 END),
        SUM( CASE WHEN (head_aff_status  ='0' AND head_qc_status  ='N' ) THEN 1 ELSE 0 END),
        SUM( CASE WHEN (head_qc_status = '0' AND pe_div_status = 'N') THEN 1 ELSE 0 END),
        SUM( CASE WHEN (head_qc_status ='Y' AND pe_div_status = '0' ) THEN 1 ELSE 0 END),
		do_user,
		 head_div_user,
		 resp_user,
		 head_aff_user,
		 head_qc_user,
		 pe_div_user
		FROM          APCSProDB.clms.cb_grr WHERE 1=1 
		group by do_user,head_div_user,resp_user,head_aff_user,head_qc_user,pe_div_user

--SELECT 
--      @WAIT_DO_USER = SUM( CASE WHEN (do_status ='0' OR head_div_status ='N') THEN 1 ELSE 0 END), 
--      @WAIT_HEAD_DIV_USER = SUM( CASE WHEN (head_div_status  ='0' OR resp_status ='N')  THEN 1 ELSE 0 END), 
--        @WAIT_RESP_USER = SUM( CASE WHEN (result_status ='Y' and (resp_status ='0' OR head_aff_status ='N') ) THEN 1 ELSE 0 END),
--        @WAIT_HEAD_AFF_USER = SUM( CASE WHEN (head_aff_status  ='0' AND head_qc_status  ='N' ) THEN 1 ELSE 0 END),
--        @WAIT_HEAD_QC_USER = SUM( CASE WHEN (head_qc_status = '0' AND pe_div_status = 'N') THEN 1 ELSE 0 END),
--        @WAIT_PE_DIV_USER = SUM( CASE WHEN (head_qc_status ='Y' AND pe_div_status = '0' ) THEN 1 ELSE 0 END),
--		@do_user=do_user,
--		 @head_div_user =head_div_user,
--		 @resp_user=resp_user,
--		 @head_aff_user=head_aff_user,
--		 @head_qc_user=head_qc_user,
--		 @pe_div_user=pe_div_user
--		FROM          APCSProDB.clms.cb_grr WHERE 1=1 
--		group by do_user,head_div_user,resp_user,head_aff_user,head_qc_user,pe_div_user



 OPEN sendmail_cursor  
			FETCH NEXT FROM sendmail_cursor INTO @WAIT_DO_USER , 
      @WAIT_HEAD_DIV_USER , 
        @WAIT_RESP_USER ,
        @WAIT_HEAD_AFF_USER ,
        @WAIT_HEAD_QC_USER ,
        @WAIT_PE_DIV_USER ,
		@do_user,
		 @head_div_user ,
		 @resp_user,
		 @head_aff_user,
		 @head_qc_user,
		 @pe_div_user ;

WHILE @@FETCH_STATUS = 0  
	BEGIN  

if @WAIT_DO_USER + @WAIT_HEAD_DIV_USER + @WAIT_RESP_USER + @WAIT_HEAD_AFF_USER +  @WAIT_HEAD_QC_USER +@WAIT_PE_DIV_USER  > 0
begin
declare @mail_tpl nvarchar(4000),@email nvarchar(4000),@mail_subj nvarchar(150);

IF @WAIT_DO_USER > 0
SET @MSG_WAIT_DO_USER =concat( @url ,N'?mode=GRR_DOUSER' ,char(10) , N'ยังไม่ส่งอนุมัติ', @WAIT_DO_USER, N' รายการ', char(10));

IF @WAIT_HEAD_DIV_USER > 0
SET @MSG_WAIT_HEAD_DIV_USER = concat(@url , N'?mode=GRR_HEAD_DIV_USER', char(10) , N'รอผู้ยืนยันอนุมัติจำนวน ' ,@WAIT_HEAD_DIV_USER , N' รายการ', char(10));

IF @WAIT_RESP_USER > 0
SET @MSG_WAIT_RESP_USER = concat(@url , N'?mode=GRR_RESP_USER', char(10) , N'รอผู้รับผิดชอบอนุมัติจำนวน ' ,@WAIT_RESP_USER , N' รายการ', char(10));

IF @WAIT_HEAD_AFF_USER > 0
SET @MSG_WAIT_HEAD_AFF_USER = concat(@url , N'?mode=GRR_HEAD_AFF_USER', char(10) , N'รอหัวหน้าสังกัด อนุมัติจำนวน ' ,@WAIT_HEAD_AFF_USER , N' รายการ', char(10));
        
IF @WAIT_HEAD_QC_USER > 0
SET @MSG_WAIT_HEAD_QC_USER = concat(@url , N'?mode=GRR_HEAD_QC_USER', char(10) , N'รอ Head QC อนุมัติจำนวน ' ,@WAIT_HEAD_QC_USER , N' รายการ', char(10));


IF @WAIT_PE_DIV_USER > 0
SET @MSG_WAIT_PE_DIV_USER = concat(@url , N'?mode=GRR_PE_DIV_USER', char(10) , N'รอPE Division อนุมัติจำนวน ' ,@WAIT_PE_DIV_USER , N' รายการ', char(10));



set @user_email = clms.get_user_email(@do_user);
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_DO_USER,@MSG_WAIT_HEAD_DIV_USER,@MSG_WAIT_RESP_USER,@MSG_WAIT_RESP_USER,@MSG_WAIT_HEAD_AFF_USER,@MSG_WAIT_HEAD_QC_USER,@MSG_WAIT_PE_DIV_USER)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'ติดตามสถานะการอนุมัติ GRR',
 @body =@mail_tpl ;

--==========================================================
IF @WAIT_HEAD_DIV_USER > 0
begin
set @user_email = clms.get_user_email(@head_div_user);
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_HEAD_DIV_USER)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'ผู้ยืนยันอนุมัติ GRR',
 @body =@mail_tpl ;

end --IF @totchk > 0
--======================================================================
IF @WAIT_RESP_USER > 0
begin
set @user_email = clms.get_user_email(@resp_user);  
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_RESP_USER)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'ผู้รับผิดชอบอนุมัติ GRR',
 @body =@mail_tpl ;
 end
--======================================================================
IF @WAIT_HEAD_AFF_USER > 0
begin
 set @user_email = clms.get_user_email(@head_aff_user);  
  set @mail_tpl = concat(@mail_tpl,char(10),@WAIT_HEAD_AFF_USER)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'หัวหน้าสังกัดอนุมัติ GRR',
 @body =@mail_tpl ;
 
end --IF @totqc > 0

--======================================================================
IF @WAIT_HEAD_QC_USER > 0
begin
 set @user_email = clms.get_user_email(@head_qc_user); 
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_HEAD_QC_USER)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'Head QC อนุมัติ GRR',
 @body =@mail_tpl ;
 
end --IF @totqc > 0

--======================================================================
IF @WAIT_PE_DIV_USER > 0
begin
  set @user_email = clms.get_user_email(@pe_div_user); 
  set @mail_tpl = concat(@mail_tpl,char(10),@MSG_WAIT_PE_DIV_USER)
  EXEC msdb.dbo.sp_send_dbmail
 @recipients =@user_email,
 --@profile_name ='RIST',
 @profile_name = @Nmail_profile,
 @subject =N'PE Division อนุมัติ GRR',
 @body =@mail_tpl ;
 
end --IF @totqc > 0

END

FETCH NEXT FROM sendmail_cursor INTO @WAIT_DO_USER , 
      @WAIT_HEAD_DIV_USER , 
        @WAIT_RESP_USER ,
        @WAIT_HEAD_AFF_USER ,
        @WAIT_HEAD_QC_USER ,
        @WAIT_PE_DIV_USER ,
		@do_user,
		 @head_div_user ,
		 @resp_user,
		 @head_aff_user,
		 @head_qc_user,
		 @pe_div_user   



--======================================================================


END
CLOSE sendmail_cursor  ;
DEALLOCATE sendmail_cursor 	;

END

