
-- exec QORT_ARM_SUPPORT.dbo.ChangeCurrent

CREATE PROCEDURE [dbo].[ChangeCurrent]
    @taskName VARCHAR(32) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Объявление переменных
        SET @taskName = NULLIF(@taskName, '');
        DECLAR
E @todayDate DATE = GETDATE();
        DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT);
        DECLARE @Message VARCHAR(1024);
        DECLARE @rows INT;
        DECLARE @aid INT = 0;
        DECLARE @WaitCount INT;
        DECLARE
 @CurOrder TABLE (Currency VARCHAR(8), OrderBy INT);
        DECLARE @Trades TABLE (rnum INT, n INT, SubAcc_Code VARCHAR(32), Security_Code VARCHAR(64), Qty FLOAT, CurrPriceAsset_ShortName VARCHAR(48), Volume1 FLOAT, Price FLOAT);
        DECLARE @TradesW
ithRowNum TABLE (rnum INT, n INT, SubAcc_Code VARCHAR(32), Security_Code VARCHAR(64), Qty FLOAT, CurrPriceAsset_ShortName VARCHAR(48), Volume1 FLOAT, Price FLOAT);
        DECLARE @Position TABLE (SubAcc_Code VARCHAR(32), Security_Code VARCHAR(64), Qty FL
OAT, Frozen BIT);
        DECLARE @CurencyTrade VARCHAR(8);
        DECLARE @CurencyComm VARCHAR(8);
        DECLARE @VolumeComm FLOAT;
        DECLARE @n INT = 0;
        DECLARE @n1 INT = 0;
        DECLARE @n3 INT = 0;

        -- Удаляем временную таб
лицу, если она существует
        IF OBJECT_ID('tempdb..#t', 'U') IS NOT NULL DROP TABLE #t;

        -- ФОРМИРУЕМ ТАБЛИЦУ С НАЧИСЛЕННЫМИ КОМИССИЯМИ
        SELECT ROW_NUMBER() OVER (ORDER BY bc.Trade_ID) rn
             , bc.Subacc_ID Subacc_ID
         
    , sub.SubAccCode SubAccCode
             , bc.Asset_ID Asset_ID
             , AssC.Name CurrencyComm
             , bc.balance sumBalance
             , bc.Account_ID 
             , bc.Trade_ID
             , Tr.CurrPayAsset_ID
             , CASE
 
                  WHEN AssC.AssetClass_Const IN (6, 7, 9, 18) THEN secu.Name
                   ELSE AssT.Name
               END AS CurrencyTrade
        INTO #t
        FROM QORT_BACK_DB..BlockCommissionOnTrades bc
        LEFT OUTER JOIN QORT_BACK_DB..
Trades Tr ON Tr.id = bc.Trade_ID
        LEFT OUTER JOIN QORT_BACK_DB..Assets AssC ON AssC.id = bc.Asset_ID
        LEFT OUTER JOIN QORT_BACK_DB..Assets AssT ON AssT.id = Tr.CurrPayAsset_ID
        LEFT OUTER JOIN QORT_BACK_DB..Securities secu ON secu.id 
