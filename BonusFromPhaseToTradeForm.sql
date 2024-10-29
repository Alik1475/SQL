
-- exec QORT_ARM_SUPPORT.dbo.BonusFromPhaseToTradeForm

CREATE PROCEDURE [dbo].[BonusFromPhaseToTradeForm]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Объявление переменных
        DECLARE @todayDate DATE = GETDATE();
        DECLARE @todayInt
 INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT);
        DECLARE @Message VARCHAR(1024);

        -- Удаляем временную таблицу, если она существует
        IF OBJECT_ID('tempdb..#t', 'U') IS NOT NULL DROP TABLE #t;

        -- Создаем временную табл
ицу #t с данными о сделках и этапах
        SELECT Tr.id AS Trade_ID
             , P.trade_ID AS Phase_ID
             , ISNULL(Tr.TSCommission, 0) AS TSCommission
             , ISNULL(P.QtyBefore, 0) AS QtyBefore
        INTO #t
        FROM QORT_BACK_
DB.dbo.Trades Tr
        LEFT OUTER JOIN QORT_BACK_DB.dbo.Phases P ON P.Trade_ID = Tr.ID 
                                                 AND P.PC_Const IN (23) 
                                                 AND P.IsCanceled = 'n'
        WHERE Tr.TSC
ommission NOT IN (0)
          AND ISNULL(Tr.SubAcc_ID, 0) NOT IN (2)
          AND Tr.TradeDate > 20240101; -- ARMBR_Subacc

        SELECT * FROM #t;

        -- Обнуляем, где у сделки есть цифра Bonus, но в этапе нет
        INSERT INTO QORT_BACK_TDB.d
bo.ImportTrades (ET_Const, IsProcessed, TradeNum, BuySell, TradeDate, TSSection_Name, TSCommission)
        SELECT 4 AS ET_Const
             , 1 AS IsProcessed
             , Trad.TradeNum
             , Trad.BuySell
             , Trad.TradeDate
       
      , Tss.Name
             , QtyBefore
        FROM #t t
        INNER JOIN QORT_BACK_DB.dbo.Trades Trad WITH (NOLOCK) ON t.Trade_ID = Trad.ID
                                                            AND QtyBefore <> Trad.TSCommission
        LEFT O
UTER JOIN QORT_BACK_DB.dbo.TSSections Tss WITH (NOLOCK) ON Tss.ID = Trad.TSSection_ID;

        -- Проверяем, что у этапа сделки Bonus есть соответствующая цифра в сделке
        INSERT INTO QORT_BACK_TDB.dbo.ImportTrades (ET_Const, IsProcessed, TradeNum,
 BuySell, TradeDate, TSSection_Name, TSCommission)
        SELECT 4 AS ET_Const
             , 1 AS IsProcessed
             , Trd.TradeNum AS TradeNum
             , Trd.BuySell
             , Trd.TradeDate
             , Ts.Name
             , QtyBefore

        FROM QORT_BACK_DB.dbo.Phases Ph
        LEFT OUTER JOIN QORT_BACK_DB.dbo.Trades Trd WITH (NOLOCK) ON Ph.Trade_ID = Trd.ID
        LEFT OUTER JOIN QORT_BACK_DB.dbo.TSSections Ts WITH (NOLOCK) ON Ts.ID = Trd.TSSection_ID
        WHERE Ph.PC_Const I
N (23)
          AND Ph.IsCanceled = 'n'
          AND QtyBefore <> TSCommission
          AND Ph.EventDate > 20240101;

    END TRY
    BEGIN CATCH
        -- Обработка исключений
        WHILE @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Message = 'ERROR
: ' + ERROR_MESSAGE();
        -- Вставка сообщения об ошибке в таблицу uploadLogs
        INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001);
        -- Возвращаем сообщение об ошибке
        SELECT @Message AS re
sult, 'STATUS' AS defaultTask, 'red' AS color;
    END CATCH
END;
