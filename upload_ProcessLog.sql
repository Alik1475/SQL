CREATE PROCEDURE [dbo].[upload_ProcessLog]

AS

BEGIN



	SET NOCOUNT ON;



	declare @logIdMin int = 0

	declare @logIdMax int = 0

	select @logIdMin = min(logId), @logIdMax = max(logId)

	from QORT_ARM_SUPPORT.dbo.uploadLogs with (nolock)

	where logDate > getdate()-1 and errorLevel between 1000 and 2999 and isProcessed = 0



	if @logIdMin <> 0 begin



		declare @html varchar(max)

		set @html = '<html><body><table border="1">'

		set @html = @html + '<tr><td>Process</td><td>DateTime</td><td>Message</td><td>Records</td></tr>'

		declare @htmlTable varchar(max)



		select @htmlTable = cast(

			(select '<font color="' + case when errorLevel between 1000 and 1999 then 'red'

			when errorLevel between 2000 and 2999 then 'green'

			else 'black' end +'"/>'

			+ '<tr>'

			+ '<td>' + isnull(logProc, 'NULL') + '</td>'

			+ '<td>' + convert(varchar, logDate, 112) + ' ' + convert(varchar, logDate, 8) + '</td>'

			+ '<td>' + isnull(logMessage, 'NULL') + '</td>'

			+ '<td>' + isnull(cast(logRecords as varchar), '') + '</td>'

			+ '</tr>'

			from QORT_ARM_SUPPORT.dbo.uploadLogs with (nolock)

			where logDate > getdate()-1 and errorLevel between 1000 and 2999 and isProcessed = 0 and logId between @logIdMin and @logIdMax

			order by logDate, logId

		for xml path('')) as varchar(max))





		set @html = @html + replace(replace(@htmlTable, '&lt;', '<'), '&gt;', '>') + '</table></body></html>'



		EXEC msdb.dbo.sp_send_dbmail

			@profile_name = 'qort-sql-mail'

			, @recipients = 'qortsupport@armbrok.am;aleksandr.mironov@armbrok.am;armine.khachatryan@armbrok.am;arevik.petrosyan@armbrok.am;lilit.manvelyan@armbrok.am;sona.nalbandyan@armbrok.am;'

			, @subject = 'PROD qort sql processings'

			, @BODY_FORMAT = 'HTML'

			, @body = @html



		update l set l.isProcessed = 1

		from QORT_ARM_SUPPORT.dbo.uploadLogs l

		where logDate > getdate()-1 and errorLevel between 1000 and 2999 and isProcessed = 0 and logId between @logIdMin and @logIdMax



	end

END
