
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
        



		insert into QORT_BACK_TDB.dbo.Subaccs (ET_Const, IsProcessed, Code, IsQUIK, FirmCode, TradeCode, MarketFirmCode, RPTACTION_Flags, RPTACTION_Period_Flags/*, IsIgnoreRules*/)

		SELECT 4 as ET_Const, 1 as IsProcessed

				, sub.SubAccCode as code	

				, isnull(sub1.IsQuik, 'n') as IsQuik

				, iif(sub1.IsQuikC is null, '', 'T0,T2,Tx') as FirmCode

				, iif(sub1.IsQuikC is null, 'BLOCK', sub.SubAccCode) as TradeCode

				, iif(sub1.IsQuikC is null, '', 'ARMBROK') as MarketFirmCode

				, iif(sub1.IsQuikC is null, 0, 14) as RPTACTION_Flags

				, iif(sub1.IsQuikC is null, 0, 14) as RPTACTION_Period_Flags

				--, iif(sub1.IsQuikC is null, 'n', null) as IsIgnoreRules

				--, *



        FROM QORT_BACK_DB.dbo.Subaccs sub

		outer apply (select 'y' as IsQuik, sub1.IsQuik as IsQuikC, sub1.SubAccCode as SubAccCode from QORT_BACK_DB.dbo.Subaccs sub1

						WHERE  sub1.id = sub.id

							and sub.ACSTAT_Const = 5 --Active

						   and sub.Enabled = 0

						   and LEFT(sub.subAccCode,2) in ('AS', 'AR')

						   AND sub.SubAccCode NOT IN (
							SELECT su.SubAccCode
							FROM [QORT_BACK_DB].[dbo].[Partners] pa
							LEFT OUTER JOIN [QORT_BACK_DB].[dbo].[Subaccs] su
								ON su.OwnerFirm_ID = pa.Partner_ID 
								AND su.Enabled = 0
							WHERE pa
.PartnerGroup_ID IN (5))

						   ) as sub1

	
		where sub.Enabled = 0 and sub.IsAnalytic = 'n' 
		and (Iif(sub1.IsQuikC is null, 'n', 'y') <> sub.IsQUIK or Iif(sub1.IsQuikC is null, 'BLOCK', sub1.SubAccCode) <> sub.TradeCode or iif(sub1.IsQuikC is null, 0, 14) <> sub.RPTACTION_Flags or iif(sub1.IsQ
uikC is null, 0, 14) <> sub.RPTACTION_Period_Flags)-- or iif(sub1.IsQuikC is null, 'n', sub.IsIgnoreRules) <> sub.IsIgnoreRules)
		--and sub.SubAccCode = 'AS1388'
  


--RETURN
  --обновление справочника БП (всем признак не спамить, чтобы исключить случай
ную отправку сообщений


   

			insert into QORT_BACK_TDB.dbo.Firms (ET_Const, IsProcessed, BOCode, IsSpam)

			select 4 as ET_Const, 1 as IsProcessed, f.BOCode, 'y' IsSpam

			from QORT_BACK_DB.dbo.Firms f 

			where IsSpam = 'n' and Enabled = 0 
   




-- update PayAccs

--/*

					insert into QORT_BACK_TDB.dbo.PayAccs (ET_Const, IsProcessed, Subacc_Code, PutAccount_ExportCode, PayAccount_ExportCode)

					SELECT 2 as ET_Const, 1 as IsProcessed

					, su.SubAccCode as Subacc_Code

					--, acc.ExportCode as PutAccount_TradeCode

					, acc.ExportCode as PutAccount_ExportCode

					, 'Armbrok_Mn_Client' as PayAccount_ExportCode

				FROM QORT_BACK_DB.dbo.Subaccs su 



				CROSS JOIN (

				  SELECT * 

				  FROM QORT_BACK_DB.dbo.Accounts acc

				  WHERE acc.IsTrade = 'y' 

					AND acc.Enabled = 0

					AND acc.AssetType IN (1) -- Securities

					AND acc.TS_ID > 0

					AND acc.IsExportToNTO = 'y'

				) acc

				where su.ACSTAT_Const = 5 --Active

					   and su.Enabled = 0

					   and LEFT(su.subAccCode,6) in ('AS1105', 'AS1031','AS1509','AS1815') --and LEFT(su.subAccCode,2) in ('AS', 'AR') 

					   and su.IsQUIK = 'y'

						 AND NOT EXISTS (
					  SELECT 1 
					  FROM QORT_BACK_DB.dbo.PayAccs pa 
					  WHERE pa.Subacc_ID = su.id
						AND pa.PutAccount_ID = acc.ID
						AND pa.PayAccount_ID = 3 --'Armbrok_Mn_Client'
				  );

					--*/




   END TRY
    BEGIN CATCH

        -- Обработка исключений
        WHILE @@TRANCOUNT > 0 ROLLBACK TRAN
        SET @Message = 'ERROR: ' + ERROR_MESSAGE(); 
        -- Вставка сообщения об ошибке в таблицу uploadLogs
        INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, e
rrorLevel) VALUES (@Message, 1001);
        -- Возвращаем сообщение об ошибке
        SELECT @Message AS result, 'STATUS' AS defaultTask, 'red' AS color;
    END CATCH

END
