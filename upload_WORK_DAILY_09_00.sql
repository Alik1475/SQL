

-- exec QORT_ARM_SUPPORT.dbo.upload_WORK_DAILY_09_00

CREATE PROCEDURE [dbo].[upload_WORK_DAILY_09_00]

AS

BEGIN

	BEGIN TRY

		DECLARE @IP VARCHAR(16) = '192.168.13.80'

		DECLARE @Message VARCHAR(1024)

		DECLARE @todayDate DATE = GETDATE()

		DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)



		EXEC QORT_ARM_SUPPORT.dbo.UpdateTokensFromAPI -- обновление токенов Райффайзен

			--exec QORT_ARM_SUPPORT.dbo.UpdateCouponForREPO -- обнуление ставки и объема купоня для заведения пролонгации РЕПО

			--exec QORT_ARM_SUPPORT.dbo.DepoReconcil @sendmail = 1 -- сверка клиентских позиций с отправкой уведомления

			--exec QORT_ARM_SUPPORT.dbo.CheckRepoFor7daysCoupon @sendmail = 1 -- уведомление за 7 дней до выплаты купонов по открытым сделкам РЕПО

			--exec QORT_ARM_SUPPORT.dbo.AssetsRedemptionEmail @SendMail = 1 -- уведомление о купонах сегодня

			--exec QORT_ARM_SUPPORT.dbo.SalesUpdate -- обновление справочника "сейлзы для клиента"(аналитические субсчета для разграничения прав)

			------------------------------------------------------------------------------------------------------------------------------



		EXEC QORT_ARM_SUPPORT..BDP_FlaskRequest @IP

			,@IsinCode = 'US0378331005 EQUITY'



		IF (

				isnull((

						SELECT TOP 1 found

						FROM QORT_ARM_SUPPORT.dbo.BloombergData

						WHERE DATE = @todayInt

							AND Code = 'US0378331005 EQUITY'

						), 0) = 1

				)

		BEGIN

			EXEC QORT_ARM_SUPPORT..BDP_FlaskRequest @IP

				,@IsinCode = NULL -- обновление QORT_arm_sUPPORT.DBO.BloombergData данными из блумберг(справочник ценных бумаг)

		END

		ELSE

			PRINT 'dont connect server'

				---------------------------------------------------------------------------------------------------------------------------

	END TRY



	BEGIN CATCH

		SET @Message = 'ERROR: ' + ERROR_MESSAGE();



		INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs (

			logMessage

			,errorLevel

			)

		VALUES (

			@message

			,1001

			);



		PRINT @Message

	END CATCH

END

