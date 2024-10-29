﻿

 

-- exec QORT_ARM_SUPPORT.dbo.upload_MarketInfo @ip = '192.168.13.59',	@IsinCode = 'XS2080321198 CORP'





CREATE PROCEDURE [dbo].[upload_MarketInfo]

@IP varchar(16),

@IsinCode NVARCHAR(MAX)



AS

BEGIN

    BEGIN TRY

        DECLARE @WaitCount INT;

        DECLARE @Message VARCHAR(1024);

        DECLARE @todayDate DATE = GETDATE() -- DATEADD(DAY, -1, GETDATE())--;

        DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT);

        DECLARE @n INT = 0;

        DECLARE @ytdDate DATE;

        

        -- Определяем вчерашний рабочий день

        WHILE dbo.fIsBusinessDay(DATEADD(DAY, -1-@n, @todayDate)) = 0 

        BEGIN    

            SET @n = @n + 1;

        END

        SET @ytdDate = (DATEADD(DAY, -1-@n, @todayDate)) -- определили вчерашний бизнес день

        DECLARE @ytdDateint INT = CAST(CONVERT(VARCHAR, @ytdDate, 112) AS INT);

        declare @ytdDatevarch varchar(32) = CONVERT(VARCHAR, @ytdDate, 112);

		PRINT @ytdDatevarch

        -- Создаем временные таблицы

        IF OBJECT_ID('tempdb..##ParsedResults', 'U') IS NOT NULL DROP TABLE ##ParsedResults;

        IF OBJECT_ID('tempdb..##CodeAssets', 'U') IS NOT NULL DROP TABLE ##CodeAssets;

        

        DECLARE @CodeAssets TABLE (

            ASSID INT, 

            Asset_ShortName VARCHAR(48), 

            Code NVARCHAR(50)

        );

		    -- Заполнение таблицы #Curloutput данными
		 if (@IsinCode is null) 
   begin



        EXEC QORT_ARM_SUPPORT.dbo.CodeAssets;

        INSERT INTO @CodeAssets (ASSID, Asset_ShortName, Code)

        SELECT ca1.assid, ca1.ShortName, ca1.code FROM ##CodeAssets ca1

		OUTER APPLY(
			SELECT top 1 PR.Value FROM QORT_BACK_DB.dbo.Assets ass1-- WHERE LEFT(CA1.CODE,12) = ass1.ISIN

			LEFT OUTER JOIN QORT_BACK_DB.dbo.AssetProperties PR ON PR.Asset_ID = ass1.ID

			WHERE PR.AssetOption_ID = 2 AND LEFT(ca1.code ,12) = ass1.ISIN) pr1

		where NOT EXISTS (
		 select 1 
			from QORT_BACK_DB.dbo.MarketInfoHist m
			left outer join QORT_BACK_DB.dbo.Assets ass on ass.id = m.Asset_ID
			
		 where ass.ISIN = left(ca1.code,12) and olddate = @ytdDateint and (isnull(LastPrice,0) <> 0 OR isnull(M
arketPrice,0) <> 0) --OR ISNULL(pr1.Value, 0) = 1
)

