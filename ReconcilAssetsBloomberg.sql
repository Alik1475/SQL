
-- exec QORT_ARM_SUPPORT.dbo.ReconcilAssetsBloomberg

CREATE PROCEDURE [dbo].[ReconcilAssetsBloomberg]
AS
BEGIN
EXECUTE AS LOGIN = 'aleksandr.mironov';
    BEGIN TRY
        -- Инициализация переменных
        DECLARE @WaitCount INT;
        DECLARE @Mes
sage VARCHAR(1024);

        DECLARE @SendMail BIT = 0;
        DECLARE @FileName VARCHAR(128) = '\\192.168.14.22\Exchange\QORT_Files\Assets\Assets_Bloomberg.xlsx';

        DECLARE @NotifyEmail VARCHAR(1024) = 'depo@armbrok.am;backoffice@armbrok.am;qort@
armbrok.am'--aleksandr.mironov@armbrok.am;sona.nalbandyan@armbrok.am;armine.khachatryan@armbrok.am';
        DECLARE @Sheet1 VARCHAR(64) = 'Sheet1';
		DECLARE @todayDate DATE = GETDATE()
        DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 11
2) AS INT)
        DECLARE @sql VARCHAR(1024);

        -- Очистка временных таблиц, если они существуют
        IF OBJECT_ID('tempdb..##f', 'U') IS NOT NULL DROP TABLE ##f;
        IF OBJECT_ID('tempdb..#t', 'U') IS NOT NULL DROP TABLE #t;
        IF OBJ
ECT_ID('tempdb..##resultT', 'U') IS NOT NULL DROP TABLE ##resultT;

-- обновление справочника про бумаги с истекшим сроком погашения--------------	
				insert into QORT_BACK_TDB.dbo.Assets (ET_Const, IsProcessed, marking, IsTrading, IsDefault)  

				  SELECT DISTINCT 
						4 AS ET_Const,
						1 AS IsProcessed,
						Marking AS marking,
						IIF(POSSESS.result is NOT NULL, 'y', 'n') AS IsTrading,
						IIF(POSSESS.result is NOT NULL, 'y', null) as IsDefault
					FROM QORT_BACK_DB.dbo.assets a
	
				OUTER APPLY (SELECT TOP 1 1 AS Result
							FROM QORT_BACK_DB.dbo.Position po
							WHERE po.Asset_ID = a.id 
							  AND po.VolFree > 0) AS POSSESS		
					WHERE 
						a.AssetClass_Const IN (6) 
						AND a.CancelDate < @todayInt 
						and a.Canc
elDate <> 0 --для бумаг без даты погашения
						AND a.Enabled = 0
						AND (IIF(POSSESS.result is NOT NULL, 'y', 'n') <> a.IsTrading or IIF(POSSESS.result is NOT NULL, 'y', 'n') <> IsDefault)
					

				  --and ShortName = 'XS1634369067'
--return
---------------------запускаем обновление справочника DepoLite--------------
		exec QORT_ARM_SUPPORT.dbo.ReconcilAssetsDepoliteEmail
-------------------------------------------------------------------------


        -- Обработка и фильтрация данных из временной таблицы ##f в #t
        SELECT
              LEFT(Code, 12) AS ISIN
            , isnull(DX657,Security_NAME) AS ViewName
            , Par_Amt AS Nominal
            , Long_Company_Name_Realtime AS 
Issuer
            , IIF(Sectoral_Sanctioned_Security = 'y' OR OFAC_Sanctioned_Security = 'y' OR EU_SAnctioned_Security = 'y' OR UK_Sanctioned_Security = 'y', 'y', 'n') AS Sanction
            , TRY_CONVERT(VARCHAR(8), DATEADD(MINUTE, CAST(Issue_dt AS big
int)/60000, '1970-01-01'), 112) AS Issue_date
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
			 , DS306
			 , DS122
			 , DS674
			 , FUND_TYP
			 , DS004
				INTO #t
				FROM QORT_ARM_SUPPORT.dbo.BloombergData po
				WHERE (po.name is not null or po.name <> 'Not Found') and po.date  = @todayInt
		--and
 po.code = 'XS1936100483 CORP'

        SELECT * FROM #t;
		--RETURN
        -- Вставка данных в основную таблицу Assets
        INSERT INTO QORT_BACK_TDB.dbo.Assets (
           IsProcessed, ET_Const, ISIN, IsInSanctionList, shortName, Marking, Comment)

        
        SELECT DISTINCT
              1 AS IsProcessed
            , 4 AS ET_Const
            , CAST(t.ISIN AS VARCHAR(16)) AS ISIN
            , IIF(ass.IsInSanctionList = 'n' AND t.Sanction = 'y', t.Sanction, ass.IsInSanctionList) AS IsInSanct
