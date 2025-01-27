﻿
-- exec QORT_ARM_SUPPORT.dbo.UPDATE_SUBACC_forQUIK

CREATE PROCEDURE [dbo].[UPDATE_SUBACC_forQUIK]
  
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- Объявление переменных
        
        DECLARE @todayDate DATE = GETDATE()
        DECLARE @toda
yInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)
        declare @Message varchar(1024)
        



		insert into QORT_BACK_TDB.dbo.Subaccs (ET_Const, IsProcessed, Code, IsQUIK, FirmCode, TradeCode, MarketFirmCode, RPTACTION_Flags, RPTACTION_Period_Flags, IsIgnoreRules)

		SELECT 4 as ET_Const, 1 as IsProcessed

				, sub.SubAccCode as code	

				, isnull(sub1.IsQuik, 'n') as IsQuik

				, iif(sub1.IsQuikC is null, '', 'T0,T2,Tx') as FirmCode

				, iif(sub1.IsQuikC is null, '', sub.SubAccCode) as TradeCode

				, iif(sub1.IsQuikC is null, '', 'ARMBROK') as MarketFirmCode

				, iif(sub1.IsQuikC is null, 0, null) as RPTACTION_Flags

				, iif(sub1.IsQuikC is null, 0, null) as RPTACTION_Period_Flags

				, iif(sub1.IsQuikC is null, 'n', null) as IsIgnoreRules

				--, *



        FROM QORT_BACK_DB.dbo.Subaccs sub

		outer apply (select 'y' as IsQuik, sub1.IsQuik as IsQuikC from QORT_BACK_DB.dbo.Subaccs sub1

						WHERE  sub1.id = sub.id

							and sub.ACSTAT_Const = 5 --Active

						   and sub.Enabled = 0

						   and LEFT(sub.subAccCode,2) in ('AS', 'AR')) as sub1

	
		where sub.Enabled = 0 and sub.IsAnalytic = 'n' 
		and (Iif(sub1.IsQuikC is null, 'n', 'y') <> sub.IsQUIK or iif(sub1.IsQuikC is null, 0, sub.RPTACTION_Flags) <> sub.RPTACTION_Flags or iif(sub1.IsQuikC is null, 0, sub.RPTACTION_Period_Flags) <> sub.RPT
ACTION_Period_Flags or iif(sub1.IsQuikC is null, 'n', sub.IsIgnoreRules) <> sub.IsIgnoreRules)
		--and sub.SubAccCode = 'AS1388'

  --обновление справочника БП (всем признак не спамить, чтобы исключить случайную отправку сообщений


   

			insert into QORT_BACK_TDB.dbo.Firms (ET_Const, IsProcessed, BOCode, IsSpam)

			select 4 as ET_Const, 1 as IsProcessed, f.BOCode, 'y' IsSpam

			from QORT_BACK_DB.dbo.Firms f 

			where IsSpam = 'n' and Enabled = 0 
   




-- Формирование и добавление логина для АПП



		/*		--	insert into QORT_BACK_TDB.dbo.Firms (ET_Const, IsProcessed, BOCode, GenName)

					select 4 as ET_Const, 1 as IsProcessed, f.BOCode, QORT_ARM_SUPPORT.dbo.fGetFirstEmail(f.Email) GenName

					from QORT_BACK_DB.dbo.Firms f 

					CROSS APPLY (
								SELECT FlagName
								FROM [dbo].[FTGetIncludedFlags](f.FT_Flags)
							) IncludedFlags

					where f.GenName = ''

					and Enabled = 0 

					and IncludedFlags.FlagName = 'FT_CLIENT'
					and f.STAT_Const in (5) -- Active;

					*/




   END TRY
    BEGIN CATCH
        -- Обработка исключений
        WHILE @@TRANCOUNT > 0 ROLLBACK TRAN
        SET @Message = 'ERROR: ' + ERROR_MESSAGE(); 

        -- Вставка сообщения об ошибке в таблицу uploadLogs
        INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001);
        -- Возвращаем сообщение об ошибке
        SELECT @Message AS result, 'STATUS' AS defau
ltTask, 'red' AS color;
    END CATCH

END