and ISNULL(pr1.Value, 0) <> 1



		--and ca1.CODE = 'XS1392917784 CORP'

			end
	else 
	begin
	
	INSERT INTO @CodeAssets (ASSID, Asset_ShortName, Code)

        
	VALUES (0, (select top 1 shortname from QORT_BACK_DB.dbo.Assets where ISIN = LEFT(@IsinCode,12)), @IsinCode)
	end


		SELECT * FROM @CodeAssets --return

        -- Создаем временную таблицу для хранения данных

        CREATE TABLE #t (

            IsProcessed INT,

            Code NVARCHAR(50),

            Asset_ShortName VARCHAR(48),

            ASSID INT,

            IsProcent CHAR(1),

            LastPrice FLOAT,

			MarketPrice FLOAT,

			MarketPrice2 FLOAT,

            OldDate INT,

            TSSection_Name VARCHAR(64),

            PriceAsset_ShortName VARCHAR(48)

			--, Accruedint float

			--, DS027 int

        );



        INSERT INTO #t (IsProcessed, Code, Asset_ShortName, ASSID, IsProcent, LastPrice, MarketPrice, MarketPrice2, OldDate, TSSection_Name, PriceAsset_ShortName /*,Accruedint, DS027*/)

        SELECT 

            ROW_NUMBER() OVER (ORDER BY Cass.Code) AS IsProcessed,

            Cass.Code,

            Cass.Asset_ShortName,

            Cass.ASSID,

            CASE WHEN RIGHT(Cass.Code, 4) = 'CORP' THEN 'y' ELSE 'n' END AS IsProcent,

            0 AS LastPrice,

			0 AS MarketPrice,

			0 AS MarketPrice2,

            @ytdDateint AS OldDate,

            'OTC_SECURITIES' AS TSSection_Name,

            CASE

				WHEN RIGHT(Cass.Code, 4) = 'CORP' 

					THEN NULL 

				ELSE ass.ShortName END AS PriceAsset_ShortName

			--, 0 as Accruedint 

			--, 0 as DS027

        FROM @CodeAssets Cass

		left outer join QORT_BACK_DB.dbo.Securities sec on sec.Asset_ID = Cass.ASSID and sec.TSSection_ID in (154, (-1)) --'OTC_Securities'

		left outer join QORT_BACK_DB.dbo.Assets ass on ass.id = sec.CurrPriceAsset_ID

		--select * from #t return

        DECLARE @MaxIsProcessed INT;

        DECLARE @CurrentIsProcessed INT = 1;

        SELECT @MaxIsProcessed = MAX(IsProcessed) FROM #t;



        WHILE @CurrentIsProcessed <= @MaxIsProcessed

        BEGIN

            DECLARE @CurrentCode NVARCHAR(50);

            SELECT @CurrentCode = Code FROM #t WHERE IsProcessed = @CurrentIsProcessed;



            -- Вызов процедуры GetFlaskData для текущего Code

            EXEC QORT_ARM_SUPPORT.dbo.GetFlaskData @IP,

                @IsinCodes = @CurrentCode,

                @StartDate = @ytdDatevarch,

                @EndDate = @ytdDatevarch;





			IF OBJECT_ID('tempdb..##ParsedResultsBDP', 'U') IS NOT NULL DROP TABLE ##ParsedResultsBDP;



            -- Обновление значения LastPrice в таблице #t

			UPDATE #t
			SET 
				LastPrice = CASE 
					WHEN ISNULL((SELECT TOP 1 Px_Last FROM ##ParsedResults), 0) <> 0 
						THEN ISNULL((SELECT TOP 1 Px_Last FROM ##ParsedResults), 0)
					WHEN ISNULL(CAST((SELECT TOP 1 PX_CLOSE_1D FROM QORT_ARM_SUPPORT.dbo.B
loombergData 
									 WHERE CODE = @CurrentCode AND Date = @todayInt) AS FLOAT), 0) <> 0 
						THEN ISNULL(CAST((SELECT TOP 1 PX_CLOSE_1D FROM QORT_ARM_SUPPORT.dbo.BloombergData 
										 WHERE CODE = @CurrentCode AND Date = @todayInt) AS FLOAT), 0)

					ELSE 0					
				END
    /*
				,Accruedint = CAST((SELECT TOP 1 Int_Acc FROM QORT_ARM_SUPPORT.dbo.BloombergData 
								  WHERE CODE = @CurrentCode AND Date = @todayInt) AS FLOAT),
				DS027 = CAST((SELECT TOP 1 BB_COMPOSITE FROM QORT_ARM_SUPPORT.db
o.BloombergData 
								  WHERE CODE = @CurrentCode AND Date = @todayInt) AS int)
    */
			WHERE Code = @CurrentCode;



			-- ЕСЛИ НЕ НАШЛИ, ТО ЗАПУСКАЕМ  BDP ПО BVAL AND BMRK

			--/*		

			IF ((ISNULL(

                (SELECT TOP 1 LastPrice FROM #t where Code = @CurrentCode), 

                0) = 0) AND (RIGHT(@CurrentCode,4) = 'CORP'))

			BEGIN

			exec QORT_ARM_SUPPORT.dbo.BDP_Request @IP,

				@IsinCodes = @CurrentCode,
				@Field1 = 'PX_LAST',
				@Field2 = 'PX_CLOSE_1D',
				@Field3 = 'PX_DISC_MID',

				@Field4 = 'MATURITY'



			    UPDATE #t
				SET LastPrice = CASE 
					WHEN OBJECT_ID('tempdb..##ParsedResultsBDP', 'U') IS NOT NULL 
						THEN CASE 
							WHEN ISNULL(CAST((SELECT TOP 1 FIELD2 FROM ##ParsedResultsBDP WHERE RIGHT(CODE,10) = '@BVAL CORP') AS FLOAT), 0) <> 0 
	
							 THEN ISNULL(CAST((SELECT TOP 1 FIELD2 FROM ##ParsedResultsBDP WHERE RIGHT(CODE,10) = '@BVAL CORP') AS FLOAT), 0)
							WHEN ISNULL(CAST((SELECT TOP 1 FIELD2 FROM ##ParsedResultsBDP WHERE RIGHT(CODE,10) = '@BMRK CORP') AS FLOAT), 0) <> 0 
								
 THEN ISNULL(CAST((SELECT TOP 1 FIELD2 FROM ##ParsedResultsBDP WHERE RIGHT(CODE,10) = '@BMRK CORP') AS FLOAT), 0)
							ELSE  0
							 END
					 ELSE 0
					END
				WHERE Code = @CurrentCode;

				

			    UPDATE #t
				SET MarketPrice =  ISNULL(CAST((SELECT TOP 1 FIELD1 FROM ##ParsedResultsBDP) AS FLOAT), 0)
				WHERE Code = @CurrentCode;

				 UPDATE #t
				SET MarketPrice2 =  ISNULL(CAST((SELECT TOP 1 FIELD3 FROM ##ParsedResultsBDP) AS FLOAT), 0)
				WHERE Code = @CurrentCode;



			END

	



			--*/





            SET @CurrentIsProcessed = @CurrentIsProcessed + 1;

        END;



        -- Вывод обновленной таблицы

        SELECT * FROM #t;--return



		--/*

		  INSERT INTO QORT_BACK_TDB..ImportMarketInfo (
            OldDate
          , TSSection_Name
          , Asset_ShortName
          , LastPrice
		  , MarketPrice
		  , MarketPrice2
          , IsProcessed
          , isprocent
          , PriceAsset_Sh
ortName
		--  , Accruedint
        )

		--*/

		select 

		@ytdDateint as OldDate

		, 'OTC_Securities' as TSSection_Name

		, t.Asset_ShortName Asset_ShortName

		, t.LastPrice as LastPrice

		, t.MarketPrice as MarketPrice

		, t.MarketPrice2 as MarketPrice2

		, 1 as IsProcessed

		, t.IsProcent as IsProcent

		, t.PriceAsset_ShortName as PriceAsset_ShortName

	--	, t.Accruedint as Accruedint



		from #t t

--/* ---------------------------Блок вставки значений ACI для расчета купонов----------------------

		   INSERT INTO QORT_BACK_TDB..AccruedInt (
		   IsProcessed,
           Date,
		   Asset_ShortName,
		   Volume
        )

		--*/

		select 1 as IsProcessed,

		BLP.DS027 as Date	

		, ass.ShortName Asset_ShortName

		 , (isnull(BLP.Int_Acc,0) * ass.BaseValue / 100) as Accruedint

		-- , ass.ShortName

		 --, t.BB_COMPOSITE

		FROM QORT_ARM_SUPPORT.dbo.BloombergData BLP

		left outer join QORT_BACK_DB.dbo.Assets ass on ass.ISIN = left(BLP.Code,12)

		where BLP.security_Name is not null  AND RIGHT(BLP.Code,4) = 'CORP' AND isnull(BLP.Int_Acc,0) <> 0

		and BLP.date = @todayInt

		--and ass.ShortName = 'SQBNZU 5.75 12/02/24'

		and NOT EXISTS (
		 select 1 
			from QORT_BACK_TDB..AccruedInt accr
		 where BLP.DS027 = accr.Date and ass.ShortName = accr.Asset_ShortName --and isnull(LastPrice,0) <> 0
)



--*/----------------------------------загрузка последней цены сделки--------------------------------




declare @ytdDateintS int = 20200000
SET @ytdDateintS = @ytdDateintS + (@ytdDateint % 100000) - RIGHT(@ytdDateint,2) + 1 -- формируем дату первого дня месяца
--print @ytdDateintS
set @n = @ytdDateint

while @n >= @ytdDateintS

	

	begin

	--/*

		  INSERT INTO QORT_BACK_TDB..ImportMarketInfo (
            OldDate
          , TSSection_Name
          , Asset_ShortName
          , SettlePrice
          , IsProcessed
          , isprocent
          , PriceAsset_ShortName
	
        )

		--*/





    select 
        @n as OldDate
      , 'OTC_SWAP' as TSSection_Name
      , CTE.Asset_ShortName
      , CTE.SettlePrice
      , 1 as IsProcessed
      , 'n' as IsProcent
      , CTE.PriceAsset_ShortName
    from (
        select 
            ass.Shor
tName as Asset_ShortName
          , trad.Price as SettlePrice
          , ass1.ShortName as PriceAsset_ShortName
		  , ass.id assID
          , ROW_NUMBER() OVER (PARTITION BY ass.ShortName ORDER BY trad.TradeDate DESC) as RowNum
        from QORT_BACK_D
B..Trades trad 
        left outer join QORT_BACK_DB..Securities sec on sec.id = trad.Security_ID
        left outer join QORT_BACK_DB..Assets ass on ass.id = sec.Asset_ID
        left outer join QORT_BACK_DB..Assets ass1 on ass1.id = trad.CurrPriceAsset_
ID
        where ass.AssetClass_Const in (5,8,11,18) 
        and trad.TradeDate < @n
		AND Trad.VT_Const NOT IN (12, 10) -- сделка не расторгнута

          AND trad.NullStatus = 'n'

          AND trad.Enabled = 0

          AND trad.IsDraft = 'n'

          AND trad.IsProcessed = 'y'
    ) CTE
    where CTE.RowNum = 1
	and NOT EXISTS (

				select TOP 1 a.SettlePrice

				from QORT_BACK_DB.dbo.MarketInfoHist a

				where a.Asset_ID = CTE.assID and a.OldDate = @n

				and a.TSSection_ID = 165 -- OTC_SWAP

			)
    set @n = @n - 1
end



    END TRY

    BEGIN CATCH

        -- Обработка ошибок

        SET @Message = 'ERROR: ' + ERROR_MESSAGE();  

        IF @message NOT LIKE '%12345 Cannot initialize the data source%' 

            INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@message, 1001);

        PRINT @Message;

    END CATCH

END;