ionList
            , ass.ShortName AS shortName
            , ass.Marking AS Marking
			, t.comment as COMMENT
        FROM #t t
        LEFT OUTER JOIN QORT_BACK_DB.dbo.Assets ass WITH (NOLOCK) ON ass.ISIN = t.ISIN
        WHERE (ass.Enabled <> ass.id A
ND ass.IsInSanctionList <> t.Sanction) OR (t.comment <> ass.Comment);

        -- Ожидание обновления данных
        SET @WaitCount = 1200;
        WHILE (@WaitCount > 0 AND EXISTS (SELECT TOP 1 1 FROM QORT_BACK_TDB.dbo.Assets t WITH (NOLOCK) WHERE t.IsPr
ocessed IN (1,2)))
        BEGIN
            WAITFOR DELAY '00:00:03';
            SET @WaitCount = @WaitCount - 1;
        END;
		--RETURN
        -- Обработка результатов сверки данных
        SELECT
              t.ISIN AS ISIN
            , t.ViewName
 AS Ticker
            , t.Nominal AS Nominal
            , t.Issuer AS Issuer
            , t.Sanction AS Sanction
            , t.Issue_date AS Issue_date
            , t.Maturity_date AS Maturity_date
            , q.isin AS ISINQ
            , q.ViewN
ame AS AssetShortNameQ
            , q.BaseValue AS NominalQ
            , e.FirmShortName AS IssuerQ
            , q.IsInSanctionList AS SanctionQ
            , q.EmitDate AS Issue_dateQ
            , q.CancelDate AS Maturity_dateQ
            , s2.Statu
sTXT AS Result
			, q.id as id
			, iif(q.AssetClass_Const in(6), f1.Name, f.Name)  curNAME -- валюту номинала из блумберг для бондов храним в бумаге, а для всех других под инструиентом
			--, t.Issuer_Bulk Issuer_Bulk
			, t.DS306 AS DS306
			, t.FUND_TY
P AS FUND_TYP
        INTO ##resultT
        FROM #t t
        FULL OUTER JOIN QORT_BACK_DB.dbo.Assets q ON t.ISIN = q.ISIN and q.Enabled <> q.id and q.IsTrading = 'y'
        LEFT OUTER JOIN QORT_BACK_DB.dbo.Firms e WITH (NOLOCK) ON e.id = q.EmitentFirm_
ID
		left outer join QORT_BACK_DB.dbo.Securities s ON s.Asset_ID = q.id and s.TSSection_ID in (154) and s.Enabled <> s.id
		LEFT OUTER JOIN QORT_BACK_DB.dbo.Assets f WITH (NOLOCK) ON f.id = s.CurrPriceAsset_ID and f.id <> f.Enabled
		LEFT OUTER JOIN QORT_
BACK_DB.dbo.Assets f1 WITH (NOLOCK) ON f1.id = q.BaseCurrencyAsset_ID and f1.id <> f1.Enabled
		LEFT OUTER JOIN QORT_BACK_DB.dbo.Coupons cou WITH (NOLOCK) ON cou.Asset_ID = q.ID and cou.id <> cou.Enabled and cou.IsCanceled = 'n' and cou.BeginDate <= @toda
