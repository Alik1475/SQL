
-- exec QORT_ARM_SUPPORT_test.dbo.ReconcilAssetsBloomberg

CREATE PROCEDURE [dbo].[ReconcilAssetsBloomberg]
AS
BEGIN
    BEGIN TRY
        -- Инициализация переменных
        DECLARE @WaitCount INT;
        DECLARE @Message VARCHAR(1024);

        DECLAR
E @SendMail BIT = 0;
        DECLARE @FileName VARCHAR(128) = '\\192.168.14.22\Exchange\QORT_Files\Assets\Assets_Bloomberg.xlsx';

        DECLARE @NotifyEmail VARCHAR(1024) = 'aleksandr.mironov@armbrok.am;sona.nalbandyan@armbrok.am;armine.khachatryan@arm
brok.am';
        DECLARE @Sheet1 VARCHAR(64) = 'Sheet1';

        DECLARE @sql VARCHAR(1024);

        -- Очистка временных таблиц, если они существуют
        IF OBJECT_ID('tempdb..##f', 'U') IS NOT NULL DROP TABLE ##f;
        IF OBJECT_ID('tempdb..#t'
, 'U') IS NOT NULL DROP TABLE #t;
        IF OBJECT_ID('tempdb..##result', 'U') IS NOT NULL DROP TABLE ##result;


        -- Обработка и фильтрация данных из временной таблицы ##f в #t
        SELECT
              LEFT(Code, 12) AS ISIN
            , isn
