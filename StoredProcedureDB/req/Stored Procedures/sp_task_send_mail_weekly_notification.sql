-- =============================================
-- Author:		<Author,,Vanatjaya P. (009131)>
-- Create date: <Create Date,2025.FEB.10,>
-- Description:	<Description,Send Mail,>
-- =============================================
CREATE PROCEDURE [req].[sp_task_send_mail_weekly_notification]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @mail_subject	NVARCHAR(max)	= 'Weekly JRS Alert Notification'
		, @mail_body_format NVARCHAR(100)	= 'HTML'
		, @mail_body		NVARCHAR(MAX)	= ''
		, @mail_profile		NVARCHAR(100)	= 'LSIMailNotify'
		, @mail_to			NVARCHAR(MAX)	= ''
		, @mail_cc			NVARCHAR(MAX)	= ''
		, @URL				NVARCHAR(MAX)	= 'http://10.29.1.242/jobrequest/Home/Temp_Data?GetOrder_no='
		, @emp_mail			NVARCHAR(MAX)	= ''
		, @RowCount			INT				= Null
		, @CurrentRow		INT				= 1
		, @Inchange_id		INT				= null
		, @Inchange_name	NVARCHAR(MAX)	= ''
		
	DECLARE @tempInchange TABLE(
		[inchange_id]	[int]	Not Null
		,[inchange_by]	[nvarchar](max)	Null
		,[emp_mail]		[nvarchar](max)	Null
	);
	Insert into @tempInchange
	select distinct [orders].[inchange_by] as [inchange_id]
		, [employees].[display_name] as [inchange_by]
		, COALESCE([employees].[email], e.[email]) as [emp_mail]
	from AppDB.req.orders
		left join [10.29.1.230].[DWH].[man].[employees] on [employees].[id] = orders.[inchange_by]
		Left JOIN [10.29.1.230].[DWH].[man].[employees_supervisor_span] on [employees].[id] = [employees_supervisor_span].emp_id
		left join [10.29.1.230].[DWH].[man].[employees] e on [employees_supervisor_span].[supervisor_id_step1] = e.id
	where state in (0,1,2,5,6) and inchange_by is not null --and inchange_by in (260)
	select * from @tempInchange

	
	SELECT @RowCount = COUNT(*) FROM @tempInchange;
	--print @RowCount
	
	-- ใช้ WHILE loop เพื่อวนซ้ำ
	WHILE @CurrentRow <= @RowCount
	BEGIN
		-- ดึงข้อมูลทีละแถว
	    SELECT 
	        @emp_mail = [emp_mail]
			,@Inchange_id = [inchange_id]
			,@Inchange_name = [inchange_by]
	    FROM (
	        SELECT ROW_NUMBER() OVER (ORDER BY [emp_mail]) AS RowNum, [inchange_by],[emp_mail],[inchange_id]
	        FROM @tempInchange
	    ) AS Temp
	    WHERE RowNum = @CurrentRow;
		--Declare @problem_sol nvarchar(max) = N'1. ตรวจสอบแล้วพบว่าพนักงาน 009273 คอมพลีททั้งลอทแม่และลอทลูกในระบบ ATP-CIM แต่ไม่มีการใช้งานโปรแกรม  F60711499.15  complete ATP-CIM 2025/06/23 22:48 009273  F60711499.02  complete ATP-CIM 2025/06/23 22:49 009273'
		--Declare @problem_req nvarchar(max) = N'1. ตรวจสอบแล้วพบว่าพนักงาน 009273 คอมพลีททั้งลอทแม่และลอทลูกในระบบ ATP-CIM แต่ไม่มีการใช้งานโปรแกรม  F60711499.15  complete ATP-CIM 2025/06/23 22:48 009273  F60711499.02  complete ATP-CIM 2025/06/23 22:49 009273'
		DECLARE @tempData TABLE(
			[order_no]			[nvarchar](20)	Not Null
			,[category]			[nvarchar](50)	Not Null
			,[problem_request]	[nvarchar](max)	Null
			,[problem_solve]	[nvarchar](max)	Null
			,[delay_d]			[nvarchar](20)	Null
			,[status]			[nvarchar](20)	null
			,[priority]			[int]			null
		);
		Insert into @tempData
		(
			[order_no]	
			,[category]
			,[problem_request]	
			,[problem_solve]
			,[delay_d]	
			,[status]	
			,[priority]
		)
		select [orders].[order_no]
			, [categories].[name]
			, case when len([orders].[problem_request]) > 40 then left([orders].[problem_request],40) + '...'
				else [orders].[problem_request] end as [problem_request]
			, case when len([problem_solve]) > 40 then left([problem_solve],40) + '...'
				else [problem_solve] end as [problem_solve]
			, Cast((CASE WHEN [orders].[state] = 3 THEN 0 ELSE DATEDIFF(DAY, [orders].[requested_at], GETDATE()) END) as nvarchar(20))
			, [item_labels].[label_eng]
			, [orders].[priority]
		FROM [AppDB].[req].[orders]
		LEFT JOIN [AppDB].[req].[categories] ON [orders].[category_id] = [categories].[id]
		LEFT JOIN [AppDB].[req].[item_labels] ON [orders].[state] = [item_labels].[val]
			AND [item_labels].[name] = 'orders.state'
		WHERE [orders].[state] in (0,1,2,5,6) 
			and [orders].[inchange_by] in (@Inchange_id)
		select * from @tempData
	--	DELETE FROM @tempData
	--    -- เพิ่มตัวนับ
	--    SET @CurrentRow = @CurrentRow + 1;
	--END;
	
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
				<table align="center" cellpadding="5" cellspacing="0" width="1024" style="border-collapse: collapse; background-color:#ffffff; font-family:Leelawadee; color:#333333;">
					<tr >
						<td bgcolor="#8B0000" style="padding: 20px 30px; color: #ffffff; font-size: 18px; font-weight: bold;">
							<h2>🔔 Weekly JRS Alert Notification </h2>
						</td>
					</tr>
					<tr style="padding: 20px 20px 0 20px; font-size:16px;">
						<p>
							To <span style="color:blue;">'+ @Inchange_name + N'</span>,</br>
							We have detected an alert message in the web application. </br>
							Please review the details below:
						</p>
					</tr>
					<tr style="padding: 20px;">
						<td >
							<table style="width:100%; border-collapse: collapse; font-size:14px;">
								<tr style="padding-botton:30px;background-color:#7286D3;color:white;">
									<th style="font-weight:bold;border: 1px solid #e1e1e1;height:30px;padding-left:3px;padding-right:3px;">Request No.</th>
									<th style="font-weight:bold;border: 1px solid #e1e1e1;height:30px;padding-left:3px;padding-right:3px;">Category</th>
									<th style="font-weight:bold;border: 1px solid #e1e1e1;height:30px;padding-left:3px;padding-right:3px;">Problem_Request</th>
									<th style="font-weight:bold;border: 1px solid #e1e1e1;height:30px;padding-left:3px;padding-right:3px;">Problem_Solve</th>
									<th style="font-weight:bold;border: 1px solid #e1e1e1;height:30px;padding-left:3px;padding-right:3px;">Delays</th>
									<th style="font-weight:bold;border: 1px solid #e1e1e1;height:30px;padding-left:3px;padding-right:3px;">Status</th>
								</tr>'

		select @mail_body = @mail_body + N'
			<tr style="text-align: center;margin-top:3px;margin-bottom:3px;color:'+ case when [priority]= 1 then 'red' else '#333333'end +N';font-family:Leelawadee;font-size:12px;">				
				<td style="border: 1px solid #e1e1e1;padding-left:3px;padding-right:3px;">' + [order_no] + N'</td>				
				<td style="border: 1px solid #e1e1e1;padding-left:3px;padding-right:3px;">' + [category] + N'</td>				
				<td style="border: 1px solid #e1e1e1;padding-left:3px;padding-right:3px;">' + [problem_request] + N'</td>				
				<td style="border: 1px solid #e1e1e1;padding-left:3px;padding-right:3px;">' + Isnull([problem_solve], N'-') + N'</td>	
				<td style="border: 1px solid #e1e1e1;padding-left:3px;padding-right:3px;">' + [delay_d] + N'</td>					
				<td style="border: 1px solid #e1e1e1;padding-left:3px;padding-right:3px;"><a href="' + @URL + [order_no] + N'&page=Management" target="_blank">' + [status] + N'<a/></td>					
			</tr>'											
		from @tempData
	
		set @mail_body = @mail_body + N'
							</table>
						</td>
					</tr>
					<tr>
						<td bgcolor="#eeeeee" style="padding: 15px; font-size: 10px; color: #777777; text-align: center;">
							This is an automated message. Please do not reply to this email.</br>
							© ' + FORMAT(GETDATE(), 'yyyy') + N' ROHM Intergrated Systems (Thailand) Co., Ltd. - All Rights Reserved
						</td>
					</tr>
				</table>
			</body>
			</html>
		';
		IF @emp_mail IS NOT NULL
		BEGIN
			set @emp_mail = case when @emp_mail is null then '' else @emp_mail + ';' end
			EXEC msdb.dbo.sp_send_dbmail
				@profile_name = @mail_profile, 
				@recipients = @emp_mail, 
				@copy_recipients = @mail_cc,
				@subject = @mail_subject, 
				@body = @mail_body, 
				@body_format = @mail_body_format;
		end
		print 'emp_mail: ' + @emp_mail;
		DELETE FROM @tempData
	    -- เพิ่มตัวนับ
	    SET @CurrentRow = @CurrentRow + 1;
	
	END;

END
