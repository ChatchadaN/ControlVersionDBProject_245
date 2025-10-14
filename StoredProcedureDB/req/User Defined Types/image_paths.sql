CREATE TYPE [req].[image_paths] AS TABLE (
    [id]          INT            NOT NULL,
    [images_file] NVARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC));

