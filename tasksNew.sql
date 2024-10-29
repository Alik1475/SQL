





CREATE PROCEDURE [dbo].[tasksNew]

	@taskName varchar(32) = null

AS

BEGIN



	SET NOCOUNT ON



	begin try



		set @taskName = nullif(@taskName, '')



		declare @Message varchar(1024)

		declare @rows int

		declare @aid int = 0

		declare @WaitCount int





		if @taskName is null begin

			select *, '' result, 'STATUS' defaultTask, 'black' color

			from taskTypes

			order by orderBy			

		end else if @taskName = 'STATUS' begin

			select top 100 *, IsProcessedTxt result, 'STATUS' defaultTask

				, case isProcessed when 1 then 'blue' when 3 then 'green' when 4 then 'red' else 'black' end color

			from QORT_ARM_SUPPORT_TEST.dbo.Tasks with (nolock)

			order by taskId desc

		end else begin

			insert into QORT_ARM_SUPPORT_TEST.dbo.tasks(taskName) values(@taskName)

		end



	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		select @Message result, 'STATUS' defaultTask, 'red' color

	end catch



END

