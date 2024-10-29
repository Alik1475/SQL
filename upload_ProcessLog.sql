CREATE PROCEDURE [dbo].[upload_ProcessLog]

AS

BEGIN



	SET NOCOUNT ON;





	



	declare @logIdMin int = 0

	declare @logIdMax int = 0

	declare @TestMode tinyint = 0

	declare @recipients varchar(512) = 'qortsupport@armbrok.am;'



	select @logIdMin = min(logId), @logIdMax = max(logId), @TestMode = max(iif(logProc in ('upload_Deals', 'upload_CrossRates_CBA'), 0, 1))

	from QORT_ARM_SUPPORT_TEST.dbo.uploadLogs with (nolock)

	where logDate > getdate()-1 and errorLevel between 1000 and 2999 and isProcessed = 0



	if @logIdMin <> 0 begin



		if @TestMode >= 0 set @recipients = @recipients + 'aleksandr.mironov@armbrok.am;'



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

			from QORT_ARM_SUPPORT_TEST.dbo.uploadLogs with (nolock)

			where logDate > getdate()-1 and errorLevel between 1000 and 2999 and isProcessed = 0 and logId between @logIdMin and @logIdMax

				and iif(logProc in ('upload_Deals', 'upload_CrossRates_CBA'), 0, 1) = @TestMode

			order by logDate, logId

		for xml path('')) as varchar(max))





		set @html = @html + replace(replace(@htmlTable, '&lt;', '<'), '&gt;', '>') + '</table></body></html>'



		EXEC msdb.dbo.sp_send_dbmail

			@profile_name = 'qort-test-sql'

			, @recipients = @recipients

			, @subject = 'TEST qort sql processings'

			, @BODY_FORMAT = 'HTML'

			, @body = @html



		update l set l.isProcessed = 1

		from QORT_ARM_SUPPORT_TEST.dbo.uploadLogs l

		where logDate > getdate()-1 and errorLevel between 1000 and 2999 and isProcessed = 0 and logId between @logIdMin and @logIdMax

			and iif(logProc in ('upload_Deals', 'upload_CrossRates_CBA'), 0, 1) = @TestMode



	end

END
