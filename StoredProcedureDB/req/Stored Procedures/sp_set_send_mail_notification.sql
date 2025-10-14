
-- =============================================
-- Author:		<Author,,Vanatjaya P. (009131)>
-- Create date: <Create Date,2025.FEB.10,>
-- Description:	<Description,Send Mail,>
-- =============================================
CREATE PROCEDURE [req].[sp_set_send_mail_notification]
	-- Add the parameters for the stored procedure here
	@request_id		INT				= Null
	,@send_mail		NVARCHAR(MAX)	= Null--'chananart.piy@adm.rohmthai.com'
	,@set_page		Nvarchar(max)	= null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	--(
	--	  [record_at]
	--	, [record_class]
	--	, [login_name]
	--	, [hostname]
	--	, [appname]
	--	, [command_text]
	--	, [lot_no]
	--)
	--SELECT GETDATE()
	--	, '4'
	--	, ORIGINAL_LOGIN()
	--	, HOST_NAME()
	--	, APP_NAME()
	--	, 'EXEC [req].[sp_set_send_mail_notification]  @request_id = ''' + CAST(ISNULL(@request_id, 'NULL') AS varchar(10))
	--	, CAST(ISNULL(@request_id, 'NULL') AS varchar(10))
	----------------------------------------------------------------------------
	--** DECLARE
	----------------------------------------------------------------------------
	DECLARE @mail_subject NVARCHAR(max) = 'Test JRS Alert Notification'
		, @mail_body_format NVARCHAR(100) = 'HTML'
		, @mail_body NVARCHAR(MAX) = ''
		, @mail_profile NVARCHAR(100) = 'LSIMailNotify'
		, @mail_to NVARCHAR(MAX) = ''
		, @mail_cc NVARCHAR(MAX) = 'chananart.piy@adm.rohmthai.com;'
		, @request_no NVARCHAR(11) = ''
		, @priority NVARCHAR(20)
		, @state NVARCHAR(30)
		, @state_id INT = NULL
		, @state_name NVARCHAR(20) = ''
		, @requested_by NVARCHAR(20) = ''
		, @handler_by NVARCHAR(20) = ''
		, @category VARCHAR(50) = ''
		, @problem VARCHAR(100) = ''
		, @app_name VARCHAR(100) = ''
		, @subject NVARCHAR(100) = ''
		, @mc_name NVARCHAR(150) = ''
		, @requested_at NVARCHAR(80) = ''
		, @last_update_at NVARCHAR(80) = ''
		, @delay_day NVARCHAR(10) = ''
		, @user_solved_id INT = NULL
		, @user_handle_id INT = NULL
		, @page nvarchar(50) = null
		, @URL nvarchar(max) = null

	SELECT @request_no = [orders].[order_no] 
		, @priority = IIF([orders].[priority]= 1, 'header-urgent', 'header')
		, @state = ( CASE [orders].[state]
			WHEN 0 THEN 'wip-details'
			WHEN 1 THEN 'analysis-details'
			WHEN 2 THEN 'doing-details'
			WHEN 3 THEN 'complete-details'
			WHEN 4 THEN 'cancel-details'
			WHEN 5 THEN 'hold-details'
			WHEN 6 THEN 'wait-details'
			ELSE 'cancel-details' END )
		, @state_id = [orders].[state]
		, @state_name = [item_labels].[label_eng]
		, @requested_by = [employees].[display_name]
		, @handler_by = [us_handle].[display_name] 
		--, @mail_to = ( CASE 
		--	WHEN @state = 3 or @state = 4 THEN CONCAT( [users].[email] , ', ' , [us_handle].[email] ) --[users].[email] + ', ' + [us_handle].[email] #17/02/2025 15.48 far
		--	ELSE [us_handle].[email] END )
		, @mail_to = IIF(@send_mail = Null or @send_mail = '', [us_handle].[email], @send_mail+';')
		, @category = [categories].[name] 
		, @problem = [problems].[name] 
		, @app_name = [applications].[name]
		, @subject = [orders].[problem_request]
		, @mc_name = ISNULL([orders].[other_detail_2], '-')
		, @requested_at = FORMAT([orders].[requested_at], 'yyyy-MM-dd HH:mm:ss')
		, @last_update_at = ISNULL(FORMAT([orders].[solved_at], 'yyyy-MM-dd HH:mm:ss'), '-')
		, @delay_day = CAST(DATEDIFF(MINUTE, [orders].[requested_at], GETDATE()) / 1440 AS VARCHAR(10)) --days
		, @user_solved_id = [orders].[solved_by] 
		, @user_handle_id = CAST([orders].[inchange_by] AS int)
		, @page = IIF(@set_page is null or @set_page = '', 'index', @set_page)
		, @URL = 'http://10.29.1.245/jobrequesttest/Home/Temp_Data?GetOrder_no='+ @request_no + N'&page='+ @page
	FROM [AppDB_app_244].[req].[orders]
	LEFT JOIN [AppDB_app_244].[req].[categories] ON [orders].[category_id] = [categories].[id]
	LEFT JOIN [AppDB_app_244].[req].[problems] ON [orders].[problem_id] = [problems].[id]
	LEFT JOIN [AppDB_app_244].[req].[applications] ON [orders].[app_id] = [applications].[id]
	LEFT JOIN [10.29.1.230].[DWH].[man].[employees] ON [orders].[requested_by] = [employees].[id]
	LEFT JOIN [AppDB_app_244].[req].[item_labels] ON [item_labels].[name] = 'orders.state'
		AND [orders].[state] = [item_labels].[val]
	LEFT JOIN [10.29.1.230].[DWH].[man].[employees] us_handle ON [orders].[inchange_by] = us_handle.[id]
	WHERE [orders].[id] = @request_id;
	
	--check user update with user handle is maching yes or no ?
	IF ((@user_solved_id = @user_handle_id and @state_id != 2 and @state_id != 6)or ((@state_id = 2 or @state_id =6) and ( @send_mail is null or @send_mail ='')))/**/
	BEGIN
		--INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		--(
		--	  [record_at]
		--	, [record_class]
		--	, [login_name]
		--	, [hostname]
		--	, [appname]
		--	, [command_text]
		--	, [lot_no]
		--)
		--SELECT GETDATE()
		--	, '4'
		--	, ORIGINAL_LOGIN()
		--	, HOST_NAME()
		--	, APP_NAME()
		--	, 'EXEC [req].[sp_set_send_mail_notification] (@user_solved_id = @user_handle_id) @request_id = ''' + CAST(ISNULL(@request_id, 'NULL') AS varchar(10))
		--	, CAST(ISNULL(@request_id, 'NULL') AS varchar(10))
		print 'soled_id = handle_id'
		RETURN
	END
	--IF ((@state_id = 2 or @state_id =6) and ( @send_mail is null or @send_mail =''))

	--check mail is null
	IF (@mail_to IS NULL OR @mail_to = '')
	BEGIN
		--INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		--(
		--	  [record_at]
		--	, [record_class]
		--	, [login_name]
		--	, [hostname]
		--	, [appname]
		--	, [command_text]
		--	, [lot_no]
		--)
		--SELECT GETDATE()
		--	, '4'
		--	, ORIGINAL_LOGIN()
		--	, HOST_NAME()
		--	, APP_NAME()
		--	, 'EXEC [req].[sp_set_send_mail_notification] (@mail_to IS NULL OR @mail_to = '') @request_id = ''' + CAST(ISNULL(@request_id, 'NULL') AS varchar(10))
		--	, CAST(ISNULL(@request_id, 'NULL') AS varchar(10))
		print 'mail_to == null'
		RETURN
	END
	--IF
	----------------------------------------------------------------------------
	--** BODY MAIL
	----------------------------------------------------------------------------
	--SET @mail_body = N'<!DOCTYPE html>
	--	<html lang="en">
	--	<head>
	--		<meta charset="UTF-8">
	--		<meta name="viewport" content="width=device-width, initial-scale=1.0">
	--		<title>Alert</title>
	--		<style>
	--			body {
	--				font-family: Arial, sans-serif;
	--				background-color: #f4f4f4;
	--				margin: 0;
	--				padding: 20px;
	--			}
	--			.container {
	--				max-width: 600px;
	--				margin: 0 auto;
	--				background-color: #fff;
	--				border: 1px solid #ddd;
	--				box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
	--				border-radius: 8px;
	--				overflow: hidden;
	--			}
	--			.header {
	--				background-color: #0056b3;
	--				color: white;
	--				padding: 20px;
	--				text-align: center;
	--			}
	--			.header h1 {
	--				margin: 0;
	--			}
	--			.content {
	--				padding: 20px;
	--				line-height: 1.6;
	--			}
	--			.wip-details {
	--				background-color: #FEB941;
	--				color: #1a1919;
	--				border: 1px solid #FEB941;
	--				padding: 10px;
	--				margin: 20px 0;
	--				border-radius: 4px;
	--			}
	--			.analysis-details {
	--				background-color: #5AB2FF;
	--				color: #1a1919;
	--				border: 1px solid #5AB2FF;
	--				padding: 10px;
	--				margin: 20px 0;
	--				border-radius: 4px;
	--			}
	--			.doing-details {
	--				background-color: #102C57;
	--				color: #fff4f4;
	--				border: 1px solid #102C57;
	--				padding: 10px;
	--				margin: 20px 0;
	--				border-radius: 4px;
	--			}
	--			.complete-details {
	--				background-color: #347928;
	--				color: #fff4f4;
	--				border: 1px solid #347928;
	--				padding: 10px;
	--				margin: 20px 0;
	--				border-radius: 4px;
	--			}
	--			.cancel-details {
	--				background-color: #6F6F6F;
	--				color: #fff4f4;
	--				border: 1px solid #6F6F6F;
	--				padding: 10px;
	--				margin: 20px 0;
	--				border-radius: 4px;
	--			}
	--			.hold-details {
	--				background-color: #ff762a;
	--				color: #fff4f4;
	--				border: 1px solid #ff762a;
	--				padding: 10px;
	--				margin: 20px 0;
	--				border-radius: 4px;
	--			}
	--			.footer {
	--				background-color: #f4f4f4;
	--				color: #888;
	--				text-align: center;
	--				padding: 15px;
	--				font-size: 12px;
	--			}
	--			.button {
	--				display: inline-block;
	--				padding: 10px 20px;
	--				background-color: #28a745;
	--				color: white;
	--				text-decoration: none;
	--				border-radius: 5px;
	--				margin-top: 20px;
	--				text-align: center;
	--			}
	--			.font-url{
	--				color:#fff;
	--			}
	--			.header-urgent {
	--			    background-color: darkred;
	--			    color: white;
	--			    padding: 20px;
	--			    text-align: center;
	--			}
	--			.header-urgent h1 {
	--			    margin: 0;
	--			}
	--		</style>
	--	</head>
	--	<body>
	--		<table role="presentation" width="700" cellpadding="0" cellspacing="0" border="0" style="background-color: #f4f4f4;" align="center">
	--			<tr style="background-color: #ffffff; border: 1px solid #ddd;">
	--				<td class="' + @priority + N'" colspan="3">
	--					<h1 style="color: #ffffff; font-size: 24px; margin: 0;">' + @mail_subject + N'</h1>
	--				</td>
	--			</tr>
	--			<tr style="background-color: #ffffff; border: 1px solid #ddd;">
	--				<td class="content" colspan="5">
	--					<p>To whom it may concern,</p>
	--					<p>We have detected an alert message in the web application. </p>
	--					<p> Please review the details below:</p>
	--				</td>
	--			</tr>
	--			<tr style="background-color: #ffffff; border: 1px solid #ddd;">
	--				<td align="center">
	--					<table class="' + @state + N'" role="presentation" width="650">
	--						<tr>
	--							<td class="content">
	--								<strong>Request No:</strong> '+ @request_no + N' <br>
	--								<strong>Problem:</strong> '+ @problem + N' <br>
	--								<strong>Status:</strong> '+ @state_name + N' <br>
	--								<strong>Category:</strong> '+ @category + N' <br>
	--								<strong>App name:</strong> '+ @app_name + N' <br>
	--								<strong>Machine:</strong> '+ @mc_name + N' <br>
	--								<strong>Request Date:</strong> '+ @requested_at + N' <br>
	--								<strong>Delay:</strong> '+ @delay_day + N' Day <br>
	--								<strong>Request By:</strong> '+ @requested_by + N' <br>
	--								<strong>Handler By:</strong> '+ @handler_by + N' <br>
	--								<strong>Last Update:</strong> '+ @last_update_at + N' <br>
	--								<strong>URL:</strong> <a class="font-url" href="http://10.29.1.242/jobrequest?GetOrder_no='+ @request_no + N'" target="_blank">Click here</a><br>
	--								<strong>URL:</strong> <a class="font-url" href="http://10.29.1.245/jobrequesttest/Home/Temp_Data?GetOrder_no='+ @request_no + N'&page='+ @page +'" target="_blank">Click here</a><br>
	--							</td>
	--						</tr>
	--					</table>
	--				</td>
	--			</tr>
	--			<tr style="background-color: #ffffff; border: 1px solid #ddd;">
	--				<td class="content"  colspan="5">
	--					<p>This is an automated message. Please do not reply to this email.</p>
	--					<p>© ' + FORMAT(GETDATE(), 'yyyy') + N' ROHM Intergrated Systems (Thailand) Co., Ltd. - All Rights Reserved</p>
	--				</td>
	--			</tr>
	--		</table>
	--	</body>
	--</html>';
	SET @mail_body = N'
		<!DOCTYPE html>
		<html lang="en">
		<head>
			<meta charset="UTF-8">
			<meta name="viewport" content="width=device-width, initial-scale=1.0">
			<title>Alert</title>
			<style>
				.wip-details {
					background-color: #FEB941;
					color: #ffffff;
				}
				.analysis-details {
					background-color: #5AB2FF;
					color: #ffffff;
				}
				.doing-details {
					background-color: #102C57;
					color: #ffffff;
				}
				.complete-details {
					background-color: #347928;
					color: #ffffff;
				}
				.cancel-details {
					background-color: #6F6F6F;
					color: #ffffff;
				}
				.hold-details {
					background-color: #ff762a;
					color: #ffffff;
				}
				.wait-details {
					background-color: #abc903;
					color: #ffffff;
				}
				.header-urgent {
				    color: red;
				}
			</style>
		</head>
		<body style="margin:0; padding:0; background-color:#f4f4f4;">
			<table align="center" cellpadding="0" cellspacing="0" width="800" style="border-collapse: collapse; background-color:#ffffff; font-family:Segoe UI, sans-serif; color:#333333;">
				<tr >
					<td class="' + @state + N'" bgcolor="#8B0000" style="padding: 20px 30px; color: #ffffff; font-size: 22px; font-weight: bold;">
						<h1>🔔 Test JRS Alert Notification </h1>
					</td>
				</tr>
				<tr style="padding: 20px 30px 0 30px; font-size:16px;">
					<p>
						To whom it may concern,</br>
						We have detected an alert message in the web application. </br>
						Please review the details below:
					</p>
				</tr>
				<tr>
					<td style="padding: 30px;">
						<table style="width:100%; border-collapse: collapse; font-size:16px;" class="'+ @priority +N'">
							<tr>
								<td style="font-weight:bold; width:120px;">Request No:</td>
								<td>' + @request_no + N'</td>
							</tr>
							<tr>
								<td style="font-weight:bold;">Problem:</td>
								<td>' + @problem + N'</td>
							</tr>
							<tr>
								<td style="font-weight:bold;">Status:</td>
								<td>' + @state_name + N'</td>
							</tr>
							<tr>
								<td style="font-weight:bold;">Category:</td>
								<td>' + @category + N'</td>
							</tr>
							<tr>
								<td style="font-weight:bold;">App name:</td>
								<td>' + @app_name + N'</td>
							</tr>
							<tr>
								<td style="font-weight:bold;">Machine:</td>
								<td>' + @mc_name + N'</td>
							</tr>	
							<tr>
								<td style="font-weight:bold;">Request Date:</td>
								<td>' + @requested_at + N'</td>
							</tr>	
							<tr>
								<td style="font-weight:bold;">Delay:</td>
								<td>' + @delay_day + N'</td>
							</tr>							
							<tr>
								<td style="font-weight:bold;">Request By:</td>
								<td>' + @requested_by + N'</td>
							</tr>
							<tr>
								<td style="font-weight:bold;">Handler By:</td>
								<td>' + @handler_by + N'</td>
							</tr>
							<tr>
								<td style="font-weight:bold;">Last Update:</td>
								<td>' + @last_update_at + N'</td>
							</tr>
							<tr>
								<td style="font-weight:bold;">URL:</td>
								<td><a href="' + @URL + N'" target="_blank">Click here<a/></td>
							</tr>
						</table>
					</td>
				</tr>
				<tr>
					<td bgcolor="#eeeeee" style="padding: 15px; font-size: 12px; color: #777777; text-align: center;">
						This is an automated message. Please do not reply to this email.</br>
						© ' + FORMAT(GETDATE(), 'yyyy') + N' ROHM Intergrated Systems (Thailand) Co., Ltd. - All Rights Reserved
					</td>
				</tr>
			</table>
		</body>
		</html>
	';
	----------------------------------------------------------------------------
	--** SEND MAIL
	----------------------------------------------------------------------------
	print @user_solved_id 
	print @user_handle_id 
	print @state_id 
	set @mail_to = @mail_cc;
	print @page
	print 'exec sp_send_mail version in StoredProcedureDB 245'
	EXEC msdb.dbo.sp_send_dbmail
		@profile_name = @mail_profile, 
		@recipients = @mail_to, 
		@copy_recipients = @mail_cc,
		@subject = @mail_subject, 
		@body = @mail_body, 
		@body_format = @mail_body_format;

END
