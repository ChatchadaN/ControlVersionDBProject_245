CREATE TABLE [dbo].[exec_sp_history] (
    [history_id]   INT            IDENTITY (1, 1) NOT NULL,
    [record_at]    DATETIME       NULL,
    [record_class] INT            NULL,
    [login_name]   NVARCHAR (50)  NULL,
    [hostname]     NVARCHAR (50)  NULL,
    [appname]      NVARCHAR (128) NULL,
    [command_text] NVARCHAR (MAX) NULL,
    [lot_no]       CHAR (20)      NULL,
    CONSTRAINT [PK_exec_sp_history] PRIMARY KEY CLUSTERED ([history_id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_exec_lot_no]
    ON [dbo].[exec_sp_history]([lot_no] ASC);

