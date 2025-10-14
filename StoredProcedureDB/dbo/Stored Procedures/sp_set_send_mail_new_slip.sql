-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_send_mail_new_slip]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	---- # Old
	--DECLARE @text varchar(max) = (select distinct [device_names].[assy_name] + '; ' + CHAR(13)
	--from [APCSProDB].[trans].[lots]
	--inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
	--inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
	--inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
	--inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]
	--where [lots].[wip_state] in (20,10,0)
	--and [device_slips].[is_released] = 2
	--and [packages].[is_enabled] = 1
	--FOR XML PATH(''))

	--EXEC msdb.dbo.sp_send_dbmail
	-- @recipients = 'chaiwat@mnf2.rohmthai.com;nucha.pra@mnf2.rohmthai.com;jsupichra@mnf2.rohmthai.com;satchara@mnf2.rohmthai.com;sjatupong@mnf2.rohmthai.com'
	-- , @profile_name ='Test external email'
	-- , @subject = 'Slip New Version'
	-- , @body = @text
	---- # New
	----------------------------------------------------------------------------
	--** DECLARE
	----------------------------------------------------------------------------
	DECLARE @appname NVARCHAR(MAX)
		, @mail_profile NVARCHAR(100) = 'Test external email'
		, @mail_to NVARCHAR(MAX) = 'chaiwat@mnf2.rohmthai.com;nucha.pra@mnf2.rohmthai.com;jsupichra@mnf2.rohmthai.com;satchara@mnf2.rohmthai.com;sjatupong@mnf2.rohmthai.com;'
		, @mail_cc NVARCHAR(MAX) = 'kittitat.pan@mnf2.rohmthai.com;'
		, @mail_subject NVARCHAR(max) = 'Slip New Version'
		, @mail_body_format NVARCHAR(100) = 'HTML'
		, @mail_body NVARCHAR(MAX) = ''
		, @mail_bodydata NVARCHAR(MAX) = ''

	--SET @mail_bodydata = (SELECT CAST((
	--	SELECT DISTINCT '<tr><td>' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS NVARCHAR(20)) + '</td><td>' + [device_names].[assy_name] + '</td></tr>'
	--	FROM [APCSProDB].[trans].[lots]
	--	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	--	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	--	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	--	INNER JOIN [APCSProDB].[method].[packages] ON [packages].[id] = [device_names].[package_id]
	--	WHERE [lots].[wip_state] IN (20, 10, 0)
	--		AND [device_slips].[is_released] = 2
	--		AND [packages].[is_enabled] = 1
	--	FOR XML PATH(''), TYPE
	--).value('.', 'NVARCHAR(MAX)') AS NVARCHAR(MAX)));
	SET @mail_bodydata = (SELECT CAST((
			SELECT '<tr><td>' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS NVARCHAR(20)) + '</td><td>' + [assy_name] + '</td></tr>'
			FROM (
				SELECT DISTINCT [device_names].[assy_name]
				FROM [APCSProDB].[trans].[lots]
				INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
				INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
				INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
				INNER JOIN [APCSProDB].[method].[packages] ON [packages].[id] = [device_names].[package_id]
				WHERE [lots].[wip_state] IN (20, 10, 0)
					AND [device_slips].[is_released] = 2
					AND [packages].[is_enabled] = 1
			) AS [table1]
		FOR XML PATH(''), TYPE
	).value('.', 'NVARCHAR(MAX)') AS NVARCHAR(MAX)));

	IF (@mail_bodydata IS NOT NULL)
	BEGIN
		----------------------------------------------------------------------------
		--** BODY MAIL
		----------------------------------------------------------------------------
		SET @mail_body = N'<!DOCTYPE html>
			<html lang="en">
			<head>
				<meta charset="UTF-8">
				<meta name="viewport" content="width=device-width, initial-scale=1.0">
				<title>Slip New Version</title>
				<style>
					body {
						font-family: Arial, sans-serif;
						background-color: #f4f4f4;
						margin: 0;
						padding: 20px;
					}
					.container {
						max-width: 1000px;
						margin: 0 auto;
						background-color: #fff;
						border: 1px solid #ddd;
						box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
						border-radius: 8px;
						overflow: hidden;
					}
					.header {
						background-color: #33b300;
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
					.table-container {
						width: 100%;
					}
					table {
						width: 100%;
						border-collapse: collapse;
					}
					th, td {
						border: 1px solid black;
					}
					th:nth-child(1), td:nth-child(1) {
						width: 10%;
					}
					th:nth-child(2), td:nth-child(2) {
						width: 90%;
					}
				</style>
			</head>
			<body>
				<div class="container">
					<div class="header">
						<h1>Slip New Version Notification</h1>
					</div>
					<div class="content">
						<p>To whom it may concern,</p>
						<p>We have a new slip attached for your. Please review the details below.</p>

						<div class="table-container">
							<table>
								<thead style="background-color:#d92c2c;color:white;">
									<tr>
										<th>No.</th>
										<th>Assy name</th>
									</tr>
								</thead>
								<tbody>' +
									 @mail_bodydata +
								'</tbody>
							</table>
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
END
