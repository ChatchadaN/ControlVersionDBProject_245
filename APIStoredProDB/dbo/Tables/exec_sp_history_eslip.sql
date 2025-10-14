CREATE TABLE [dbo].[exec_sp_history_eslip] (
    [history_id]    INT            IDENTITY (1, 1) NOT NULL,
    [record_at]     DATETIME       NULL,
    [record_class]  INT            NULL,
    [login_name]    NVARCHAR (50)  NULL,
    [hostname]      NVARCHAR (50)  NULL,
    [clientname]    NVARCHAR (100) NULL,
    [appname]       NVARCHAR (128) NULL,
    [lot_no]        NVARCHAR (50)  NULL,
    [e_slip_id]     NVARCHAR (50)  NULL,
    [medthod_type]  NVARCHAR (50)  NULL,
    [function_name] NVARCHAR (50)  NULL,
    [link_name]     NVARCHAR (MAX) NULL,
    [command_text]  NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_exec_sp_history_eslip] PRIMARY KEY CLUSTERED ([history_id] ASC)
);

