﻿
-- exec QORT_ARM_SUPPORT.dbo.ReconcilAssetsBloomberg

CREATE PROCEDURE [dbo].[ReconcilAssetsBloomberg]
AS
BEGIN
    BEGIN TRY
        -- Инициализация переменных
        DECLARE @WaitCount INT;
        DECLARE @Message VARCHAR(1024);

        DECLARE @Se
ndMail BIT = 0;
        DECLARE @FileName VARCHAR(128) = '\\192.168.14.22\Exchange\QORT_Files\Assets\Assets_Bloomberg.xlsx';

        DECLARE @NotifyEmail VARCHAR(1024) = 'backoffice@armbrok.am;depo@armbrok.am;QORT@armbrok.am;'--aleksandr.mironov@armbrok.
am;sona.nalbandyan@armbrok.am;armine.khachatryan@armbrok.am';
        DECLARE @Sheet1 VARCHAR(64) = 'Sheet1';
		DECLARE @todayDate DATE = GETDATE()
        DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)
        DECLARE @sql VARCHAR
(1024);

        -- Очистка временных таблиц, если они существуют
        IF OBJECT_ID('tempdb..##f', 'U') IS NOT NULL DROP TABLE ##f;
        IF OBJECT_ID('tempdb..#t', 'U') IS NOT NULL DROP TABLE #t;
        IF OBJECT_ID('tempdb..##resultT', 'U') IS NOT
 NULL DROP TABLE ##resultT;

-- обновление справочника про бумаги с истекшим сроком погашения--------------	
				insert into QORT_BACK_TDB.dbo.Assets (ET_Const, IsProcessed, marking, IsTrading)  

				  select distinct 4 as ET_Const, 1 as IsProcessed

				 , Marking as marking

				  , 'n' as IsTrading				 

				  FROM QORT_BACK_DB.dbo.assets 

				  where AssetClass_Const in (6) and CancelDate < @todayInt and Enabled = 0

					  AND  IsTrading = 'y'

				  --and ShortName = 'XS1634369067'

---------------------запускаем обновление справочника DepoLite--------------
		exec QORT_ARM_SUPPORT.dbo.ReconcilAssetsDepoliteEmail
-------------------------------------------------------------------------

       
 -- Обработка и фильтрация данных из временной таблицы ##f в #t
        SELECT
              LEFT(Code, 12) AS ISIN
            , isnull(DX657,Security_NAME) AS ViewName
            , Par_Amt AS Nominal
            , Long_Company_Name_Realtime AS Issuer
 
           , IIF(Sectoral_Sanctioned_Security = 'y' OR OFAC_Sanctioned_Security = 'y' OR EU_SAnctioned_Security = 'y' OR UK_Sanctioned_Security = 'y', 'y', 'n') AS Sanction
            , TRY_CONVERT(VARCHAR(8), DATEADD(MINUTE, CAST(Issue_dt AS bigint)/600
00, '1970-01-01'), 112) AS Issue_date
			, TRY_CONVERT(VARCHAR(8), DATEADD(MINUTE, CAST(Nxt_Cpn_Dt AS bigint)/60000, '1970-01-01'), 112) AS Nxt_Cpn_Dt

			, TRY_CONVERT(VARCHAR(8), DATEADD(MINUTE, CAST(Maturity AS bigint)/60000, '1970-01-01'), 112) AS Maturity_date

			, Crncy as crncy
			, Cpn as cpn
			,  (
					SELECT STRING_AGG(ColumnName, ', ')
					FROM (
						SELECT 'Sectoral_Sanctioned_Security' AS ColumnName 
						WHERE Sectoral_Sanctioned_Security = 'y'
						UNION ALL
						SELECT 'OFAC_Sanctioned_Securi
ty' 
						WHERE OFAC_Sanctioned_Security = 'y'
						UNION ALL
						SELECT 'EU_Sanctioned_Security' 
						WHERE EU_Sanctioned_Security = 'y'
						UNION ALL
						SELECT 'UK_Sanctioned_Security' 
						WHERE UK_Sanctioned_Security = 'y'
					) Sanction
Columns
			 ) AS Comment
			 , Issuer_Bulk
				INTO #t
				FROM QORT_ARM_SUPPORT.dbo.BloombergData po
				WHERE (po.name is not null or po.name <> 'Not Found') and po.date  = @todayInt
		--and po.code = 'XS1936100483 CORP'

        SELECT * FROM #t;
		--R
ETURN
        -- Вставка данных в основную таблицу Assets
        INSERT INTO QORT_BACK_TDB.dbo.Assets (
           IsProcessed, ET_Const, ISIN, IsInSanctionList, shortName, Marking, Comment)
        
        SELECT DISTINCT
              1 AS IsProcessed

            , 4 AS ET_Const
            , CAST(t.ISIN AS VARCHAR(16)) AS ISIN
            , IIF(ass.IsInSanctionList = 'n' AND t.Sanction = 'y', t.Sanction, ass.IsInSanctionList) AS IsInSanctionList
            , ass.ShortName AS shortName
            , 
