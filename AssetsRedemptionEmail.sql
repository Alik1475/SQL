
-- exec QORT_ARM_SUPPORT.dbo.AssetsRedemptionEmail @SendMail = 1

CREATE PROCEDURE [dbo].[AssetsRedemptionEmail]
    @SendMail bit
AS
BEGIN
    BEGIN TRY
        DECLARE @todayDate DATE = GETDATE()
        DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @t
odayDate, 112) AS INT)

        DECLARE @Message VARCHAR(1024)

        -- DECLARE @FileName VARCHAR(128) = '\\192.168.14.22\Exchange\QORT_Files\TEST\Firms_ARM\Clients_from_register_apgrade.xlsx';
        -- DECLARE @FileName VARCHAR(128) = '\\192.168.14.
22\Exchange\QORT_Files\TEST\test\Copy of Clients_from_register_apgrade.xlsx';
        -- DECLARE @FileName VARCHAR(128) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Clients\Copy of Clients_from_register_apgrade.xlsx';
        -- DECLARE @Sheet1 VARCH
AR(64) = 'Sheet1';

        DECLARE @Result VARCHAR(128)
        DECLARE @NotifyEmail VARCHAR(1024) = 'milena.ghayfajyan@armbrok.am;maxim.biryukov@armbrok.am;tigran.gevorgyan@armbrok.am;backoffice@armbrok.am;aleksey.yudin@armbrok.am;QORT@armbrok.am'

    
    IF OBJECT_ID('tempdb..#t', 'U') IS NOT NULL DROP TABLE #t

        SELECT 'Coupon' AS EventType
             , cp.EndDate AS RedemtionDate
             , ass.ISIN
             , ass.ViewName AS Insrument
             , f1.Name AS curency
             
, f.Name AS EmitentAsset
             , ass.Country AS Country
        INTO #t
        FROM QORT_BACK_DB.dbo.Coupons CP
        INNER JOIN QORT_BACK_DB.dbo.Assets ass ON ass.id = CP.Asset_ID
        INNER JOIN QORT_BACK_DB.dbo.Firms f ON f.id = ass.Emiten
tFirm_ID
        LEFT OUTER JOIN QORT_BACK_DB.dbo.Assets f1 ON f1.id = ass.BaseCurrencyAsset_ID
        WHERE CP.EndDate = @todayInt
        
        SELECT * FROM #t 

        -- Блок формирования части уведомления о сделках в процессе
        IF OBJECT_
ID('tempdb..#t1', 'U') IS NOT NULL DROP TABLE #t1

        SELECT tr.id
             , Tr.RepoTrade_ID AS RepoTrade_ID
             , fcp.Name AS CpName
             , ass.ViewName AS Insrument
             , f.Name AS EmitentAsset
             , ass.ISIN

             , CASE 
                   WHEN (tr.RepoTrade_ID > 0 AND Tr.BuySell = 1 AND tr.IsRepo2 = 'n') 
                        OR (tr.IsRepo2 = 'y' AND Tr.BuySell = 2) THEN 'Reverse'
                   WHEN (tr.RepoTrade_ID > 0 AND Tr.BuySell = 2 AN
D tr.IsRepo2 = 'n') 
                        OR (tr.IsRepo2 = 'y' AND Tr.BuySell = 1) THEN 'Direct'
                   WHEN (tr.RepoTrade_ID < 0 AND Tr.BuySell = 1 AND tr.IsRepo2 = 'n') 
                        OR (tr.IsRepo2 = 'y' AND Tr.BuySell = 2) THE
N 'Buy'
                   WHEN (tr.RepoTrade_ID < 0 AND Tr.BuySell = 2 AND tr.IsRepo2 = 'n') 
                        OR (tr.IsRepo2 = 'y' AND Tr.BuySell = 1) THEN 'Sell'
                   ELSE 'unknown'
               END AS TradeType
             , Tr
