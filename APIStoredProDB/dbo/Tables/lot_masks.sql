CREATE TABLE [dbo].[lot_masks] (
    [lot_no]     VARCHAR (10)  NOT NULL,
    [mno]        VARCHAR (MAX) NULL,
    [comment]    VARCHAR (200) NULL,
    [date_stamp] DATETIME      NULL,
    CONSTRAINT [PK_master_data_mask] PRIMARY KEY CLUSTERED ([lot_no] ASC)
);

