
-- exec QORT_ARM_SUPPORT..CodeAssets

CREATE PROCEDURE [dbo].[CodeAssets]
AS
BEGIN
    BEGIN TRY
        DECLARE @Message VARCHAR(1024) -- для уведомлений об ошибках
        DECLARE @todayDate DATE = GETDATE()
        DECLARE @todayInt INT = CAST(CONVERT
(VARCHAR, @todayDate, 112) AS INT)

        -- Удаляем временные таблицы, если они существуют
        IF OBJECT_ID('tempdb..##CodeAssets', 'U') IS NOT NULL DROP TABLE ##CodeAssets
        IF OBJECT_ID('tempdb..#t1', 'U') IS NOT NULL DROP TABLE #t1

      
  -- Основной запрос для выборки данных
        SELECT ASS.ID ASSID, ASS.shortname,
		CASE WHEN ass.AssetClass_Const IN (6,7,9,19)
		then cast(ass.ISIN as varchar(32))+' '+'CORP'
		WHEN ass.AssetClass_Const IN (12)
		then cast(ass.ISIN as varchar(32))+' '
+'INDEX'
		else cast(ass.ISIN as varchar(32))+' '+'EQUITY' 
		END code
		into ##CodeAssets
		from QORT_BACK_DB.dbo.Assets ass
		OUTER APPLY (

			SELECT TOP 1 *

			FROM QORT_BACK_DB.dbo.AssetsHist ah

			WHERE ah.Founder_ID = ass.ID

			  AND ah.user_modified = 9 and isnull(ass.EmitentFirm_ID, -1)  < 0

			ORDER BY ah.Founder_Date DESC, ah.Founder_Time DESC

		) AS ah
		where ass.Enabled = 0
			and ass.AssetType_Const in (1,4) -- 	Securities (AT_SEC), Indices AT_IDX
			and (ass.CancelDate >= @todayInt or ass.CancelDate = 0)
			and ass.IsTrading = 'y'
			and ass.PricingTSSection_ID in (154, (-1)) -- 'OTC_Secur
ities'

           -- and LEFT(ASS.ISIN,2) = 'AM'
		 --  AND ass.AssetClass_Const = 19
			DECLARE @JsonResult NVARCHAR(MAX);



    

	SELECT *

    FROM ##CodeAssets

 
    END TRY
    BEGIN CATCH
        WHILE @@TRANCOUNT > 0 ROLLBACK TRAN
        SET @Message = 'ERROR: ' + ERROR_MESSAGE()
        INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001)
        PRINT @Message
       
 SELECT @Message AS Result, 'red' AS ResultColor
    END CATCH
END
