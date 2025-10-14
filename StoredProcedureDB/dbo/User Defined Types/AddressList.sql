CREATE TYPE [dbo].[AddressList] AS TABLE (
    [id]      INT         NOT NULL,
    [x]       CHAR (1)    NULL,
    [y]       VARCHAR (2) NULL,
    [z]       VARCHAR (2) NULL,
    [wh_code] INT         NULL);

