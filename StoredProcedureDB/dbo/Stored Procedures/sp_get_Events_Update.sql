-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_Events_Update]
	-- Add the parameters for the stored procedure here
		@subject nvarchar(30),
		@roomname nvarchar(10),
		@datestart date,
		@start time(0),
		@end time(0),
		@idroom int,
		@ID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @dbdate date , @countstart int , @countend int , @countstart1 int , @countend1 int

	SET @dbdate = (select  top 1  Date from dbx.dbo.RoomServ where @datestart = Date and @idroom = roomid)

	set @countstart = (select  count(*) from dbx.dbo.RoomServ where @ID <> id and @datestart = Date and @idroom = roomid and DATEADD(MINUTE, +1, CAST(@start as time)) between TimeStart  and TimeEnd)
	set @countstart1 = (select  count(*) from dbx.dbo.RoomServ where @ID <> id and @datestart = Date and @idroom = roomid and TimeStart  between  DATEADD(MINUTE, +1, CAST(@start as time)) and DATEADD(MINUTE, -1, CAST(@end  as time)))
	
	set @countend = (select  count(*) from dbx.dbo.RoomServ where @ID <> id and @datestart = Date and @idroom = roomid and DATEADD(MINUTE, -1, CAST(@end as time)) between TimeStart  and TimeEnd)
	set @countend1 = (select  count(*) from dbx.dbo.RoomServ where @ID <> id and @datestart = Date and @idroom = roomid and TimeEnd  between  DATEADD(MINUTE, +1, CAST(@start as time)) and DATEADD(MINUTE, -1, CAST(@end  as time)))
	
	SET NOCOUNT ON;
	
    if(@roomname = 'G-1' )
	begin
	if (@datestart = @dbdate)
		begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
		end
	else 
	begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
	end
	end
	else if(@roomname = 'G-2' )
	begin
	if (@datestart = @dbdate)
		begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
		end
	else 
	begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
	end
	end
	else if(@roomname = 'G-3' )
	begin
	if (@datestart = @dbdate)
		begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
		end
	else 
	begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
	end
	end
	else if(@roomname = '2-1' )
	begin
	if (@datestart = @dbdate)
		begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
		end
	else 
	begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
	end
	end
	else if(@roomname = '3-1' )
	begin
	if (@datestart = @dbdate)
		begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
		end
	else 
	begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
	end
	end
	else if(@roomname = '3-2' )
	begin
	if (@datestart = @dbdate)
		begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
		end
	else 
	begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0) 
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
	end
	end
	-- INTERPRETER
	else if(@roomname = 'TAI-SAN' )
	begin
	if (@datestart = @dbdate)
		begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
		end
	else 
	begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
	end
	end

	else if(@roomname = 'PAER-JANG' )
	begin
	if (@datestart = @dbdate)
		begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
		end
	else 
	begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
	end
	end
	else if(@roomname = 'LITA-JANG' )
	begin
	if (@datestart = @dbdate)
		begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
		end
	else 
	begin
			if(@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				UPDATE dbx.[dbo].[RoomServ]
						   SET [Room] = @roomname
							  ,[Date] = @datestart
							  ,[TimeStart] = @start
							  ,[TimeEnd] = @end
							  ,[title] = @subject
							  ,[roomid] = @idroom
							  ,[Detail] = GETDATE()
						 WHERE id = @ID 
						 select  'true'  as status
			end
			else 
				begin
					select 'false' as status
				end
	end
	end
	else
	begin
		select 'false' as status
	end
	
	delete from dbx.dbo.RoomServ
	where Date < cast(getdate()-7 as date)

	--[dbo].[sp_get_Events]

end
