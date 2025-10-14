-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_send_mail_by_stored]
	-- Add the parameters for the stored procedure here
	@mail_profile varchar(max),
	@mail_name varchar(max),
	@mail_subject varchar(max),
	@message varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	----------------------------------------------------------------------------
	--** declare
	----------------------------------------------------------------------------
	declare @mail_body_format varchar(100) = 'HTML'
		, @sql varchar(max) = ''
		, @mail_body nvarchar(max) = ''
	----------------------------------------------------------------------------
	--** set send mail
	----------------------------------------------------------------------------
	set @mail_body += '<html>';
	set @mail_body += '	<head></head>';
	set @mail_body += '	<body>';
	set @mail_body += '		<b>Date time : </b>' + FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss');
	set @mail_body += '		<br></br>';
	set @mail_body += '		<b>Application name : </b>' + CAST(APP_NAME() AS VARCHAR);
	set @mail_body += '		<br></br>';
	set @mail_body += @message;  
	set @mail_body += '		<br></br>';
	set @mail_body += '	</body>';
	set @mail_body += '</html>';
	--** << execute
	exec msdb.dbo.sp_send_dbmail
		@profile_name = @mail_profile
		, @recipients = @mail_name
		, @subject = @mail_subject
		, @body = @mail_body
		, @body_format = @mail_body_format;
	----select @mail_body
	--** >> execute
END
