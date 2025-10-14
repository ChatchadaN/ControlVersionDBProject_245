
-- =============================================

-- Author:              <Author,,Name>

-- Create date: <Create Date,,>

-- Description: <Description,,>

-- =============================================

CREATE PROCEDURE[stripmap].[GET_USER_MAP_EDIT_LICENSE]

        -- Add the parameters for the stored procedure here

        @USER_ID INT

 

AS

BEGIN

        -- SET NOCOUNT ON added to prevent extra result sets from

        -- interfering with SELECT statements.

        SET NOCOUNT ON;

 

    -- Insert statements for procedure here

        select DISTINCT

                OP.name as EDITOR,

                US.is_admin as ADMIN

        from APCSProDB.man.users as US with(nolock)

        left outer join APCSProDB.man.user_roles as UR with(nolock) on UR.user_id = US.id

        left outer join APCSProDB.man.role_permissions as RP with(nolock) on RP.role_id = UR.role_id

        left outer join APCSProDB.man.permission_operations as PO with(nolock) on PO.permission_id = RP.permission_id

        left outer join APCSProDB.man.operations as OP with(nolock) on OP.id = PO.operation_id and OP.name = 'MapEditor'

        where US.id = @USER_ID

        

        return @@ROWCOUNT

END