ull(DX657,Security_NAME) AS ViewName
            , Par_Amt AS Nominal
            , Long_Company_Name_Realtime AS Issuer
            , IIF(Sectoral_Sanctioned_Security = 'y' OR OFAC_Sanctioned_Security = 'y' /*OR [EU SAnctioned Security] = 'y' */ OR UK_Sa
nctioned_Security = 'y', 'y', 'n') AS Sanction
            , TRY_CONVERT(VARCHAR(8), DATEADD(MINUTE, CAST(Issue_dt AS bigint)/60000, '1970-01-01'), 112) AS Issue_date
			, TRY_CONVERT(VARCHAR(8), DATEADD(MINUTE, CAST(Nxt_Cpn_Dt AS bigint)/60000, '1970-01-
01'), 112) AS Nxt_Cpn_Dt

			, TRY_CONVERT(VARCHAR(8), DATEADD(MINUTE, CAST(Maturity AS bigint)/60000, '1970-01-01'), 112) AS Maturity_date


		INTO #t
        FROM QORT_ARM_SUPPORT_TEST.dbo.BloombergData po
        WHERE (po.name is not null or po.name <> 'Not Found') --and po.code = 'AMGB3029A522 CORP'

        SELECT * FROM #t;
		--RETURN
        -- Вставка данных в основную таблицу Assets

        INSERT INTO QORT_BACK_TDB_UAT.dbo.Assets (
            IsProcessed, ET_Const, ISIN, IsInSanctionList, shortName, Marking
        )
        SELECT DISTINCT
              1 AS IsProcessed
            , 4 AS ET_Const
            , CAST(t.ISIN AS VARC
HAR(16)) AS ISIN
            , IIF(ass.IsInSanctionList = 'n' AND t.Sanction = 'y', t.Sanction, ass.IsInSanctionList) AS IsInSanctionList
            , ass.ShortName AS shortName
            , ass.Marking AS Marking
        FROM #t t
        LEFT OUTER JO
IN QORT_BACK_DB_UAT.dbo.Assets ass WITH (NOLOCK) ON ass.ISIN = t.ISIN
        WHERE ass.Enabled <> ass.id AND ass.IsInSanctionList <> t.Sanction;

        -- Ожидание обновления данных
        SET @WaitCount = 1200;
        WHILE (@WaitCount > 0 AND EXIST
S (SELECT TOP 1 1 FROM QORT_BACK_TDB_UAT.dbo.Assets t WITH (NOLOCK) WHERE t.IsProcessed IN (1,2)))
        BEGIN
            WAITFOR DELAY '00:00:03';
            SET @WaitCount = @WaitCount - 1;
        END;

        -- Обработка результатов сверки данны
х
        SELECT
              t.ISIN AS ISIN
            , t.ViewName AS Ticker
            , t.Nominal AS Nominal
            , t.Issuer AS Issuer
            , t.Sanction AS Sanction
            , t.Issue_date AS Issue_date
            , t.Maturity_dat
e AS Maturity_date
            , q.isin AS ISINQ
            , q.ViewName AS AssetShortNameQ
            , q.BaseValue AS NominalQ
            , e.FirmShortName AS IssuerQ
            , q.IsInSanctionList AS SanctionQ
            , q.EmitDate AS Issue_dat
eQ
            , q.CancelDate AS Maturity_dateQ
            , s2.StatusTXT AS Result
        INTO ##result
        FROM #t t
        FULL OUTER JOIN QORT_BACK_DB_UAT.dbo.Assets q ON t.ISIN = q.ISIN
        LEFT OUTER JOIN QORT_BACK_DB_UAT.dbo.Firms e WITH
 (NOLOCK) ON e.id = q.EmitentFirm_ID
        OUTER APPLY (
            SELECT CASE
                WHEN t.ISIN IS NULL AND q.ISIN <> '' THEN 'Asset not found in Bloomberg: ' + q.ISIN
                WHEN q.ISIN IS NULL AND t.ISIN IS NOT NULL THEN 'Asset n
ot found in Qort!!!' + t.ISIN
             ELSE ''
                    + IIF(t.Sanction <> q.IsInSanctionList, ', Sanction!!!', '')
                    + IIF(t.ViewName <> LEFT(q.ViewName, 30) AND t.ViewName <> '#N/A N/A', ', Ticker(ShortName)', '')
     
             --  + IIF(t.Issue_date <> q.EmitDate AND t.Issue_date <> 0, ', Issuer_Date', '')
                    + IIF(ISNULL(t.Nominal, 0) <> ISNULL(q.BaseValue, 0) AND ISNULL(t.Nominal, 0) <> 0, ', Nominal', '')
                 --   + IIF(t.Maturity_d
ate <> q.CancelDate AND t.Maturity_date <> 0, ', MaturityDate', '')
            END AS StatusTXT
        ) s1
        OUTER APPLY (
            SELECT CASE
                WHEN LEFT(s1.StatusTXT, 2) = ', ' THEN 'Mismatched: ' + RIGHT(StatusTXT, LEN(Status
TXT) - 2)
                WHEN StatusTXT = '' THEN 'OK'
                ELSE StatusTXT
            END AS StatusTXT
        ) s2
        WHERE (q.Enabled <> q.id OR q.Enabled IS NULL) AND (q.AssetType_Const = 1 OR q.AssetType_Const IS NULL) AND q.Marking 
<> 'XS1207654853';

        SELECT * FROM ##result ORDER BY ISINQ;
  /*
        -- Отправка email с отчетом
        IF EXISTS (SELECT ISIN FROM ##result WHERE Result <> 'OK')
        BEGIN
            DECLARE @FilePath VARCHAR(255) = '\\192.168.14.22\Exch
ange\QORT_Files\PRODUCTION\Reports';
            IF RIGHT(@FilePath, 1) <> '\' SET @FilePath = @FilePath + '\';
            DECLARE @SheetClient VARCHAR(32) = 'Assets';
            DECLARE @fileTemplate VARCHAR(512) = 'template_Asset_Check_Bloomberg.xlsx'
;
            DECLARE @fileReport VARCHAR(512) = 'Asset_Check_Bloomberg_' + CONVERT(VARCHAR, GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '-') + '.xlsx';
            DECLARE @cmd VARCHAR(512);
            DECLARE @sql2 VARCHAR(10
24);

            -- Копирование шаблона отчета
            SET @cmd = 'copy "' + @FilePath + @fileTemplate + '" "' + @FilePath + @fileReport + '"';
            EXEC master.dbo.xp_cmdshell @cmd, no_output;

            -- Вставка данных в новый файл Excel

            SET @sql2 = 'INSERT INTO OPENROWSET (
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0; Database=' + @FilePath + @fileReport + '; HDR=YES;IMEX=0'',
                ''SELECT * FROM [' + @SheetClient + '$A1:Q1000000]''
)
                SELECT ISIN, ISINQ, Issue_date, Issue_dateQ, Ticker, AssetShortNameQ, Nominal, NominalQ,
                       Maturity_date, Maturity_dateQ, Issuer, IssuerQ, Sanction, SanctionQ, Result
                FROM ##result ORDER BY ISINQ';
  
          EXEC(@sql2);

            -- Подготовка сообщения для отправки по email
            DECLARE @NotifyMessage VARCHAR(MAX);
            DECLARE @NotifyTitle VARCHAR(1024) = NULL;
            SET @NotifyMessage = CAST((
                SELECT '//1\\
' + IIF(tt.ISIN IS NULL, 'NOT FOUND!!!', CAST(tt.ISIN AS VARCHAR))
                    + '//2\\' + ISNULL(CAST(tt.ISINQ AS VARCHAR), 'NOT FOUND!!!')
                    + '//2\\' + ISNULL(CAST(tt.Issue_date AS VARCHAR), '----------')
                    +
 '//2\\' + ISNULL(CAST(tt.Issue_dateQ AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(CAST(tt.Ticker AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(tt.AssetShortNameQ, '----------') COLLATE Cyrillic_General_CI_AS
     
               + '//2\\' + ISNULL(CAST(tt.Nominal AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(CAST(tt.NominalQ AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(CAST(tt.Maturity_date AS VARCHAR), '----------')
       
             + '//2\\' + ISNULL(CAST(tt.Maturity_dateQ AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(CAST(tt.Issuer AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(CAST(tt.IssuerQ AS VARCHAR), '----------')
          
          + '//2\\' + ISNULL(CAST(tt.Sanction AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(CAST(tt.SanctionQ AS VARCHAR), '----------')
                    + '//2\\' + tt.Result
          FROM ##result tt
                WHERE tt.Resu
lt <> 'OK' AND tt.ISIN IS NOT NULL
                ORDER BY ISINQ ASC
                FOR XML PATH('')
            ) AS VARCHAR(MAX));

            SET @NotifyMessage = REPLACE(@NotifyMessage, '//1\\', '<tr><td>');
            SET @NotifyMessage = REPLACE
(@NotifyMessage, '//2\\', '</td><td>');
            SET @NotifyMessage = REPLACE(@NotifyMessage, '//3\\', '</td></tr>');
            SET @NotifyMessage = REPLACE(@NotifyMessage, '//4\\', '</td><td ');
            SET @NotifyMessage = REPLACE(@NotifyMessag
e, '//5\\', '>');

            SET @NotifyMessage = '<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'
                                + '<td>ISIN(Bloomberg)</td><td>ISIN(Qort)</td><td>IssuerDate(Bloomberg)</td><td>IssuerDate(Qort)</t
d><td>Ticker(Bloomberg)</td><td>AssetShortName(Qort)</td><td>Nominal(Bloomberg)</td><td>Nominal(Qort)</td><td>MaturityDate(Bloomberg)</td><td>MaturityDate(Qort)</td><td>Issuer(Bloomberg)</td><td>Issuer(Qort)</td><td>Sanction</td><td>SanctionQ</td><td>Resu
lt</td></tr>'
                                + @NotifyMessage + '</table>';

            SET @fileReport = @FilePath + @fileReport;
            SET @NotifyTitle = 'Alert!!! Assets for check';

            -- Отправка email
            EXEC msdb.dbo.sp_se
nd_dbmail
                @profile_name = 'qort-test-sql',--'qort-sql-mail',
                @recipients = @NotifyEmail,
                @subject = @NotifyTitle,
                @BODY_FORMAT = 'HTML',
                @body = @NotifyMessage,
              
  @file_attachments = @fileReport;

            -- Удаление старых отчетов
            SET @cmd = 'del "' + @FilePath + 'Asset_Check_Bloomberg_*.*"';
            EXEC master.dbo.xp_cmdshell @cmd, no_output;

            PRINT @NotifyTitle;
        END -- 
Конец блока отправки сообщения
		--*/
    END TRY
    BEGIN CATCH
        -- Обработка ошибок
        WHILE @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Message = 'ERROR: ' + ERROR_MESSAGE();
        INSERT INTO QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMess
age, errorLevel) VALUES (@Message, 1001);
        PRINT @Message;
        SELECT @Message AS Result, 'red' AS ResultColor;
    END CATCH
END
