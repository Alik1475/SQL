





CREATE PROCEDURE [dbo].[tasksProcess]

AS

BEGIN



	SET NOCOUNT ON





	declare @Message varchar(1024)

	declare @rows int

	declare @aid int = 0

	declare @WaitCount int



	declare @taskId int

	declare @taskName varchar(32)

	declare @IsProcessed tinyint

	declare @IsProcessedTxt varchar(128)



	declare @endTime datetime = getdate() + 29.9 / 1440

	--declare @endTime datetime = getdate() + 0.1 / 86400



	while getdate() < @endTime begin



		begin try



			select @taskId = null



			select top 1 @taskId = t.taskId, @taskName = t.taskNAme

			from QORT_ARM_SUPPORT_TEST.dbo.tasks t

			where t.IsProcessed = 1

			order by 1 desc



			if @taskId is not null begin

				select @IsProcessed = 3, @IsProcessedTxt = 'done'



				if @taskName = 'upload Deals' begin

					exec QORT_ARM_SUPPORT_TEST.dbo.upload_Deals

					--select @IsProcessedTxt = 'deals done'

				end else if @taskName = 'upload NTTSs' begin

					exec QORT_ARM_SUPPORT_TEST.dbo.upload_NTTs

					--select @IsProcessedTxt = 'ntts done'

				end else if @taskName = 'upload CBA CrossRates' begin

					exec QORT_ARM_SUPPORT_TEST.dbo.upload_CrossRates_CBA

					--select @IsProcessedTxt = 'cba done'

				end else if @taskName = 'upload Clients' begin

					exec QORT_ARM_SUPPORT_TEST.dbo.upload_Clients

					--select @IsProcessedTxt = 'clients done'

				end else begin

					select @IsProcessed = 4, @IsProcessedTxt = 'unknown task: ' + isnull(@taskName, 'NULL')

				end



				update t set t.IsProcessed = @IsProcessed, t.IsProcessedTxt = @IsProcessedTxt, t.procesedAt = getdate()

				from QORT_ARM_SUPPORT_TEST.dbo.tasks t

				where t.IsProcessed = 1 and t.taskId <= @taskId and isnull(t.taskName, 'NULL') = isnull(@taskName, 'NULL')



				waitfor delay '00:00:01'

			end else begin

				waitfor delay '00:00:03'

			end

			

		end try

		begin catch

			while @@TRANCOUNT > 0 ROLLBACK TRAN

			set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

			insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

			if @taskId > 0 begin

				select @IsProcessed = 4, @IsProcessedTxt = left(@Message, 128)

				update t set t.IsProcessed = @IsProcessed, t.IsProcessedTxt = @IsProcessedTxt, t.procesedAt = getdate()

				from QORT_ARM_SUPPORT_TEST.dbo.tasks t

				where t.IsProcessed = 1 and t.taskId <= @taskId and isnull(t.taskName, 'NULL') = isnull(@taskName, 'NULL')

			end

			waitfor delay '00:01:00'

		end catch



	end





END