yInt and cou.EndDate > @todayInt
		--LEFT OUTER JOIN QORT_BACK_DB.dbo.Coupons couL WITH (NOLOCK) ON couL.Asset_ID = q.ID and q.id <> q.Enabled and coul.Description = cast(TRY_CAST(cou.Description as int) + 1 as varchar (12))
        outer apply ( (select 
top 1 couL.EndDate as EndDate from QORT_BACK_DB.dbo.Coupons couL 
				where couL.Asset_ID = q.ID and couL.id <> couL.Enabled and coul.Description = cast(TRY_CAST(cou.Description as int) + 1 as varchar (12)))
			) as couLL
		outer apply ( (select resDL.Sta
tusTXT as StatusTXTdl from ##resultDepoliteAssets resDL
				where isnull(resDL.ISIN,resDL.num)  = t.ISIN COLLATE Cyrillic_General_CI_AS)
			) as STXT
       
		
		OUTER APPLY (
            SELECT CASE
                WHEN t.ISIN IS NULL AND q.ISIN <> '' a
nd q.IsTrading = 'y' THEN 'Asset not found in Bloomberg: ' + q.ISIN
                WHEN q.ISIN IS NULL AND t.ISIN IS NOT NULL THEN 'Asset not found in Qort!!!' + t.ISIN
                ELSE ''
                    + IIF(t.Sanction <> q.IsInSanctionList, '
, Sanction!!!', '')
                    + IIF(t.ViewName <> LEFT(q.ViewName, 30) AND t.ViewName <> '#N/A N/A', ', Ticker(ShortName)'+ cast(t.ViewName as varchar (12)) + '_Bloom/Qort_' + cast(q.ViewName as varchar(12)), '')
                    + IIF(t.Issu
e_date <> q.EmitDate AND t.Issue_date <> 0, ', Issuer_Date:' + cast(t.Issue_date as varchar (12)) + '_Bloom/Qort_' + cast(q.EmitDate as varchar (12)), '')
                    + IIF(ISNULL(t.Nominal, 0) <> ISNULL(q.BaseValue, 0) AND ISNULL(t.Nominal, 0) <>
 0, ', Nominal', '')
                    + IIF(t.Maturity_date <> q.CancelDate AND t.Maturity_date <> 0, ', MaturityDate:'+ cast(t.Maturity_date as varchar (12)) + '_Bloom/Qort_' + cast(q.CancelDate as varchar (12)), '')
					+ IIF((t.crncy <> isnull(iif(
q.AssetClass_Const in(6), f1.Name, f.Name),'')) , ', Currency:'+ t.crncy+'_Bloom/Qort_'+ isnull(f.name,''), '')
					+ IIF((cast(isnull(t.cpn , isnull(cou.Procent,0)) as float) <> iif(isnull(cou.Procent,0) = 0, iif(CHARINDEX('/', cou.Description) >0 ,cast
(SUBSTRING(cou.Description, CHARINDEX('/', cou.Description, CHARINDEX('/', cou.Description) + 1) + 1, LEN(cou.Description)) as float),0), isnull(cou.Procent,0)) and (q.AssetClass_Const IN(6,7,9))) , ', Coupon%:'+cast(t.cpn AS varchar(16))+'_Q:'+cast(isnul
l(cou.Procent,0) as varchar(16)), '')
					+ IIF(
								(CAST(ISNULL(t.Nxt_Cpn_Dt, 0) AS VARCHAR(16)) <> CAST(ISNULL(cou.EndDate, 0) AS VARCHAR(16))
								and CAST(ISNULL(t.Nxt_Cpn_Dt, 0) AS VARCHAR(16)) <> CAST(ISNULL(couLL.EndDate, 0) AS VARCHAR(16)
))
								AND q.AssetClass_Const IN (6, 7, 9),
								', DateNextCoupon:' + CAST(t.Nxt_Cpn_Dt AS VARCHAR(16)) + '_Q:' + CAST(ISNULL(cou.EndDate, 0) AS VARCHAR(16)),
								''
							)
					 + IIF(t.Issuer_Bulk <> e.CBR_ShortName, ', ISSUE:' + ISNULL(t.
Issuer_Bulk,'') + '_BLOOMBERG/QORT_'+ ISNULL(e.CBR_ShortName,'')  , '')
					 + CASE WHEN t.DS122 = 'Equity' AND (t.DS674 = 'Common Stock' OR t.DS674 = 'Preference') and q.AssetClass_Const not in (5,18,19,16,11)

							THEN t.DS122 + t.DS674 + '_Bloom/Qort_' + 'NOT_Equity'

							WHEN t.DS122 = 'Equity' AND t.DS674 = 'Mutual Fund' and FUND_TYP = 'ETF'  and q.AssetClass_Const not in (18)

							THEN t.FUND_TYP  + '_Bloom/Qort_' + 'NOT_ETF'

							WHEN t.DS122 = 'Equity' AND t.DS674 = 'Mutual Fund' and isnull(FUND_TYP,'') <> 'ETF'  and q.AssetClass_Const not in (11)

							THEN t.DS674  + '_Bloom/Qort_' + 'NOT_otherFund'

							WHEN t.DS306 = 'Y' and q.AssetClass_Const not in (19)

							THEN 'SFP'+ '_Bloom/Qort_' + 'NOT_SFP'	--Structured Finance Products (AC_STRUCT)

							WHEN (t.DS122 = 'Corp' OR t.DS122 = 'Govt') and q.AssetClass_Const not in (6)

							THEN t.DS122  + '_Bloom/Qort_' + 'NOT_Bond'

							WHEN t.DS122 = 'Equity' and t.DS674 = 'Depositary Receipt' and q.AssetClass_Const not IN (16)

							THEN t.DS674 + '_Bloom/Qort_' + 'NOT_ADR'--	RDR(ADR)(AC_RDR)

							ELSE ''

							END					

					 +  CASE WHEN t.DS122 = 'Equity' AND t.DS674 = 'Common Stock' and q.AssetSort_Const not in(1)

							THEN t.DS674 + '_Bloom/Qort_' + 'NOT_Common/Ordinary' -- 	Common/Ordinary shares(AS_SEC_BASIC)

							WHEN t.DS122 = 'Equity' AND t.DS674 = 'Preference' and q.AssetSort_Const not in(78)

							THEN t.DS674 + '_Bloom/Qort_' + 'NOT_Preferred' -- Preferred/Preference shares(AS_PREF)

							WHEN t.DS122 = 'Equity' AND t.DS674 = 'Depositary Receipt' and q.AssetSort_Const not in(32)

							THEN t.DS674  + 'Bloom/Qort_' + 'NOT_ADR' -- 		RDR(AS_RDR)

							WHEN t.DS122 = 'Equity' AND t.DS674 = 'Mutual Fund' and FUND_TYP = 'ETF' and q.AssetSort_Const not in (84)

							THEN t.FUND_TYP + '_Bloom/Qort_' + 'NOT_ETF' --ETF(AC_ETF)

							WHEN t.DS122 = 'Equity' AND t.DS674 = 'Mutual Fund' and FUND_TYP <> 'ETF' and q.AssetSort_Const not in (14)

							THEN t.DS674 + '_Bloom/Qort_' + 'NOT_otherFund' 

							WHEN t.DS306 = 'Y' and q.AssetSort_Const not in (85)

							THEN 'SFP'+ '_Bloom/Qort_' + 'NOT_SFP'  --	Structured Finance Products (AS_STRUCT)

							WHEN t.DS122 = 'Govt' and q.AssetSort_Const not in (3,11)

							THEN t.DS122 +  '_Bloom/Qort_' + 'NOT_GOVT' --	Federal loan bonds(AS_OFZ)

							WHEN t.DS122 = 'Corp'  and q.AssetSort_Const not in (6)

							THEN t.DS122 +  '_Bloom/Qort_' + 'NOT_CORP' --	Corporate bonds(AS_CORP)

							ELSE ''

							END						 
					 + iif(STXT.StatusTXTdl = 'OK', '', ', DEPOLITE:' + STXT.StatusTXTdl) COLLATE Cyrillic_General_CI_AS
            END AS StatusTXT
        ) s1
        OUTER APPLY (
            SELECT CASE
                WHEN LEFT(s1.StatusTXT, 2) 
= ', ' THEN 'Mismatched: ' + RIGHT(StatusTXT, LEN(StatusTXT) - 2)
                WHEN StatusTXT = '' THEN 'OK'
                ELSE StatusTXT
            END AS StatusTXT
        ) s2
        WHERE (q.Enabled <> q.id OR q.Enabled IS NULL) AND (q.AssetTyp
e_Const = 1 OR q.AssetType_Const IS NULL) AND q.Marking <> 'XS1207654853';

        SELECT * FROM ##resultT ORDER BY ISINQ;
		--return
        -- Отправка email с отчетом
        IF EXISTS (SELECT ISIN FROM ##resultT WHERE Result <> 'OK')
        BEGIN
  
          DECLARE @FilePath VARCHAR(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Reports';
            IF RIGHT(@FilePath, 1) <> '\' SET @FilePath = @FilePath + '\';
            DECLARE @SheetClient VARCHAR(32) = 'Assets';
            DECLARE @f
ileTemplate VARCHAR(512) = 'template_Asset_Check_Bloomberg.xlsx';
            DECLARE @fileReport VARCHAR(512) = 'Asset_Check_Bloomberg_' + CONVERT(VARCHAR, GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '-') + '.xlsx';
           
 DECLARE @cmd VARCHAR(512);
            DECLARE @sql2 VARCHAR(1024);

            -- Копирование шаблона отчета
            SET @cmd = 'copy "' + @FilePath + @fileTemplate + '" "' + @FilePath + @fileReport + '"';
            EXEC master.dbo.xp_cmdshell @c
md, no_output;

            -- Вставка данных в новый файл Excel
            SET @sql2 = 'INSERT INTO OPENROWSET (
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0; Database=' + @FilePath + @fileReport + '; HDR=YES;IMEX=0'',
    
            ''SELECT * FROM [' + @SheetClient + '$A1:Q1000000]'')
                SELECT ISIN, ISINQ, Issue_date, Issue_dateQ, Ticker, AssetShortNameQ, Nominal, NominalQ,
                       Maturity_date, Maturity_dateQ, Issuer, IssuerQ, Sanction, San
ctionQ, Result
                FROM ##resultT ORDER BY ISINQ';
            EXEC(@sql2);

            -- Подготовка сообщения для отправки по email
            DECLARE @NotifyMessage VARCHAR(MAX);
            DECLARE @NotifyTitle VARCHAR(1024) = NULL;
    
        SET @NotifyMessage = CAST((
                SELECT '//1\\' + ISNULL(CAST(tt.ISINQ AS VARCHAR), 'NOT FOUND!!!')
                   -- + '//2\\' + IIF(tt.ISIN IS NULL, 'NOT FOUND!!!', CAST(tt.ISIN AS VARCHAR))
                    --+ '//2\\' + ISNUL
L(CAST(tt.Issue_date AS VARCHAR), '----------')
                    --+ '//2\\' + ISNULL(CAST(tt.Issue_dateQ AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(CAST(tt.Ticker AS VARCHAR), '----------')
                    + '//2\\' + ISNULL
(tt.AssetShortNameQ, '----------') COLLATE Cyrillic_General_CI_AS
                    + '//2\\' + ISNULL(CAST(tt.Nominal AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(CAST(tt.NominalQ AS VARCHAR), '----------')
                   -- + 
'//2\\' + ISNULL(CAST(tt.Maturity_date AS VARCHAR), '----------')
                    --+ '//2\\' + ISNULL(CAST(tt.Maturity_dateQ AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(CAST(tt.Issuer AS VARCHAR), '----------')
                 
   + '//2\\' + ISNULL(CAST(tt.IssuerQ AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(CAST(tt.Sanction AS VARCHAR), '----------')
                    + '//2\\' + ISNULL(CAST(tt.SanctionQ AS VARCHAR), '----------')
                    + '
//2\\' + isnull(tt.Result,'')
                FROM ##resultT tt
                WHERE tt.Result <> 'OK' AND tt.ISIN IS NOT NULL
                ORDER BY ISINQ ASC
                FOR XML PATH('')
            ) AS VARCHAR(MAX));

            SET @NotifyMes
sage = REPLACE(@NotifyMessage, '//1\\', '<tr><td>');
            SET @NotifyMessage = REPLACE(@NotifyMessage, '//2\\', '</td><td>');
            SET @NotifyMessage = REPLACE(@NotifyMessage, '//3\\', '</td></tr>');
            SET @NotifyMessage = REPLACE(
@NotifyMessage, '//4\\', '</td><td ');
            SET @NotifyMessage = REPLACE(@NotifyMessage, '//5\\', '>');

            SET @NotifyMessage = '<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'
                                --+ '<
td>ISIN(Bloomberg)</td>'
								+ '<td>ISIN(Qort)'
								--+ '</td><td>IssuerDate(Bloomberg)</td>'
								--+ '<td>IssuerDate(Qort)</td>'
								+ '<td>Ticker(Bloomberg)</td><td>AssetShortName(Qort)</td>'
								+ '<td>Nominal(Bloomberg)</td>'
					
			+ '<td>Nominal(Qort)</td>'
								--+ '<td>MaturityDate(Bloomberg)</td>'
								--+ '<td>MaturityDate(Qort)</td>'
								+ '<td>Issuer(Bloomberg)</td>'
								+ '<td>Issuer(Qort)</td>'
								+ '<td>Sanction</td>'
								+ '<td>SanctionQ</td><td>
Result</td></tr>'
                                + @NotifyMessage + '</table>';

            SET @fileReport = @FilePath + @fileReport;
            SET @NotifyTitle = 'Alert!!! Assets for check';

            -- Отправка email
            EXEC msdb.dbo.s
p_send_dbmail
                @profile_name = 'qort-sql-mail',
                @recipients = @NotifyEmail,
                @subject = @NotifyTitle,
                @BODY_FORMAT = 'HTML',
                @body = @NotifyMessage,
                @file_attach
ments = @fileReport;

            -- Удаление старых отчетов
            SET @cmd = 'del "' + @FilePath + 'Asset_Check_Bloomberg_*.*"';
            EXEC master.dbo.xp_cmdshell @cmd, no_output;

            PRINT @NotifyTitle;
        END -- Конец блока от
правки сообщения
    END TRY
    BEGIN CATCH
        -- Обработка ошибок
        WHILE @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Message = 'ERROR: ' + ERROR_MESSAGE();
        INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@
Message, 1001);
        PRINT @Message;
        SELECT @Message AS Result, 'red' AS ResultColor;
    END CATCH
END