.Qty
             , Tr.Volume1
             , AssCur.Name AS Cname
             , Tr.RepoRate
             , cp.EndDate AS RedemtionDate
             , 'Coupon' AS EventType
             , cp.Volume * Tr.Qty AS PayAmountCoupon
             , f1.Name AS Cu
rCoupon
        INTO #t1
        FROM QORT_BACK_DB.dbo.Coupons CP
        INNER JOIN QORT_BACK_DB.dbo.Assets ass ON ass.id = CP.Asset_ID
        LEFT OUTER JOIN QORT_BACK_DB.dbo.Firms f ON f.id = ass.EmitentFirm_ID
        LEFT OUTER JOIN QORT_BACK_DB.dbo
.Assets f1 ON f1.id = ass.BaseCurrencyAsset_ID
        LEFT OUTER JOIN QORT_BACK_DB.dbo.Securities sec ON sec.Asset_ID = CP.Asset_ID
        LEFT OUTER JOIN QORT_BACK_DB.dbo.Trades Tr ON Tr.Security_ID = sec.id
        LEFT OUTER JOIN QORT_BACK_DB.dbo.Fir
ms fcp ON fcp.ID = Tr.CpFirm_ID
        LEFT OUTER JOIN QORT_BACK_DB.dbo.Assets AssCur ON AssCur.id = Tr.CurrPayAsset_ID
        WHERE CP.EndDate = @todayInt 
          AND Tr.VT_Const NOT IN (12, 10) -- сделка не расторгнута
          AND tr.NullStatus =
 'n'
          AND tr.Enabled = 0
          AND tr.IsDraft = 'n'
          AND tr.IsProcessed = 'y'
          -- AND Tr.TT_Const IN (6,3) -- OTC repo (6); Exchange repo (3)
         AND Tr.PutDate = 0 -- не закрытые по бумагам сделки
      
        
     
   SELECT * FROM #t1 

        -- Начало блока отправки сообщений
        IF EXISTS (SELECT RedemtionDate FROM #t) AND @SendMail = 1 
        BEGIN
            DECLARE @NotifyMessage VARCHAR(MAX)
            DECLARE @NotifyTitle VARCHAR(1024) = NULL

    
        SET @NotifyMessage = CAST((
                SELECT '//1\\' + ISNULL(t.EventType, 'NULL')
                     + '//2\\' + QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(CAST(TRY_CONVERT(INT, t.RedemtionDate, 105) AS VARCHAR))
                     + '//2\\
' + ISNULL(t.ISIN, 'NULL')
                     + '//2\\' + ISNULL(t.Insrument, 'NULL')
                     + '//2\\' + ISNULL(t.curency, 'NULL')
                     + '//2\\' + ISNULL(t.EmitentAsset, 'NULL')
                     + '//2\\' + ISNULL(t.Co
untry, 'NULL')
                FROM #t t
                FOR XML PATH('')
            ) AS VARCHAR(MAX))

            SET @NotifyMessage = REPLACE(@NotifyMessage, '//1\\', '<tr><td>')
            SET @NotifyMessage = REPLACE(@NotifyMessage, '//2\\', '</td
><td>')
            SET @NotifyMessage = REPLACE(@NotifyMessage, '//3\\', '</td></tr>')
            SET @NotifyMessage = REPLACE(@NotifyMessage, '//4\\', '</td><td ')
            SET @NotifyMessage = REPLACE(@NotifyMessage, '//5\\', '>')

            SET 
@NotifyMessage = 'is an automatically generated message.<br/><br/><b>'
                + '<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'
                + '<td>EventType</td><td>RecordDate</td><td>ISIN</td><td>Instrument</td><td>Cu
rrency if available</td><td>EmitentAsset</td><td>Country</td></tr>'
                + @NotifyMessage + '</table>'

            IF EXISTS (SELECT id FROM #t1)
            BEGIN
                DECLARE @NotifyMessage1 VARCHAR(MAX)
                DECLARE @N
otifyTitle1 VARCHAR(1024) = NULL

                SET @NotifyMessage1 = CAST((
                    SELECT '//1\\' + CAST(t1.id AS VARCHAR(16)) + IIF(t1.RepoTrade_ID > 0, '/' + CAST(t1.RepoTrade_ID AS VARCHAR(16)), '')
                         + '//2\\' + 
ISNULL(t1.CpName, 'NULL')
                         + '//2\\' + ISNULL(t1.Insrument, 'NULL')
                         + '//2\\' + ISNULL(t1.EmitentAsset, 'NULL')
                         + '//2\\' + ISNULL(t1.ISIN, 'NULL')
                         + '//2\\
' + ISNULL(t1.TradeType, 'NULL')
                         + '//2\\' + CAST(QORT_ARM_SUPPORT.dbo.fFloatToCurrency(t1.Qty) AS VARCHAR(16))
                         + '//2\\' + CAST(QORT_ARM_SUPPORT.dbo.fFloatToCurrency(t1.Volume1) AS VARCHAR(16)) + CAST(t1.
Cname AS VARCHAR(16))
                         + '//2\\' + IIF(t1.RepoTrade_ID > 0, CAST(t1.RepoRate AS VARCHAR(16)) + '%', '-')
                         + '//2\\' + QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(CAST(TRY_CONVERT(INT, t1.RedemtionDate, 105) AS VA
RCHAR))
                         + '//2\\' + ISNULL(t1.EventType, 'NULL')
                         + '//2\\' + CAST(t1.PayAmountCoupon AS VARCHAR(16)) + CAST(t1.CurCoupon AS VARCHAR(16))
                    FROM #t1 t1
                    FOR XML PATH('')

                ) AS VARCHAR(MAX))

                SET @NotifyMessage1 = REPLACE(@NotifyMessage1, '//1\\', '<tr><td>')
                SET @NotifyMessage1 = REPLACE(@NotifyMessage1, '//2\\', '</td><td>')
                SET @NotifyMessage1 = REPLACE(@No
tifyMessage1, '//3\\', '</td></tr>')
                SET @NotifyMessage1 = REPLACE(@NotifyMessage1, '//4\\', '</td><td ')
                SET @NotifyMessage1 = REPLACE(@NotifyMessage1, '//5\\', '>')

                SET @NotifyMessage1 = '<br/><br/><b>'
 
                   + '<br><br>Trade in process now: '
                    + '<table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'
                    + '<td>Trade_ID</td><td>Counterparty</td><td>Instrument</td><td>EmitentAsset</td><td>ISIN</td><
td>TradeType</td><td>Qty</td><td>Volume</td><td>RepoRate</td><td>RecordDate</td><td>EventType</td><td>Payment amount</td></tr>'
                    + @NotifyMessage1 + '</table>'
            END
            ELSE 
                SET @NotifyMessage1 = '<br
/><br/><b>'
                    + '<br><br>Trade in process now: '
                    + '<table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'
                    + 'NO TRADES IN PROGRESS'

            SET @NotifyMessage = @NotifyMessage + @Noti
fyMessage1
            SET @NotifyTitle = 'Alert!!! Assets with redemtion today'

            EXEC msdb.dbo.sp_send_dbmail
                @profile_name = 'qort-sql-mail'
              , @recipients = @NotifyEmail
              , @subject = @NotifyTitle
 
             , @BODY_FORMAT = 'HTML'
              , @body = @NotifyMessage

            PRINT @NotifyTitle
            -- PRINT @NotifyMessage
        END -- Конец блока отправки сообщения
    END TRY
    BEGIN CATCH
        WHILE @@TRANCOUNT > 0 ROLLBAC
K TRAN
        SET @Message = 'ERROR: ' + ERROR_MESSAGE()
        INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001)
        PRINT @Message
        SELECT @Message AS Result, 'red' AS ResultColor
    END CATCH
END
