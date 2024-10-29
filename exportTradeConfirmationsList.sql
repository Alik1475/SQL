





-- exec QORT_ARM_SUPPORT_TEST.dbo.exportTradeConfirmationsList @TradesList = '6916, 6917, 6918, 6919, 6920, 111, 22222'

-- exec QORT_ARM_SUPPORT_TEST.dbo.exportTradeConfirmationsList @TradesList = '6916, 6917, 11111'



CREATE PROCEDURE [dbo].[exportTradeConfirmationsList]

	@TradesList varchar(8000)

AS

BEGIN



	SET NOCOUNT ON



	begin try



		declare @resultStatus varchar(1024)

		declare @resultPath varchar(255)

		declare @resultColor varchar(32)

		declare @resultDateTime varchar(32)



		declare @res table(Num int identity, TradeId bigint, resultStatus varchar(1024), resultPath varchar(255), resultColor varchar(32), resultDateTime varchar(32))



		declare @Message varchar(1024)



		declare @trades table(id int identity, tradeId bigint)



		insert into @trades(tradeId)

		select val

		from QORT_ARM_SUPPORT_TEST.dbo.fnt_ParseString_Num(replace(@TradesList, ' ', ','), ',')

		where TRY_CONVERT(bigint, val) > 0



		declare @id int = 0

		declare @TradeId bigint = 0



		while @TradeId is not null begin

			set @TradeId = null

			select top 1 @id = t.id, @TradeId = t.tradeId

			from @Trades t

			where t.id > @id

			order by 1

			if @TradeId is null break

			print @TradeId



			select @resultStatus = null, @resultPath = null, @resultColor = null, @resultDateTime = null

			--insert into @res (TradeId, resultStatus, resultPath, resultColor, resultDateTime)

			exec QORT_ARM_SUPPORT_TEST.dbo.exportTradeConfirmation @TradeId = @TradeId

				, @resultStatus = @resultStatus out

				, @resultPath = @resultPath out

				, @resultColor = @resultColor out

				, @resultDateTime = @resultDateTime out



			insert into @res (TradeId, resultStatus, resultPath, resultColor, resultDateTime)

			select @TradeId, @resultStatus, @resultPath, @resultColor, @resultDateTime

		end



	end try

	begin catch

		--while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		--insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		insert into @res(resultStatus, resultColor)

		select @Message result, 'red' color

	end catch



	select * from @res

END

