
-- exec QORT_ARM_SUPPORT..BlockingForOrders

CREATE PROCEDURE [dbo].[BlockingForOrders]
AS
BEGIN
    BEGIN TRY
        DECLARE @Message VARCHAR(1024) -- для уведомлений об ошибках
        DECLARE @todayDate DATE = GETDATE()
        DECLARE @todayInt INT 
= CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)

        -- Удаляем временные таблицы, если они существуют
        IF OBJECT_ID('tempdb..#tt', 'U') IS NOT NULL DROP TABLE #tt
        IF OBJECT_ID('tempdb..#t1', 'U') IS NOT NULL DROP TABLE #t1

        --
 Основной запрос для выборки данных
        SELECT 
              ti.id AS SystemID
            , ti.AuthorSubAcc_ID
            , IIF(
                  ti.Volume = 0
                , IIF(
                      ti.pricetype IN (2), ti.Qty * ti.price
   
                 , IIF(
                          ti.pricetype IN (1)
                        , CASE 
                              WHEN ti.asset_id > 0 THEN ti.Qty * (
                                  SELECT BaseValue 
                                  
FROM QORT_BACK_DB..assets 
                                  WHERE id = ti.asset_id
                              ) * ti.price / 100
                              ELSE ti.Qty * (
                                  SELECT ass.BaseValue 
                    
              FROM QORT_BACK_DB..securities sec 
                                  LEFT OUTER JOIN QORT_BACK_DB..assets ass ON ass.id = sec.asset_id
                                  WHERE sec.id = ti.security_ID
                              ) * ti.price
 / 100
                          END
                        , 0
                    )
                )
                , ti.Volume
            ) AS Qty_Order
            , tra.Volume1 AS Qty_Trade
            , ti.CurrencyAsset_ID AS CurrencyAsset_ID1
 
           , CAST(0 AS FLOAT) AS Qty_TradeSum
            , ISNULL(cr.id, 0) AS ID_correction
        INTO #tt
        FROM QORT_BACK_DB..TradeInstrs ti
        LEFT OUTER JOIN QORT_BACK_DB..TradeInstrLinks tr ON ti.id = tr.TradeInstr_ID
        LEFT OUTE
R JOIN QORT_BACK_DB..Trades tra ON tr.Trade_ID = tra.ID 
                                                      AND Tra.VT_Const NOT IN (12, 10) -- сделка не расторгнута
                                                      AND tra.NullStatus = 'n'
       
                                               AND tra.Enabled = 0
                                                      AND tra.IsDraft = 'n'
                                                      AND tra.IsProcessed = 'y'
													  
        LEFT OUT
ER JOIN QORT_BACK_DB..CorrectPositions cr ON cr.InfoSource = ti.id 
                                                               AND cr.CT_Const = 50 
                                                               AND cr.IsCanceled = 'n'
        WHERE t
i.date > 20240401 -- поручения с начала года. Нужно будет придумать логику - сократить поиск
          AND ti.Enabled = 0
          AND ti.TIPROP_Flags IN (1, 3) -- галочка хеджирования стоит
          AND ti.IS_Const IN (1, 2, 4, 11) -- NEW, In executing
, Partially executed, Not execution
		  AND ti.Type in (7) -- buy only
        ORDER BY SystemID

        -- Обновление суммы сделок
        UPDATE #tt
        SET Qty_TradeSum = (
          cast( (SELECT SUM(Qty_Trade)
            FROM #tt AS t2
        
    WHERE t2.SystemID = #tt.SystemID) as float)
         - Qty_Order)

        UPDATE #tt
        SET Qty_TradeSum = Qty_Order * (-1)
        WHERE Qty_TradeSum IS NULL

        -- Удаление дубликатов
        ;WITH CTE AS (
            SELECT *,
         
          ROW_NUMBER() OVER (PARTITION BY SystemID ORDER BY (SELECT NULL)) AS rn
            FROM #tt
        )
        DELETE FROM CTE
        WHERE rn > 1

        -- Вывод результатов
        SELECT * FROM #tt

        -- Создание временной таблицы #t1

        SELECT *   
        INTO #t1
        FROM QORT_BACK_DB..CorrectPositions corr
        LEFT JOIN #tt tt ON tt.SystemID = corr.InfoSource
        WHERE corr.CT_Const IN (50)
          AND corr.Enabled = 0
          AND corr.IsCanceled = 'n'
       
   AND (tt.SystemID IS NULL OR dbo.fFloatToMoney2Varchar(tt.Qty_TradeSum) <> dbo.fFloatToMoney2Varchar(corr.Size))
        
        SELECT * FROM #t1

        -- Удаление записей
        --/*              
        INSERT INTO QORT_BACK_TDB.dbo.CancelCorre
ctPositions (IsProcessed, BackID, IsExecByComm) 
        --*/
        SELECT 
              1 AS IsProcessed
            , n.BackID
            , 'n' AS IsExecByComm
        FROM #t1 n 

        --/*
        INSERT INTO QORT_BACK_TDB.dbo.CorrectPositions 
(IsProcessed, ET_Const, CT_Const, BackID
                , InfoSource, Account_ExportCode, Subacc_Code, Asset
                , Size, IsInternal, RegistrationDate) 
        --*/
        SELECT 
              1 AS IsProcessed
            , 2 AS ET_Const
  
          , 50 AS CT_Const
            , CAST(RIGHT(sub.SubaccCode, 4) AS VARCHAR(8)) + CAST((n.SystemID) AS VARCHAR(8)) + CAST((@todayInt) AS VARCHAR(8)) AS BackID
            , n.SystemID
            , 'Armbrok_Mn_Client' AS AccountExportCode
          
  , sub.SubaccCode
            , ass.ShortName
            , CAST(n.Qty_TradeSum AS DECIMAL(32, 2))
            , 'y' AS IsInternal
            , @todayInt AS RegistrationDate
        FROM #tt n
        LEFT OUTER JOIN QORT_BACK_DB.dbo.Assets ass ON ass.i
d = n.CurrencyAsset_ID1
        LEFT OUTER JOIN QORT_BACK_DB.dbo.Subaccs sub ON sub.id = n.AuthorSubAcc_ID
        WHERE CAST(n.Qty_TradeSum AS DECIMAL(32, 2)) * (-1) <> 0
          AND n.ID_correction = 0

    END TRY
    BEGIN CATCH
        WHILE @@TRAN
COUNT > 0 ROLLBACK TRAN
        SET @Message = 'ERROR: ' + ERROR_MESSAGE()
        INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001)
        PRINT @Message
        SELECT @Message AS Result, 'red' AS ResultColor
 
   END CATCH
END
