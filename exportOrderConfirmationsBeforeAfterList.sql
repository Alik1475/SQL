









-- exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmationsBeforeAfterList @OrdersList = '5057, 5061', @BeforeAfter = 1

-- exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmationsBeforeAfterList @OrdersList = '5057, 5061', @BeforeAfter = 2

-- exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmationsBeforeAfterList @OrdersList = '5057, 5061, 5079, 4139', @BeforeAfter = 2



CREATE PROCEDURE [dbo].[exportOrderConfirmationsBeforeAfterList]

	@OrdersList varchar(8000)

	, @BeforeAfter tinyint -- 1 - before, 2 - after

AS

BEGIN



	SET NOCOUNT ON



	begin try



		declare @resultStatus varchar(1024)

		declare @resultPath varchar(255)

		declare @resultColor varchar(32)

		declare @resultDateTime varchar(32)



		declare @res table(Num int identity, OrderId bigint, resultStatus varchar(1024), resultPath varchar(255), resultColor varchar(32), resultDateTime varchar(32))



		declare @Message varchar(1024)



		declare @orders table(id int identity, orderId bigint)



		insert into @orders(orderId)

		select val

		from QORT_ARM_SUPPORT.dbo.fnt_ParseString_Num(replace(@OrdersList, ' ', ','), ',')

		where TRY_CONVERT(bigint, val) > 0



		declare @id int = 0

		declare @OrderId bigint = 0

		declare @IsRepo bit = 0





		while @OrderId is not null begin

			set @OrderId = null

			select top 1 @id = t.id, @OrderId = t.orderId

			from @orders t

			where t.id > @id

			order by 1

			if @OrderId is null break

			print @OrderId



			set @IsRepo = 0



			select top 1 @IsRepo = iif(ti.RepoDate2 > 0 or ti.RepoRate > 0 or ti.RepoTerm > 0, 1, 0)

			from QORT_BACK_DB.dbo.TradeInstrs ti with (nolock)

			where ti.id = @OrderId



			select @resultStatus = null, @resultPath = null, @resultColor = null, @resultDateTime = null

			--insert into @res (orderId, resultStatus, resultPath, resultColor, resultDateTime)



			if @IsRepo = 1 begin

				exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmation @OrderId = @OrderId

					, @resultStatus = @resultStatus out

					, @resultPath = @resultPath out

					, @resultColor = @resultColor out

					, @resultDateTime = @resultDateTime out

					, @repoStep = 1

			end else begin

				exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmationBeforeAfter @OrderId = @OrderId

					, @BeforeAfter = @BeforeAfter

					, @resultStatus = @resultStatus out

					, @resultPath = @resultPath out

					, @resultColor = @resultColor out

					, @resultDateTime = @resultDateTime out

			end



			insert into @res (orderId, resultStatus, resultPath, resultColor, resultDateTime)

			select @OrderId, @resultStatus, @resultPath, @resultColor, @resultDateTime

		end



	end try

	begin catch

		--while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		--insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		insert into @res(resultStatus, resultColor)

		select @Message result, 'red' color

	end catch



	select * 

	from @res

	order by 1

END

