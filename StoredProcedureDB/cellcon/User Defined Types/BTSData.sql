CREATE TYPE [cellcon].[BTSData] AS TABLE (
    [MCNo]            VARCHAR (30)  NOT NULL,
    [LotNo]           VARCHAR (20)  NOT NULL,
    [StartUser]       VARCHAR (6)   NULL,
    [StartTime]       DATETIME      NULL,
    [EndUser]         VARCHAR (6)   NULL,
    [EndTime]         DATETIME      NULL,
    [Input]           INT           NULL,
    [InputAdjust]     INT           NULL,
    [Good]            INT           NULL,
    [GoodAdjust]      INT           NULL,
    [NG]              INT           NULL,
    [NGAdjust]        INT           NULL,
    [PretestNG]       INT           NULL,
    [PretestNGAdjust] INT           NULL,
    [BurnInNG]        INT           NULL,
    [BurnInNGAdjust]  INT           NULL,
    [Remark]          VARCHAR (100) NULL);

