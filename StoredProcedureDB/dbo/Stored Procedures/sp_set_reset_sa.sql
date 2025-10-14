-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_reset_sa]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	----------------------------------------------------------------------------
	--** declare
	----------------------------------------------------------------------------
	declare @date date = getdate() --'2021-05-31'

	declare @user varchar(100) = 'sa'
		, @password varchar(100) = ''
		--, @mail_profile varchar(100) = 'RIST'
		--, @mail_name varchar(100) = 'LSI_Database_Admin@rist.local'
		--, @mail_subject varchar(100) = 'Auto Change Password'
		--, @mail_body_format varchar(100) = 'HTML'
		, @sql varchar(max) = ''
		--, @mail_body nvarchar(max) = ''
	----------------------------------------------------------------------------
	--** set password
	----------------------------------------------------------------------------
	set @password = (select 'Rist' + format(@date, 'yyMM') + '*');
	set @sql = 'ALTER LOGIN ' + @user + ' WITH PASSWORD = ' + '''' + @password  + ''',CHECK_POLICY = OFF;';
	--** << execute
	execute(@sql);
	----select @sql
	--** >> execute
	------------------------------------------------------------------------------
	----** set send mail
	------------------------------------------------------------------------------
	--set @mail_body += '<html>';
	--set @mail_body += '	<head>';
	--set @mail_body += '		<style>  td {border: solid black;border-width: 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font: 11px arial}  </style>';
	--set @mail_body += '	</head>';
	--set @mail_body += '	<body>Change on : ' + convert(varchar(50), @date, 106);
	--set @mail_body += '		<br></br>';
	--set @mail_body += '		<table cellpadding=0 cellspacing=0 border=0>';
	--set @mail_body += '			<tr>';
	--set @mail_body += '				<td bgcolor=#E6E6FA>';
	--set @mail_body += '					<b>USER</b>';
	--set @mail_body += '				</td>';
	--set @mail_body += '				<td bgcolor=#E6E6FA>';
	--set @mail_body += '					<b>PASSWORD</b>';
	--set @mail_body += '				</td>';
	--set @mail_body += '			</tr>';
	--set @mail_body += '			<tr>';
	--set @mail_body += '				<td bgcolor=#E6E6FA>';
	--set @mail_body += '					<b>' + @user + '</b>';
	--set @mail_body += '				</td>';
	--set @mail_body += '				<td bgcolor=#E6E6FA>';
	--set @mail_body += '					<b>' + @password + '</b>';
	--set @mail_body += '				</td>';
	--set @mail_body += '			</tr>';
	--set @mail_body += '		</table>';
	--set @mail_body += '	</body>';
	--set @mail_body += '</html>';
	----** << execute
	--exec msdb.dbo.sp_send_dbmail
	--	@profile_name = @mail_profile
	--	, @recipients = @mail_name
	--	, @subject = @mail_subject
	--	, @body = @mail_body
	--	, @body_format = @mail_body_format;
	------select @mail_body
	----** >> execute
END
