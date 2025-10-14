CREATE TYPE [dbo].[TG_List] AS TABLE (
    [lot_no] VARCHAR (10) NOT NULL,
    [qty]    INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([lot_no] ASC));