ass.Marking AS Marking
			, t.comment as COMMENT
        FROM #t t
        LEFT OUTER JOIN QORT_BACK_DB.dbo.Assets ass WITH (NOLOCK) ON ass.ISIN = t.ISIN
        WHERE (ass.Enabled <> ass.id AND ass.IsInSanctionList <> t.Sanction) OR (t.comment <> ass.Com
ment);

        -- Ожидание обновления данных
        SET @WaitCount = 1200;
        WHILE (@WaitCount > 0 AND EXISTS (SELECT TOP 1 1 FROM QORT_BACK_TDB.dbo.Assets t WITH (NOLOCK) WHERE t.IsProcessed IN (1,2)))
        BEGIN
            WAITFOR DELAY '00:
00:03';
            SET @WaitCount = @WaitCount - 1;
        END;
		--RETURN
        -- Обработка результатов сверки данных
        SELECT
              t.ISIN AS ISIN
            , t.ViewName AS Ticker
            , t.Nominal AS Nominal
            , t.I
ssuer AS Issuer
            , t.Sanction AS Sanction
            , t.Issue_date AS Issue_date
            , t.Maturity_date AS Maturity_date
            , q.isin AS ISINQ
            , q.ViewName AS AssetShortNameQ
            , q.BaseValue AS NominalQ
  
          , e.FirmShortName AS IssuerQ
            , q.IsInSanctionList AS SanctionQ
            , q.EmitDate AS Issue_dateQ
            , q.CancelDate AS Maturity_dateQ
            , s2.StatusTXT AS Result
			, q.id as id
			, iif(q.AssetClass_Const in(6
), f1.Name, f.Name)  curNAME -- валюту номинала из блумберг для бондов храним в бумаге, а для всех других под инструиентом
			--, t.Issuer_Bulk Issuer_Bulk
        INTO ##resultT
        FROM #t t
        FULL OUTER JOIN QORT_BACK_DB.dbo.Assets q ON t.ISI
N = q.ISIN and q.Enabled <> q.id and q.IsTrading = 'y'
        LEFT OUTER JOIN QORT_BACK_DB.dbo.Firms e WITH (NOLOCK) ON e.id = q.EmitentFirm_ID
		left outer join QORT_BACK_DB.dbo.Securities s ON s.Asset_ID = q.id and s.TSSection_ID in (154) and s.Enabled
 <> s.id
		LEFT OUTER JOIN QORT_BACK_DB.dbo.Assets f WITH (NOLOCK) ON f.id = s.CurrPriceAsset_ID and f.id <> f.Enabled
		LEFT OUTER JOIN QORT_BACK_DB.dbo.Assets f1 WITH (NOLOCK) ON f1.id = q.BaseCurrencyAsset_ID and f1.id <> f1.Enabled
		LEFT OUTER JOIN Q