= Tr.Security_ID
        LEFT OUTER JOIN QORT_BACK_DB..Assets AssN ON AssN.id = secu.Asset_ID
        LEFT OUTER JOIN QORT_BACK_DB..Subaccs sub WITH (NOLOCK) ON sub.id = bc.Subacc_ID
        WHERE bc.Enabled <> bc.id
          AND bc.Balance > 0;

       
 SELECT * FROM #t;

        -- Посделочно формируем данные для сделок конвертации
        SET @n = (SELECT MAX(rn) FROM #t);
        
        -- НАЧАЛО ЦИКЛА ПОСДЕЛОЧНОГО ФОРМИРОВАНИЯ СДЕЛОК КОНВЕРТАЦИИ
        WHILE @n > 0
        BEGIN
            IF OB
JECT_ID('tempdb..#t1', 'U') IS NOT NULL DROP TABLE #t1;
            DELETE FROM @CurOrder;
            DELETE FROM @Trades;
            DELETE FROM @TradesWithRowNum;

            SET @CurencyTrade = (SELECT CurrencyTrade FROM #t WHERE rn = @n); -- берем 
одну сделку

            -- Формируем приоритет по валютам, с учетом того, что первая валюта из сделки.
            INSERT INTO @CurOrder (Currency, OrderBy)
            VALUES (@CurencyTrade, 6)
                 , ('USD', 5)
                 , ('EUR', 4)

                 , ('AMD', 3)
                 , ('RUB', 2);

            -- Формируем таблицу с позицией клиента
            SET @VolumeComm = 0; -- сбрасываем счетчик сколько денег получили от конвертаций по сформированным сделкам

            SELECT t
.Subacc_ID
                 , t.SubAccCode SubAccCode
                 , t.Asset_ID CurID_Need
                 , t.sumBalance
                 , IIF(po.frozen IS NOT NULL, 0, ph.VolFree) VolFree
                 , ph.Asset_ID curBalance
                 
, ass.Name CurrencyBal
                 , IIF(ph.Asset_ID = t.Asset_ID, 0, (SELECT TOP 1 OrderBy FROM @CurOrder WHERE Currency = ass.Name COLLATE Cyrillic_General_CS_AS)) OrderBy
                 , po.Frozen
            INTO #t1
            FROM #t t
    
        LEFT OUTER JOIN QORT_BACK_DB..Position ph WITH (NOLOCK) ON ph.Subacc_ID = t.Subacc_ID --and ph.Date = @todayInt
            LEFT OUTER JOIN QORT_BACK_DB..Assets ass WITH (NOLOCK) ON Ass.id = ph.Asset_ID
            LEFT OUTER JOIN @Position po ON 
po.SubAcc_Code = t.SubAccCode COLLATE Cyrillic_General_CS_AS
                                       AND po.Security_Code = ass.Name COLLATE Cyrillic_General_CS_AS
            WHERE ass.AssetType_Const = 3 -- только валюты 
              AND t.rn = @n 
   
           AND ph.Account_ID IN (3) -- только на физ счете ARMBROK_MONEY
              AND ass.Name IN ('AMD', 'USD', 'RUB', 'EUR');

            -- Проверяем, что позицию клиента еще не записывали, и тогда формируем (для заморозки позиций по другим сделк
ам, если сделок несколько)
            IF (SELECT TOP 1 SubAcc_Code FROM @Position WHERE (SELECT TOP 1 SubAccCode FROM #t1) = SubAcc_Code COLLATE Cyrillic_General_CS_AS) IS NULL
            BEGIN
                -- записываем позицию клиента
             
   INSERT INTO @Position (SubAcc_Code, Security_Code, Qty, Frozen)
                SELECT SubAccCode
                     , CurrencyBal
                     , VolFree
                     , NULL AS Frozen
                FROM #t1;
            END

       
     SELECT * FROM #t1;

            -- Формируем вторую расчетную таблицу, апгрейдом первой #t
            IF OBJECT_ID('tempdb..#t2', 'U') IS NOT NULL DROP TABLE #t2;

            SELECT ROW_NUMBER() OVER (ORDER BY t1.OrderBy) rn1
                 , t1.
OrderBy OrderBy
                 , t1.Subacc_ID
                 , t1.SubAccCode
                 , t1.CurID_Need
                 , ass.ShortName CurName_Need
                 , t1.sumBalance - ISNULL((SELECT VolFree FROM #t1 WHERE CurrencyBal = ass.Shor
tName COLLATE Cyrillic_General_CS_AS), 0) sumBalance_need
                 , t1.VolFree
                 , t1.CurrencyBal CurrencyBal_pos
                 , ISNULL(cr2.Bid, 1) bid
            INTO #t2
            FROM #t1 t1
            LEFT OUTER JOIN QO
RT_BACK_DB..CrossRatesHist cr2 WITH (NOLOCK) ON t1.curBalance = cr2.TradeAsset_ID
                                                                         AND cr2.Date = @todayInt
                                                                         AN
D cr2.InfoSource = 'CBA'
            LEFT OUTER JOIN QORT_BACK_DB..Assets ass WITH (NOLOCK) ON t1.CurID_Need = ass.id
            WHERE (t1.sumBalance - ISNULL((SELECT VolFree FROM #t1 WHERE CurrencyBal = ass.ShortName COLLATE Cyrillic_General_CS_AS), 0))
 > 0;

            -- Сохраняем значение той валюты, которую ищем
            SET @CurencyComm = (SELECT CurName_Need FROM #t2 WHERE CurrencyBal_pos = CurName_Need COLLATE Cyrillic_General_CS_AS);

            SELECT * FROM #t2;

            -- Запускаем 
этап формирования сделок конвертаций внутри цикла начисленных комиссий по сделкам
            SET @n1 = (SELECT MAX(rn1) FROM #t2); -- из таблицы находим максимальное порядковое значение и откручиваем по нему вниз.

            WHILE @n1 > 1 -- на последн
ей строчке будет валюта, которой не хватает (OrderBy = 6)
            BEGIN
                IF OBJECT_ID('tempdb..#trades', 'U') IS NOT NULL DROP TABLE #trades;

                -- Формируем таблицу планируемой сделки по первой доступной валюте
          
      SELECT t2.Subacc_ID
                     , t2.SubAccCode
                     , t2.CurID_Need
                     , t2.CurName_Need
                     , (SELECT bid FROM #t2 WHERE CurName_Need = CurrencyBal_pos COLLATE Cyrillic_General_CS_AS) bid
_curneed
                     , ISNULL(t2.sumBalance_need, 0) - @VolumeComm PosNeed
                     , t2.VolFree PosFree
                     , t2.CurrencyBal_pos CurrPosFree
                     , t2.bid bidPosFree
                     , ROUND((t2.s
umBalance_need - @VolumeComm) * (SELECT bid FROM #t2 WHERE CurName_Need = CurrencyBal_pos COLLATE Cyrillic_General_CS_AS) / t2.bid, 2) VolumForTrade
                     , ROUND(t2.VolFree - t2.sumBalance_need * (SELECT bid FROM #t2 WHERE CurName_Need = C
urrencyBal_pos COLLATE Cyrillic_General_CS_AS) / t2.bid, 2) VolFreeNow
                INTO #trades
                FROM #t2 t2
                WHERE rn1 = @n1
                  AND t2.VolFree > 0
                  AND (ISNULL(t2.sumBalance_need, 0) - @Vo
lumeComm) > 0;

                SELECT * FROM #trades;

                IF (SELECT VolFreeNow FROM #trades) >= 0
                BEGIN
                    -- записываем сделки конвертации
                    INSERT INTO @Trades (rnum, n, SubAcc_Code, Secu
rity_Code, Qty, CurrPriceAsset_ShortName, Volume1, Price)
                    SELECT NULL AS rnum
                         , @n1 AS n
                         , SubAccCode
                         , CurrPosFree
                         , IIF(VolFreeNow >=
 0, VolumForTrade, PosFree)
                         , CurName_Need
                         , ROUND(IIF(VolFreeNow >= 0, PosNeed, PosFree / bid_curneed * bidPosFree), 2)
                         , CASE 
                             WHEN CurName_Need = 'A
MD' THEN bidPosFree
                             ELSE ROUND(CASE 
                                         WHEN IIF(VolFreeNow >= 0, VolumForTrade, PosFree) / IIF(VolFreeNow >= 0, PosNeed, PosFree / bid_curneed * bidPosFree) >
                            
                  IIF(VolFreeNow >= 0, PosNeed, PosFree / bid_curneed * bidPosFree) / IIF(VolFreeNow >= 0, VolumForTrade, PosFree)
                                         THEN IIF(VolFreeNow >= 0, VolumForTrade, PosFree) / IIF(VolFreeNow >= 0, PosNeed, P
osFree / bid_curneed * bidPosFree)
                                         ELSE IIF(VolFreeNow >= 0, PosNeed, PosFree / bid_curneed * bidPosFree) / IIF(VolFreeNow >= 0, VolumForTrade, PosFree)
                                       END, 2)
              
             END
                    FROM #trades;

                    SET @n1 = 1; -- конец цикла (завершаем)
                END
                ELSE
                BEGIN
                    IF (SELECT VolFreeNow FROM #trades) <= 0 AND @n1 = 2 -- если
 денег по валютам не хватило, то не формируем сделки, удаляем черновики и сбрасываем переменную валюты комиссии, чтобы не заморозить
                    BEGIN
                        DELETE FROM @Trades WHERE SubAcc_Code = (SELECT TOP 1 SubAccCode FROM #t
1) COLLATE Cyrillic_General_CS_AS;
                        SET @CurencyComm = ''; -- сбросили валюту комисии которую искали, потому что денег на всех денежных позициях недостаточно
                    END
                    ELSE
                    BEGIN

                        -- записываем сделки конвертации
                        INSERT INTO @Trades (rnum, n, SubAcc_Code, Security_Code, Qty, CurrPriceAsset_ShortName, Volume1, Price)
                        SELECT NULL AS rnum
                        
     , @n1 AS n
                             , SubAccCode
                             , CurrPosFree
                             , IIF(VolFreeNow >= 0, VolumForTrade, PosFree)
                             , CurName_Need
                             , ROU
ND(IIF(VolFreeNow >= 0, PosNeed, PosFree / bid_curneed * bidPosFree), 2)
                             , ROUND(CASE 
                                     WHEN IIF(VolFreeNow >= 0, VolumForTrade, PosFree) / IIF(VolFreeNow >= 0, PosNeed, PosFree / bid_curnee
d * bidPosFree) >
                                          IIF(VolFreeNow >= 0, PosNeed, PosFree / bid_curneed * bidPosFree) / IIF(VolFreeNow >= 0, VolumForTrade, PosFree)
                                     THEN IIF(VolFreeNow >= 0, VolumForTrade, PosF
ree) / IIF(VolFreeNow >= 0, PosNeed, PosFree / bid_curneed * bidPosFree)
                                     ELSE IIF(VolFreeNow >= 0, PosNeed, PosFree / bid_curneed * bidPosFree) / IIF(VolFreeNow >= 0, VolumForTrade, PosFree)
                           
          END, 2)
                        FROM #trades;

                        SET @VolumeComm = @VolumeComm + ROUND(ISNULL((SELECT TOP 1 IIF(VolFreeNow >= 0, PosNeed, PosFree / bid_curneed * bidPosFree) FROM #trades), 0), 2);
                    END
  
              END -- конец else на 179 строке

                SET @n1 = @n1 - 1;
            END -- конец внутреннего цикла формирования сделок конвертаций

            -- Обновляем таблицу сделок - нумеруем, чтобы загружать посделочно сделки в Корт
    
        INSERT INTO @TradesWithRowNum (rnum, n, SubAcc_Code, Security_Code, Qty, CurrPriceAsset_ShortName, Volume1, Price)
            SELECT ROW_NUMBER() OVER (ORDER BY n) AS rnum
                 , n
                 , SubAcc_Code
                 , Sec
urity_Code
                 , Qty
                 , CurrPriceAsset_ShortName
                 , Volume1
                 , Price
            FROM @Trades;

            SELECT * FROM @TradesWithRowNum;

            -- Формирование сделок в Корт
          
  SET @n3 = (SELECT MAX(rnum) FROM @TradesWithRowNum);

            WHILE @n3 > 0
            BEGIN
                SET @WaitCount = 1200; -- задержка, не передаем в ТДБ сделку, пока предыдущая не закончила грузиться
                WHILE (@WaitCount > 0 
AND EXISTS (SELECT TOP 1 1 FROM QORT_BACK_TDB.dbo.ImportTrades t WITH (NOLOCK) WHERE t.IsProcessed IN (1, 2)))
                BEGIN
                    WAITFOR DELAY '00:00:03';
                    SET @WaitCount = @WaitCount - 1;
                END

  
              -- Добавление сделки в Корт
                INSERT INTO QORT_BACK_TDB.dbo.ImportTrades (
                    IsProcessed
                  , ET_Const
                  , IsDraft
                  , TradeDate
                  , TradeTime
   
               , TSSection_Name
                  , BuySell
                  , Security_Code
                  , Qty
                  , Price
                  , Volume1
                  , CurrPriceAsset_ShortName
                  , PutPlannedDate
   
               , PayPlannedDate
                  , PutAccount_ExportCode
                  , PayAccount_ExportCode
                  , SubAcc_Code
                  , TT_Const
                  , PT_Const
                  , IsSynchronize
               
   , CpSubacc_Code
                  , FunctionType
                  , CurrPayAsset_ShortName
                  , TradeNum
                  , CpFirm_BOCode
                )
                SELECT 1 AS IsProcessed
                     , 2 AS ET_Const
  
                   , 'n' AS IsDraft
                     , @todayInt AS TradeDate
                     , REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '') + '000' AS TradeTime
                     , 'OTC_FX' TSSection_Name
                     , 2 AS Buy
Sell
                     , Security_Code AS Security_Code
                     , Qty AS Qty
                     , Price AS Price
                     , Volume1 AS Volume1
                     , CurrPriceAsset_ShortName AS CurrPriceAsset_ShortName
      
               , @todayInt AS PutPlannedDate
                     , @todayInt AS PayPlannedDate
                     , 'ARMBR_MONEY' AS PutAccount_ExportCode
                     , 'ARMBR_MONEY' AS PayAccount_ExportCode
                     , SubAcc_Code 
AS SubAcc_Code
                     , 8 AS TT_Const
                     , 2 AS PT_Const
                     , 'y' AS IsSynchronize
                     , 'AB0001' AS CpSubacc_Code
                     , 0 AS FunctionType
                     , CurrPrice
Asset_ShortName AS CurrPayAsset_ShortName
                     , CAST(CAST(RIGHT(SubAcc_Code, 4) AS VARCHAR(8)) + CAST(ISNULL((SELECT MAX(ID) FROM QORT_BACK_DB.dbo.Trades WITH (NOLOCK)) + 1, 0) AS VARCHAR(8)) AS INT) AS TradeNum
                     , '00
001' AS CpFirm_BOCode
                FROM @TradesWithRowNum
                WHERE rnum = @n3;

                SET @n3 = @n3 - 1;
            END -- конец внутреннего цикла формирования сделок в Корт

            -- Замораживаем позицию клиента для следу
ющих сделок
            UPDATE @Position
            SET Frozen = 1
            WHERE Security_Code = @CurencyComm;

            SELECT * FROM @Position;

            SET @n = @n - 1;
        END -- конец цикла прохода по начисленным комиссиям

    END TR
Y
    BEGIN CATCH
        -- Обработка исключений
        WHILE @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Message = 'ERROR: ' + ERROR_MESSAGE();
        -- Вставка сообщения об ошибке в таблицу uploadLogs
        INSERT INTO QORT_ARM_SUPPORT.dbo.uploadL
ogs(logMessage, errorLevel) VALUES (@Message, 1001);
        -- Возвращаем сообщение об ошибке
        SELECT @Message AS result, 'STATUS' AS defaultTask, 'red' AS color;
    END CATCH
END;
