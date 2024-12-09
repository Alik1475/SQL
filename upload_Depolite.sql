

--exec QORT_ARM_SUPPORT.dbo.upload_Depolite @QueryDate = '20241202'



CREATE PROCEDURE [dbo].[upload_Depolite]

	@QueryDate datetime 

AS

 BEGIN

 EXECUTE AS LOGIN = 'aleksandr.mironov'

	SET NOCOUNT ON



	begin try

-- Создаём временную таблицу для данных



	DECLARE @todayDate DATE = GETDATE()

	DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)

	declare @QueryDateInt int = cast(convert(varchar, @QueryDate, 112) as int)

	declare @Message varchar(1024)

CREATE TABLE #TempResult (

    NAME_A NVARCHAR(MAX),

    COUNTRY NVARCHAR(MAX),

    RESIDENT NVARCHAR(MAX),

    BIRTHDAY INT,

    DOCUMENT NVARCHAR(MAX),

    ACTYPE NVARCHAR(MAX),

    ACCOUNT NVARCHAR(MAX),

    PERSON NVARCHAR(MAX),

    TYPE NVARCHAR(MAX),

    NUM NVARCHAR(MAX),

    OWNERNAME NVARCHAR(MAX),

    BAL DECIMAL(18, 2),

    BALMINAMNT DECIMAL(18, 2),

    SCUR NVARCHAR(MAX),

    MINAMNT DECIMAL(18, 2),

    PAHPANMANVAYR1 NVARCHAR(MAX),

    PAHPANMANVAYR2 NVARCHAR(MAX),

    PAHPANMANVAYR3 NVARCHAR(MAX),

    PAHPANMANVAYR4 NVARCHAR(MAX)

);



-- Вставляем данные из процедуры во временную таблицу

INSERT INTO #TempResult

EXEC [192.168.13.8].Depositary.[dbo].[Rp_cur5992] '2', @QueryDate, '', '-1';



-- Удаляем строки с такой же датой QUERY_DATE

DELETE FROM QORT_ARM_SUPPORT..Rp_cur5992_Result

WHERE QUERY_DATE = @QueryDate;

-- Вставляем данные из временной таблицы в основную таблицу



INSERT INTO QORT_ARM_SUPPORT..Rp_cur5992_Result (

    NAME_A, COUNTRY, RESIDENT, BIRTHDAY, DOCUMENT, ACTYPE, ACCOUNT, PERSON, TYPE, NUM, OWNERNAME, BAL, BALMINAMNT, SCUR, MINAMNT, 

    PAHPANMANVAYR1, PAHPANMANVAYR2, PAHPANMANVAYR3, PAHPANMANVAYR4, QUERY_DATE

)

SELECT *, @QueryDate

FROM #TempResult;



-- Удаляем временную таблицу

DROP TABLE #TempResult;



-- Делаем выборку из таблицы

SELECT * FROM QORT_ARM_SUPPORT..Rp_cur5992_Result ;



select row_number() over(order by t.account) rn

				, @QueryDateInt as Checkdate

				, t.account Depocount

				, t.num ISIN

				, cast(t.bal as float) Qty

				, CASE  t.PAHPANMANVAYR1

					WHEN 'BTA' THEN 'ARMBR_DEPO_BTA'

					WHEN 'GPP' THEN 'ARMBR_DEPO_GPP'

					WHEN 'Halyk Finance' THEN 'ARMBR_DEPO_HFN'

					WHEN 'Method Investments and Advisory LTD' THEN 'ARMBR_DEPO_MTD'

					WHEN 'RONIN EUROPE LIMITED' THEN 'ARMBR_DEPO_RON'

					WHEN 'Freedom Finance' THEN 'ARMBR_DEPO_FDF'

					WHEN 'Astana International Exchange' THEN 'ARMBR_DEPO_AIX'

					WHEN 'GTN Technologies (Private) Limited' THEN 'ARMBR_DEPO_GTN'

					WHEN 'MADA CAPITAL' THEN 'ARMBR_DEPO_MAD'

					WHEN 'MAREX PRIME SERVICES LIMITED' THEN 'ARMBR_DEPO_MAREX'

					ELSE 

					iif(left(t.account,14) = '42000116594323', 'GX2IN_ARMBR_DEPO_'+cast(right(t.account,4) as varchar(128)),

					'ARMBR_DEPO') END Depository

					

				, isnull(da.Code,isnull(cast(t.account+'_'+isnull(Cl.NAME_Translate,'ClientNameNotFound') as varchar),'ClientNameNotFound')) code

				, isnull(a.ShortName,'AssetNoQort'+t.num) Asset_ShortName

				 , @TodayInt date -- дата всегда текущая, иначе сверка в Корт не отработает. Сверяет только с данными, где текущая дата.



			into #comms 

			from QORT_ARM_SUPPORT..Rp_cur5992_Result t

			left join QORT_BACK_DB..FirmDEPOAccs  da on  da.DEPODivisionCode = t.account

			left outer join QORT_BACK_DB..Assets a on a.isin = t.num and a.IsTrading = 'y'

			left outer join QORT_ARM_SUPPORT..ClientNameTranslate cl on cl.account = t.account

			where t.QUERY_DATE = @QueryDate

			

			select * from #comms 



			DELETE from QORT_BACK_TDB..CheckPositions -- удаляем значения перед загрузкой новых.

			where CheckDate = cast(@QueryDate as int) and InfoSource = 'DEPOLITE' 

			or (Date = @TodayInt and InfoSource = 'DEPOLITE')



			if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms

			

			--/*

			INSERT INTO QORT_BACK_TDB..CheckPositions (
							Subacc_Code, 
							Account_ExportCode, 
							Asset_ShortName, 
							VolFree, 
							Date, 
							InfoSource, 
							CheckDate, 
							IsAnalytic, 
							PosDate
						)
						--*/
			SELECT 

							code, 
							Depository, 
							Asset_ShortName, 
							SUM(Qty) AS Qty, -- Суммируем значения Qty
							date, 
							'DEPOLITE' AS INFOSOURCE, 
							checkdate, 
							'n' AS IsAnalytic, 
							checkdate AS PosDate
						FROM 
							#com
ms
							where Code not in ('AS1109')-- временно убрал счет Алора, чтобы не дублировался. К двум AS привязан один депо
						GROUP BY 
							checkdate, 
							ISIN, 
							Depository, 
							code, 
							Asset_ShortName, 
							date;

		

	



	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		select @Message result, 'STATUS' defaultTask, 'red' color

	end catch

	REVERT;

END;

