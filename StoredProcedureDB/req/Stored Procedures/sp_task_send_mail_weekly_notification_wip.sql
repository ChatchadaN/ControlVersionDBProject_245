-- =============================================
-- Author:		<Author,,Vanatjaya P. (009131)>
-- Create date: <Create Date,2025.FEB.10,>
-- Description:	<Description,Send Mail,>
-- =============================================
CREATE PROCEDURE [req].[sp_task_send_mail_weekly_notification_wip]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @mail_subject	NVARCHAR(max)	= 'Weekly JRS Alert Notification'
		, @mail_body_format NVARCHAR(100)	= 'HTML'
		, @mail_body		NVARCHAR(MAX)	= ''
		, @mail_profile		NVARCHAR(100)	= 'LSIMailNotify'
		, @mail_to			NVARCHAR(MAX)	= 'chananart.piy@adm.rohmthai.com'
		, @mail_cc			NVARCHAR(MAX)	= ''
		, @URL				NVARCHAR(MAX)	= 'http://10.29.1.242/jobrequest/Home/Temp_Data?GetOrder_no='
		, @emp_mail			NVARCHAR(MAX)	= ''
		, @RowCount			INT				= Null
		, @CurrentRow		INT				= 1
		, @CurrentCateID	INT				= null
		, @Inchange_name	NVARCHAR(MAX)	= ''
		
	DECLARE @tempInchange TABLE(
		[category_id]   [int]       NULL,
		[inchange_by]   NVARCHAR(MAX) NULL,
		[emp_mail]      NVARCHAR(MAX) NULL
	);
	INSERT INTO @tempInchange
	SELECT 
	    --NULL AS [inchange_id], -- ไม่จำเป็นต้องใช้ inchange_id ในกรณีนี้
		[inchanges].[category_id],
	    STRING_AGG([employees].[display_name], ', ') AS [inchange_by], -- รวมชื่อ
	    STRING_AGG([employees].[email], '; ') AS [emp_mail] -- รวมอีเมล
	FROM AppDB.req.inchanges
	LEFT JOIN [10.29.1.230].[DWH].[man].[employees] 
	    ON [employees].[id] = [inchanges].[inchange_by]
	WHERE 
	    (category_id = 1 AND inchange_by IN (3218, 916, 2730)) OR
	    (category_id = 2 AND inchange_by IN (916)) OR
	    (category_id = 3 AND inchange_by IN (3245)) OR
	    (category_id = 4 AND inchange_by IN (3245, 916, 2730)) OR
	    (category_id = 5 AND inchange_by IN (550)) OR
	    (category_id = 6 AND inchange_by IN (4491)) OR
	    (category_id = 7 AND inchange_by IN (3245)) OR
	    (category_id = 13 AND inchange_by IN (2399))
	GROUP BY [inchanges].[category_id];
	--select * from @tempInchange

	DECLARE @tempCate TABLE(
		RowNum INT IDENTITY(1,1),
		[category_id]   [int]       NULL
	);
	INSERT INTO @tempCate
	select distinct category_id --as [category_id]
	from AppDB.req.orders --cate_data 
	where inchange_by is null
	--select * from @tempCate
	
	SELECT @RowCount = COUNT(*) FROM @tempCate;
	--print @RowCount
	
	-- ใช้ WHILE loop เพื่อวนซ้ำ
	WHILE @CurrentRow <= @RowCount
	BEGIN
		-- ดึงข้อมูลทีละแถว
		print  @CurrentRow
	    SELECT @CurrentCateID = category_id
		FROM @tempCate
		WHERE RowNum = @CurrentRow;
		PRINT 'Processing CategoryID: ' + CAST(@CurrentCateID AS NVARCHAR);
		
		select @Inchange_name = [inchange_by]
			,@emp_mail = [emp_mail]
		from @tempInchange
		where category_id = @CurrentCateID

		DECLARE @tempData TABLE(
			[order_no]			[nvarchar](20)	Not Null
			,[category_id]		[int]			null
			,[category]			[nvarchar](50)	Not Null
			,[application]		[nvarchar](max)	Null
			,[problem_request]	[nvarchar](max)	Null
			--,[problem_solve]	[nvarchar](max)	Null
			,[delay_d]			[nvarchar](20)	Null
			,[status]			[nvarchar](20)	null
			,[priority]			[int]			null
		);
		Insert into @tempData
		(
			[order_no]	
			,[category_id]
			,[category]
			,[application]
			,[problem_request]	
			--,[problem_solve]
			,[delay_d]	
			,[status]	
			,[priority]
		)
		select orders.order_no
			, orders.category_id
			, categories.name
			, applications.name
			, case when len([orders].[problem_request]) > 40 then left([orders].[problem_request],40) + '...'
				else [orders].[problem_request] end as [problem_request]
			--, orders.state --,inchage.id, inchage.emp_code, inchage.email
			, Cast((CASE WHEN [orders].[state] = 3 THEN 0 ELSE DATEDIFF(DAY, [orders].[requested_at], GETDATE()) END) as nvarchar(20)) as delay_d
			, [item_labels].[label_eng]
			, [orders].[priority]
		from AppDB.req.orders
		LEFT JOIN [AppDB].[req].[categories] ON [orders].[category_id] = [categories].[id]
		LEFT JOIN [AppDB].[req].[item_labels] ON [orders].[state] = [item_labels].[val]
			AND [item_labels].[name] = 'orders.state'
		Left join AppDB.req.applications on orders.app_id = applications.id
		where orders.inchange_by is null and orders.category_id = @CurrentCateID
		--select * from @tempData
		
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
									<th style="font-weight:bold;border: 1px solid #e1e1e1;height:30px;padding-left:3px;padding-right:3px;">Application</th>
									<th style="font-weight:bold;border: 1px solid #e1e1e1;height:30px;padding-left:3px;padding-right:3px;">Problem_Request</th>
									<th style="font-weight:bold;border: 1px solid #e1e1e1;height:30px;padding-left:3px;padding-right:3px;">Delays</th>
									<th style="font-weight:bold;border: 1px solid #e1e1e1;height:30px;padding-left:3px;padding-right:3px;">Status</th>
								</tr>'

		select @mail_body = @mail_body + N'
								<tr style="text-align: center;margin-top:3px;margin-bottom:3px;color:'+ case when [priority]= 1 then 'red' else '#333333'end +N';font-family:Leelawadee;font-size:12px;">				
									<td style="border: 1px solid #e1e1e1;padding-left:3px;padding-right:3px;">' + [order_no] + N'</td>				
									<td style="border: 1px solid #e1e1e1;padding-left:3px;padding-right:3px;">' + [category] + N'</td>						
									<td style="border: 1px solid #e1e1e1;padding-left:3px;padding-right:3px;">' + [application] + N'</td>		
									<td style="border: 1px solid #e1e1e1;padding-left:3px;padding-right:3px;">' + [problem_request] + N'</td>	
									<td style="border: 1px solid #e1e1e1;padding-left:3px;padding-right:3px;">' + [delay_d] + N'</td>					
									<td style="border: 1px solid #e1e1e1;padding-left:3px;padding-right:3px;"><a href="' + @URL + [order_no] + N'&page=Management" target="_blank">' + [status] + N'<a/></td>					
								</tr>'											
		from @tempData
	
		set @mail_body = @mail_body + N'
							</table>
						</td>
					</tr>
					<tr style="padding: 0px 20px 20px 20px; font-size:14px;">
						<p>
							Comment: No handler.
						</p>
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
			print 'send mail';
		END
		--print 'emp_mail: ' + @emp_mail;
		DELETE FROM @tempData
	    -- เพิ่มตัวนับ
	    SET @CurrentRow = @CurrentRow + 1;
	
	END;

END
