-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_Events]
	-- Add the parameters for the stored procedure here
		@subject nvarchar(30),
		@roomname nvarchar(10),
		@userid nvarchar(10),
		@tel nvarchar(10),
		@datestart date,
		@start time(0),
		@end time(0),
		@idroom int
		
		--@pMessage VARCHAR(5) OUTPUT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @var INT,@MinutesToAdd INT = 1,@maxid  INT  = 0,@maxnew  INT  = 0  ,@datecheck int ,@countstart int ,@countend int,@idcount int , @countstart1 int , @countend1 int
	
    -- Insert statements for procedure here
	SELECT @maxid = (SELECT top 1 max(id) as id from dbx.dbo.RoomServ)
	SET @datecheck = (SELECT count(*) From dbx.dbo.RoomServ	WHERE @datestart = Date AND @idroom = roomid)
	
	
	set @countstart = (select  count(*) from dbx.dbo.RoomServ where @datestart  = Date and @idroom = roomid and TimeStart  between DATEADD(MINUTE, +1, CAST(@start as time)) and DATEADD(MINUTE, -1, CAST(@end  as time)))
	set @countstart1 = (select  count(*) from dbx.dbo.RoomServ where @datestart = Date and @idroom = roomid and DATEADD(MINUTE, +1, CAST(@start as time))  between TimeStart  and TimeEnd)

	
	set @countend = (select  count(*) from dbx.dbo.RoomServ where @datestart  = Date and @idroom = roomid and TimeEnd  between  DATEADD(MINUTE, +1, CAST(@start as time)) and DATEADD(MINUTE, -1, CAST(@end  as time)))
	set @countend1 = (select  count(*) from dbx.dbo.RoomServ where @datestart = Date and @idroom = roomid and DATEADD(MINUTE, +1, CAST(@start as time))  between TimeStart  and TimeEnd)

	set @idcount = (select count(*) from [APCSProDB].[man].[users] where emp_num like @userid)

	if (@idcount = 1)
	begin
	if(@roomname = 'G-1')
	begin
		if (@datecheck <> 0)
		begin
			if (@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
			end
		end
		else
		begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
		end
	end
	else if(@roomname = 'G-2' )
	begin
		if (@datecheck <> 0)
		begin
			if (@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
			end
		end
		else
		begin
			INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
		end
	end
		else if(@roomname = 'G-3' )
	begin
		if (@datecheck <> 0)
		begin
			if (@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
			end
		end
		else
		begin
			INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
		end
	end
	else if(@roomname ='2-1')
	begin
		if (@datecheck <> 0)
		begin
			if (@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
			end
		end
		else
		begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
		end
	end
	else if(@roomname = '3-1')
	begin
		if (@datecheck <> 0)
		begin
			if (@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
			end
		end
		else
		begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
		end
	end
	else if(@roomname = '3-2' )
	begin
		if (@datecheck <> 0)
		begin
			if (@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
			end
		end
		else
		begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
		end
	end
	-- INTERPERTER
	else if(@roomname ='TAI-SAN' )
	begin
		if (@datecheck <> 0)
		begin
			if (@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
			end
		end
		else
		begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
		end
	end

	else if(@roomname = 'PAER-JANG' )
	begin
		if (@datecheck <> 0)
		begin
			if (@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
			end
		end
		else
		begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
		end
	end

	else if(@roomname = 'LITA-JANG' )
	begin
		if (@datecheck <> 0)
		begin
			if (@countstart = 0 and @countend = 0 and @countstart1 = 0 and @countend1 = 0)
			begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
			end
		end
		else
		begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
		end
	end

	else 
	begin
				INSERT INTO dbx.dbo.RoomServ ([Room],[Date],[TimeStart],[TimeEnd],[user_id],[title],[Detail],[tel],[roomid])
						VALUES (@roomname,@datestart,@start,@end,@userid,@subject,GETDATE(),@tel,@idroom);
				SELECT @maxnew = (SELECT max(id) as id from dbx.dbo.RoomServ)
	end

	end


	if(@maxid < @maxnew)
	begin
		select  'true'  as status --,@idcount
	end
	else
	begin
		select  'false' as status
	end
	

	--EXEC [dbo].[sp_get_Events_Update]


END

