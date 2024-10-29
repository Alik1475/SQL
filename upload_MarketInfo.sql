



-- exec QORT_ARM_SUPPORT_TEST.dbo.upload_MarketInfo





CREATE PROCEDURE [dbo].[upload_MarketInfo]

AS

BEGIN

    BEGIN TRY

        DECLARE @WaitCount INT;

        DECLARE @Message VARCHAR(1024);

        DECLARE @todayDate DATE = GETDATE();

        DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT);

        DECLARE @n INT = 0;

        DECLARE @ytdDate DATE;

        

        -- Определяем вчерашний рабочий день

        WHILE dbo.fIsBusinessDay(DATEADD(DAY, -1-@n, GETDATE())) = 0 

        BEGIN    

            SET @n = @n + 1;

        END

        SET @ytdDate = (DATEADD(DAY, -1-@n, GETDATE())); -- определили вчерашний бизнес день

        DECLARE @ytdDateint INT = CAST(CONVERT(VARCHAR, @ytdDate, 112) AS INT);

        declare @ytdDatevarch varchar(32) = CONVERT(VARCHAR, @ytdDate, 112);

        -- Создаем временные таблицы

        IF OBJECT_ID('tempdb..##ParsedResults', 'U') IS NOT NULL DROP TABLE ##ParsedResults;

        IF OBJECT_ID('tempdb..##CodeAssets', 'U') IS NOT NULL DROP TABLE ##CodeAssets;

        

        DECLARE @CodeAssets TABLE (

            ASSID INT, 

            Asset_ShortName VARCHAR(48), 

            Code NVARCHAR(50)

        );



        EXEC QORT_ARM_SUPPORT_TEST.dbo.DRAFT;

        INSERT INTO @CodeAssets (ASSID, Asset_ShortName, Code)

        SELECT * FROM ##CodeAssets;



        -- Создаем временную таблицу для хранения данных

        CREATE TABLE #t (

            IsProcessed INT,

            Code NVARCHAR(50),

            Asset_ShortName VARCHAR(48),

            ASSID INT,

            IsProcent CHAR(1),

            LastPrice FLOAT,

            OldDate INT,

            TSSection_Name VARCHAR(64),

            PriceAsset_ShortName VARCHAR(48)

        );



        INSERT INTO #t (IsProcessed, Code, Asset_ShortName, ASSID, IsProcent, LastPrice, OldDate, TSSection_Name, PriceAsset_ShortName)

        SELECT 

            ROW_NUMBER() OVER (ORDER BY Cass.Code) AS IsProcessed,

            Cass.Code,

            Cass.Asset_ShortName,

            Cass.ASSID,

            CASE WHEN RIGHT(Cass.Code, 4) = 'CORP' THEN 'y' ELSE 'n' END AS IsProcent,

            0 AS LastPrice,

            @ytdDateint AS OldDate,

            'OTC_SECURITIES' AS TSSection_Name,

            CASE WHEN RIGHT(Cass.Code, 4) = 'CORP' THEN NULL ELSE 'USD' END AS PriceAsset_ShortName

        FROM @CodeAssets Cass;



        DECLARE @MaxIsProcessed INT;

        DECLARE @CurrentIsProcessed INT = 1;

        SELECT @MaxIsProcessed = MAX(IsProcessed) FROM #t;



        WHILE @CurrentIsProcessed <= @MaxIsProcessed

        BEGIN

            DECLARE @CurrentCode NVARCHAR(50);

            SELECT @CurrentCode = Code FROM #t WHERE IsProcessed = @CurrentIsProcessed;



            -- Вызов процедуры GetFlaskData для текущего Code

            EXEC QORT_ARM_SUPPORT_TEST.dbo.GetFlaskData

                @IsinCodes = @CurrentCode,

                @StartDate = @ytdDatevarch,

                @EndDate = @ytdDatevarch;



            -- Обновление значения LastPrice в таблице #t

            UPDATE #t

            SET LastPrice = ISNULL(

                (SELECT TOP 1 Px_Last FROM ##ParsedResults), 

                0)

            WHERE Code = @CurrentCode;



            SET @CurrentIsProcessed = @CurrentIsProcessed + 1;

        END;



        -- Вывод обновленной таблицы

        SELECT * FROM #t;





		  INSERT INTO QORT_BACK_TDB_UAT..ImportMarketInfo (
            OldDate
          , TSSection_Name
          , Asset_ShortName
          , LastPrice
          , IsProcessed
          , isprocent
          , PriceAsset_ShortName
        )

		select 

		@ytdDateint as OldDate

		, 'OTC_Securities' as TSSection_Name

		, t.Asset_ShortName Asset_ShortName

		, t.LastPrice as LastPrice

		, 1 as IsProcessed

		, t.IsProcent as IsProcent

		, t.PriceAsset_ShortName as PriceAsset_ShortName



		from #t t





    END TRY

    BEGIN CATCH

        -- Обработка ошибок

        SET @Message = 'ERROR: ' + ERROR_MESSAGE();  

        IF @message NOT LIKE '%12345 Cannot initialize the data source%' 

            INSERT INTO QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) VALUES (@message, 1001);

        PRINT @Message;

    END CATCH

END;

