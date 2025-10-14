-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ctrlic].[sp_send_mail_approve_skill]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	declare @totchk int,@totappr int,@totqc int;
	declare @msgchk nvarchar(1000),@msgappr nvarchar(1000),@msgqc nvarchar(1000),@url nvarchar(1000);

 select @totchk= sum(case when check_date is null then 1 else 0 end ),
		@totappr = sum(case when check_date is not null and approve_date is null then 1 else 0 end ),
		@totqc = sum(case when approve_date is not null and qc_approve_date is null then 1 else 0 end )
from APCSProDB.ctrlic.approve_skill;

--set @url ='http://10.28.33.111/LicenseManagementSystem/Account/Login?returnUrl=/SkillTest/ApproveSkill';
set @url ='http://webserv.thematrix.net/LicenseManagementSystem/Account/Login?returnUrl=/SkillTest/ApproveSkill';

if @totchk + @totappr + @totqc > 0
begin
			IF @totchk > 0
				SET @msgchk =concat( @url ,N'?mode=checkuser' ,char(10) , N'รอตรวจสอบจำนวน ', @totchk, N' รายการ', char(10));

			IF @totappr > 0
				SET @msgappr = concat(@url , N'?mode=approveuser', char(10) , N'รออนุมัติจำนวน ' , @totappr , N' รายการ', char(10));

			IF @totqc > 0
				SET @msgqc = concat(@url , N'?mode=qcuser', char(10) , N'รอQC อนุมัติจำนวน ' ,@totqc , N' รายการ', char(10));


			declare @mail_tpl nvarchar(4000),@email nvarchar(4000),@mail_subj nvarchar(150);

			--set @mail_subj='Test1010';
			DECLARE douser_cursor CURSOR FOR 
				SELECT 
				  trim([mail_template])
				   ,trim([email])
				   ,trim([mail_subj])
			  FROM [APCSProDB].[ctrlic].[group_mail] 
			  WHERE [app_name] ='CTRL_LICENSE' and [group_type] ='DO_USER' and [is_active] = 1;

			OPEN douser_cursor  
			FETCH NEXT FROM douser_cursor INTO @mail_tpl,@email,@mail_subj  ;

				WHILE @@FETCH_STATUS = 0  
					BEGIN  
				   set @mail_tpl = concat(@mail_tpl,char(10),@msgchk,@msgappr,@msgqc)
				   EXEC msdb.dbo.sp_send_dbmail
					  @recipients =@email,
					  @profile_name ='RIST',
					  @subject =@mail_subj,
					  @body =@mail_tpl ;
				  FETCH NEXT FROM douser_cursor INTO @mail_tpl,@email,@mail_subj  
				END 

			CLOSE douser_cursor  ;
			DEALLOCATE douser_cursor 	;
--==========================================================
			IF @totchk > 0
			begin
				DECLARE checkuser_cursor CURSOR FOR 
					SELECT 
					  trim([mail_template])
					   ,trim([email])
					   ,trim([mail_subj])
				  FROM [APCSProDB].[ctrlic].[group_mail] 
				  WHERE [app_name] ='CTRL_LICENSE' and [group_type] ='CHECK_USER' and [is_active] = 1;

				OPEN checkuser_cursor  
				FETCH NEXT FROM checkuser_cursor INTO @mail_tpl,@email,@mail_subj  ;

					WHILE @@FETCH_STATUS = 0  
						BEGIN  
					   set @mail_tpl = concat(@mail_tpl,char(10),@msgchk)
					   EXEC msdb.dbo.sp_send_dbmail
						  @recipients =@email,
						  @profile_name ='RIST',
						  @subject =@mail_subj,
						  @body =@mail_tpl ;
					  FETCH NEXT FROM checkuser_cursor INTO @mail_tpl,@email,@mail_subj  
					END 

				CLOSE checkuser_cursor  ;
				DEALLOCATE checkuser_cursor 	;
			end --IF @totchk > 0
--======================================================================

			IF @totappr > 0
			begin
				DECLARE appruser_cursor CURSOR FOR 
					SELECT 
					  trim([mail_template])
					   ,trim([email])
					   ,trim([mail_subj])
				  FROM [APCSProDB].[ctrlic].[group_mail] 
				  WHERE [app_name] ='CTRL_LICENSE' and [group_type] ='APPROVE_USER' and [is_active] = 1;

				OPEN appruser_cursor  
				FETCH NEXT FROM appruser_cursor INTO @mail_tpl,@email,@mail_subj  ;

					WHILE @@FETCH_STATUS = 0  
						BEGIN  
					   set @mail_tpl = concat(@mail_tpl,char(10),@msgappr)
					   EXEC msdb.dbo.sp_send_dbmail
						  @recipients =@email,
						  @profile_name ='RIST',
						  @subject =@mail_subj,
						  @body =@mail_tpl ;
					  FETCH NEXT FROM appruser_cursor INTO @mail_tpl,@email,@mail_subj  
					END 

				CLOSE appruser_cursor  ;
				DEALLOCATE appruser_cursor 	;
			end --IF @totappr > 0
--======================================================================
			IF @totqc > 0
			begin
				DECLARE qcuser_cursor CURSOR FOR 
					SELECT 
					  trim([mail_template])
					   ,trim([email])
					   ,trim([mail_subj])
				  FROM [APCSProDB].[ctrlic].[group_mail] 
				  WHERE [app_name] ='CTRL_LICENSE' and [group_type] ='QC_USER' and [is_active] = 1;

				OPEN qcuser_cursor  
				FETCH NEXT FROM qcuser_cursor INTO @mail_tpl,@email,@mail_subj  ;

					WHILE @@FETCH_STATUS = 0  
						BEGIN  
					   set @mail_tpl = concat(@mail_tpl,char(10),@msgqc)
					   EXEC msdb.dbo.sp_send_dbmail
						  @recipients =@email,
						  @profile_name ='RIST',
						  @subject =@mail_subj,
						  @body =@mail_tpl ;
					  FETCH NEXT FROM qcuser_cursor INTO @mail_tpl,@email,@mail_subj  
					END 

				CLOSE qcuser_cursor  ;
				DEALLOCATE qcuser_cursor 	;
			end --IF @totqc > 0
END --end main if


	--set @mail_subj='Test1010';
	


END
