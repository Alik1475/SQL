



-- exec QORT_ARM_SUPPORT.dbo.upload_WORK_DAILY_09_00

CREATE PROCEDURE [dbo].[upload_WORK_DAILY_09_00]



AS



BEGIN



	begin try

		DECLARE @IP VARCHAR(16) = '192.168.13.80'

		declare @Message varchar(1024)

		DECLARE @todayDate DATE = GETDATE()
        DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)


		exec QORT_ARM_SUPPORT.dbo.UpdateTokensFromAPI -- обновление токенов Райффайзен

		--exec QORT_ARM_SUPPORT.dbo.UpdateCouponForREPO -- обнуление ставки и объема купоня для заведения пролонгации РЕПО

		--exec QORT_ARM_SUPPORT.dbo.DepoReconcil @sendmail = 1 -- сверка клиентских позиций с отправкой уведомления

		--exec QORT_ARM_SUPPORT.dbo.CheckRepoFor7daysCoupon @sendmail = 1 -- уведомление за 7 дней до выплаты купонов по открытым сделкам РЕПО

		--exec QORT_ARM_SUPPORT.dbo.AssetsRedemptionEmail @SendMail = 1 -- уведомление о купонах сегодня

		--exec QORT_ARM_SUPPORT.dbo.SalesUpdate -- обновление справочника "сейлзы для клиента"(аналитические субсчета для разграничения прав)

		------------------------------------------------------------------------------------------------------------------------------

		exec QORT_ARM_SUPPORT..BDP_FlaskRequest @IP, @IsinCode = 'US0378331005 EQUITY'
		if (isnull((select top 1 found from QORT_ARM_SUPPORT.dbo.BloombergData where Date = @todayInt and Code = 'US0378331005 EQUITY'),0) = 1) begin

		exec QORT_ARM_SUPPORT..BDP_FlaskRequest @IP, @IsinCode = NULL-- обновление QORT_arm_sUPPORT.DBO.BloombergData данными из блумберг(справочник ценных бумаг)

		end

		else print 'dont connect server'

		---------------------------------------------------------------------------------------------------------------------------



	end try

	begin catch

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END

