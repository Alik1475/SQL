







-- exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmationsList @OrdersList = '10, 11'



CREATE PROCEDURE [dbo].[exportOrderConfirmationsList]

	@OrdersList varchar(8000)

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



		while @OrderId is not null begin

			set @OrderId = null

			select top 1 @id = t.id, @OrderId = t.orderId

			from @orders t

			where t.id > @id

			order by 1

			if @OrderId is null break

			print @OrderId



			select @resultStatus = null, @resultPath = null, @resultColor = null, @resultDateTime = null

			--insert into @res (orderId, resultStatus, resultPath, resultColor, resultDateTime)

			exec QORT_ARM_SUPPORT.dbo.exportOrderConfirmation @OrderId = @OrderId

				, @resultStatus = @resultStatus out

				, @resultPath = @resultPath out

				, @resultColor = @resultColor out

				, @resultDateTime = @resultDateTime out



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