ORT_BACK_DB.dbo.Coupons cou WITH (NOLOCK) ON cou.Asset_ID = q.ID and cou.id <> cou.Enabled and cou.IsCanceled = 'n' and cou.BeginDate <= @todayInt and cou.EndDate > @todayInt
		--LEFT OUTER JOIN QORT_BACK_DB.dbo.Coupons couL WITH (NOLOCK) ON couL.Asset_ID
 = q.ID and q.id <> q.Enabled and coul.Description = cast(TRY_CAST(cou.Description as int) + 1 as varchar (12))
        outer apply ( (select top 1 couL.EndDate as EndDate from QORT_BACK_DB.dbo.Coupons couL 
				where couL.Asset_ID = q.ID and couL.id <> c
ouL.Enabled and coul.Description = cast(TRY_CAST(cou.Description as int) + 1 as varchar (12)))
			) as couLL
		outer apply ( (select resDL.StatusTXT as StatusTXTdl from ##resultDepoliteAssets resDL
				where isnull(resDL.ISIN,resDL.num)  = t.ISIN COLLATE 
Cyrillic_General_CI_AS)
			) as STXT
       
		
		OUTER APPLY (
            SELECT CASE
                WHEN t.ISIN IS NULL AND q.ISIN <> '' and q.IsTrading = 'y' THEN 'Asset not found in Bloomberg: ' + q.ISIN
                WHEN q.ISIN IS NULL AND t.ISI
N IS NOT NULL THEN 'Asset not found in Qort!!!' + t.ISIN
                ELSE ''
                    + IIF(t.Sanction <> q.IsInSanctionList, ', Sanction!!!', '')
                    + IIF(t.ViewName <> LEFT(q.ViewName, 30) AND t.ViewName <> '#N/A N/A', ',
 Ticker(ShortName)'+ cast(t.ViewName as varchar (12)) + '_Bloom/Qort_' + cast(q.ViewName as varchar(12)), '')
                    + IIF(t.Issue_date <> q.EmitDate AND t.Issue_date <> 0, ', Issuer_Date:' + cast(t.Issue_date as varchar (12)) + '_Bloom/Qort_
' + cast(q.EmitDate as varchar (12)), '')
                    + IIF(ISNULL(t.Nominal, 0) <> ISNULL(q.BaseValue, 0) AND ISNULL(t.Nominal, 0) <> 0, ', Nominal', '')
                    + IIF(t.Maturity_date <> q.CancelDate AND t.Maturity_date <> 0, ', Matur
ityDate:'+ cast(t.Maturity_date as varchar (12)) + '_Bloom/Qort_' + cast(q.CancelDate as varchar (12)), '')
					+ IIF((t.crncy <> isnull(iif(q.AssetClass_Const in(6), f1.Name, f.Name),'')) , ', Currency:'+ t.crncy+'_Bloom/Qort_'+ isnull(f.name,''), '')
	
				+ IIF((cast(isnull(t.cpn , isnull(cou.Procent,0)) as float) <> iif(isnull(cou.Procent,0) = 0, iif(CHARINDEX('/', cou.Description) >0 ,cast(SUBSTRING(cou.Description, CHARINDEX('/', cou.Description, CHARINDEX('/', cou.Description) + 1) + 1, LEN(cou.Des
cription)) as float),0), isnull(cou.Procent,0)) and (q.AssetClass_Const IN(6,7,9))) , ', Coupon%:'+cast(t.cpn AS varchar(16))+'_Q:'+cast(isnull(cou.Procent,0) as varchar(16)), '')
					+ IIF(
								(CAST(ISNULL(t.Nxt_Cpn_Dt, 0) AS VARCHAR(16)) <> CAST(I
SNULL(cou.EndDate, 0) AS VARCHAR(16))
								and CAST(ISNULL(t.Nxt_Cpn_Dt, 0) AS VARCHAR(16)) <> CAST(ISNULL(couLL.EndDate, 0) AS VARCHAR(16)))
								AND q.AssetClass_Const IN (6, 7, 9),
								', DateNextCoupon:' + CAST(t.Nxt_Cpn_Dt AS VARCHAR(16)) +
 '_Q:' + CAST(ISNULL(cou.EndDate, 0) AS VARCHAR(16)),
								''
							)
					 + IIF(t.Issuer_Bulk <> e.CBR_ShortName, ', ISSUE:' + ISNULL(t.Issuer_Bulk,'') + '_BLOOMBERG/QORT_'+ ISNULL(e.CBR_ShortName,'')  , '')
					 + iif(STXT.StatusTXTdl = 'OK', '', 
', DEPOLITE:' + STXT.StatusTXTdl) COLLATE Cyrillic_General_CI_AS
            END AS StatusTXT
        ) s1
        OUTER APPLY (
            SELECT CASE
                WHEN LEFT(s1.StatusTXT, 2) = ', ' THEN 'Mismatched: ' + RIGHT(StatusTXT, LEN(StatusTXT
) - 2)
                WHEN StatusTXT = '' THEN 'OK'
                ELSE StatusTXT
            END AS StatusTXT
        ) s2
        WHERE (q.Enabled <> q.id OR q.Enabled IS NULL) AND (q.AssetType_Const = 1 OR q.AssetType_Const IS NULL) AND q.Marking <> 
'XS1207654853';

        SELECT * FROM ##resultT ORDER BY ISINQ;
	--	return
        -- Отправка email с отчетом
        IF EXISTS (SELECT ISIN FROM ##resultT WHERE Result <> 'OK')
        BEGIN
            DECLARE @FilePath VARCHAR(255) = '\\192.168.14.22
\Exchange\QORT_Files\PRODUCTION\Reports';
            IF RIGHT(@FilePath, 1) <> '\' SET @FilePath = @FilePath + '\';
            DECLARE @SheetClient VARCHAR(32) = 'Assets';
            DECLARE @fileTemplate VARCHAR(512) = 'template_Asset_Check_Bloomberg.
xlsx';
            DECLARE @fileReport VARCHAR(512) = 'Asset_Check_Bloomberg_' + CONVERT(VARCHAR, GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '-') + '.xlsx';
            DECLARE @cmd VARCHAR(512);
            DECLARE @sql2 VARCH
AR(1024);

            -- Копирование шаблона отчета
            SET @cmd = 'copy "' + @FilePath + @fileTemplate + '" "' + @FilePath + @fileReport + '"';
            EXEC master.dbo.xp_cmdshell @cmd, no_output;

            -- Вставка данных в новый файл 
Excel
            SET @sql2 = 'INSERT INTO OPENROWSET (
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0; Database=' + @FilePath + @fileReport + '; HDR=YES;IMEX=0'',
                ''SELECT * FROM [' + @SheetClient + '$A1:Q10000
00]'')
                SELECT ISIN, ISINQ, Issue_date, Issue_dateQ, Ticker, AssetShortNameQ, Nominal, NominalQ,
                       Maturity_date, Maturity_dateQ, Issuer, IssuerQ, Sanction, SanctionQ, Result
                FROM ##resultT ORDER BY ISIN
Q';
            EXEC(@sql2);

            -- Подготовка сообщения для отправки по email
            DECLARE @NotifyMessage VARCHAR(MAX);
            DECLARE @NotifyTitle VARCHAR(1024) = NULL;
            SET @NotifyMessage = CAST((
                SELECT 
'//1\\' + ISNULL(CAST(tt.ISINQ AS VARCHAR), 'NOT FOUND!!!')
                   -- + '//2\\' + IIF(tt.ISIN IS NULL, 'NOT FOUND!!!', CAST(tt.ISIN AS VARCHAR))
                    --+ '//2\\' + ISNULL(CAST(tt.Issue_date AS VARCHAR), '----------')
           
         --+ '//2\\' + ISNULL(CAST(tt.Issue_dateQ AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(CAST(tt.Ticker AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(tt.AssetShortNameQ, '----------') COLLATE Cyrillic_General
_CI_AS
                    + '//2\\' + ISNULL(CAST(tt.Nominal AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(CAST(tt.NominalQ AS VARCHAR), '----------')
                   -- + '//2\\' + ISNULL(CAST(tt.Maturity_date AS VARCHAR), '------
----')
                    --+ '//2\\' + ISNULL(CAST(tt.Maturity_dateQ AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(CAST(tt.Issuer AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(CAST(tt.IssuerQ AS VARCHAR), '-------
---')
                    + '//2\\' + ISNULL(CAST(tt.Sanction AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(CAST(tt.SanctionQ AS VARCHAR), '----------')
                    + '//2\\' + isnull(tt.Result,'')
                FROM ##result
T tt
                WHERE tt.Result <> 'OK' AND tt.ISIN IS NOT NULL
                ORDER BY ISINQ ASC
                FOR XML PATH('')
            ) AS VARCHAR(MAX));

            SET @NotifyMessage = REPLACE(@NotifyMessage, '//1\\', '<tr><td>');
      
      SET @NotifyMessage = REPLACE(@NotifyMessage, '//2\\', '</td><td>');
            SET @NotifyMessage = REPLACE(@NotifyMessage, '//3\\', '</td></tr>');
            SET @NotifyMessage = REPLACE(@NotifyMessage, '//4\\', '</td><td ');
            SET @Not
ifyMessage = REPLACE(@NotifyMessage, '//5\\', '>');

            SET @NotifyMessage = '<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'
                                --+ '<td>ISIN(Bloomberg)</td>'
								+ '<td>ISIN(Qort)'
							
	--+ '</td><td>IssuerDate(Bloomberg)</td>'
								--+ '<td>IssuerDate(Qort)</td>'
								+ '<td>Ticker(Bloomberg)</td><td>AssetShortName(Qort)</td>'
								+ '<td>Nominal(Bloomberg)</td>'
								+ '<td>Nominal(Qort)</td>'
								--+ '<td>MaturityDate
(Bloomberg)</td>'
								--+ '<td>MaturityDate(Qort)</td>'
								+ '<td>Issuer(Bloomberg)</td>'
								+ '<td>Issuer(Qort)</td>'
								+ '<td>Sanction</td>'
								+ '<td>SanctionQ</td><td>Result</td></tr>'
                                + @Notify
Message + '</table>';

            SET @fileReport = @FilePath + @fileReport;
            SET @NotifyTitle = 'Alert!!! Assets for check';

            -- Отправка email
            EXEC msdb.dbo.sp_send_dbmail
                @profile_name = 'qort-sql-mai
l',
                @recipients = @NotifyEmail,
                @subject = @NotifyTitle,
                @BODY_FORMAT = 'HTML',
                @body = @NotifyMessage,
                @file_attachments = @fileReport;

            -- Удаление старых отчето
в
            SET @cmd = 'del "' + @FilePath + 'Asset_Check_Bloomberg_*.*"';
            EXEC master.dbo.xp_cmdshell @cmd, no_output;

            PRINT @NotifyTitle;
        END -- Конец блока отправки сообщения
    END TRY
    BEGIN CATCH
        -- Обр
аботка ошибок
        WHILE @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Message = 'ERROR: ' + ERROR_MESSAGE();
        INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001);
        PRINT @Message;
        SELECT @Mes
sage AS Result, 'red' AS ResultColor;
    END CATCH
END
