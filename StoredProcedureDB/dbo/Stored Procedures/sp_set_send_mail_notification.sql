-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_send_mail_notification]
	-- Add the parameters for the stored procedure here
	@appname NVARCHAR(MAX),
	@mail_profile NVARCHAR(100),
	@mail_to NVARCHAR(MAX),
	@mail_cc NVARCHAR(MAX) = '',
	@message NVARCHAR(MAX), 
	@datetime NVARCHAR(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	----------------------------------------------------------------------------
	--** DECLARE
	----------------------------------------------------------------------------
	DECLARE @mail_subject NVARCHAR(max) = 'Error Alert Notification (' + CAST(@appname AS NVARCHAR(255)) + ')'
		, @mail_body_format NVARCHAR(100) = 'HTML'
		, @mail_body NVARCHAR(MAX) = ''

	----------------------------------------------------------------------------
	--** BODY MAIL
	----------------------------------------------------------------------------
	SET @mail_body = N'<!DOCTYPE html>
		<html lang="en">
		<head>
			<meta charset="UTF-8">
			<meta name="viewport" content="width=device-width, initial-scale=1.0">
			<title>Error Alert</title>
			<style>
				body {
					font-family: Arial, sans-serif;
					background-color: #f4f4f4;
					margin: 0;
					padding: 20px;
				}
				.container {
					max-width: 600px;
					margin: 0 auto;
					background-color: #fff;
					border: 1px solid #ddd;
					box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
					border-radius: 8px;
					overflow: hidden;
				}
				.header {
					background-color: #0056b3;
					color: white;
					padding: 20px;
					text-align: center;
				}
				.header h1 {
					margin: 0;
				}
				.content {
					padding: 20px;
					line-height: 1.6;
				}
				.error-details {
					background-color: #f8d7da;
					color: #721c24;
					border: 1px solid #f5c6cb;
					padding: 10px;
					margin: 20px 0;
					border-radius: 4px;
				}
				.footer {
					background-color: #f4f4f4;
					color: #888;
					text-align: center;
					padding: 15px;
					font-size: 12px;
				}
				.button {
					display: inline-block;
					padding: 10px 20px;
					background-color: #28a745;
					color: white;
					text-decoration: none;
					border-radius: 5px;
					margin-top: 20px;
					text-align: center;
				}
			</style>
		</head>
		<body>
			<div class="container">
				<div class="header">
					<h1>Error Alert Notification</h1>
				</div>
				<div class="content">
					<p>To whom it may concern,</p>
					<p>We have detected an error in the program. Please review the error details below:</p>

					<div class="error-details">
						<strong>Application Name:</strong> ' + CAST(@appname AS NVARCHAR(255)) + N'<br>
						<strong>Error Message:</strong> ' + @message + N'<br>
						<strong>Error DateTime:</strong> ' + @datetime + N'
					</div>
				</div>
				<div class="footer">
					<p>This is an automated message. Please do not reply to this email.</p>
					<p>© ' + FORMAT(GETDATE(), 'yyyy') + N' ROHM Intergrated Systems (Thailand) Co., Ltd. - All Rights Reserved</p>
				</div>
			</div>
		</body>
		</html>';
	----------------------------------------------------------------------------
	--** SEND MAIL
	----------------------------------------------------------------------------
	EXEC msdb.dbo.sp_send_dbmail
		@profile_name = @mail_profile, 
		@recipients = @mail_to, 
		@copy_recipients = @mail_cc,
		@subject = @mail_subject, 
		@body = @mail_body, 
		@body_format = @mail_body_format;
END
