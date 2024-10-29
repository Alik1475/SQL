













/*

	exec QORT_ARM_SUPPORT.dbo.exportClientConfirmationSubscription @SubAccCodes = 'AS1882, AS1883'

	SubscriptionID

	2C22E308-D6A3-4143-8CA9-9795980078D6

	ExtensionSettings

	<ParameterValues><ParameterValue><Name>PATH</Name><Value>\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\All Confirmations\Client Brokerage Confirmations\Temp</Value></ParameterValue><ParameterValue><Name>FILENAME</Name><Value>Client Brokerage Confirmatio
n</Value></ParameterValue><ParameterValue><Name>FILEEXTN</Name><Value>True</Value></ParameterValue><ParameterValue><Name>USERNAME</Name><Value>MHfN3rOQnmZa2qirG7L4i1caK6vuA+QBq5s9BiUu0+EVKoV/Rbyn9g==</Value></ParameterValue><ParameterValue><Name>PASSWORD<
/Name><Value>1VDUMkX84PL0cgDYtXSJTPfO2rjizGmxL8VVBpKUZGzxVbVF6gZWAixPRzxWTvHgOenZHU7MnA0=</Value></ParameterValue><ParameterValue><Name>RENDER_FORMAT</Name><Value>WORDOPENXML</Value></ParameterValue><ParameterValue><Name>WRITEMODE</Name><Value>Overwrite</
Value></ParameterValue><ParameterValue><Name>DEFAULTCREDENTIALS</Name><Value>False</Value></ParameterValue></ParameterValues>

	Parameters

	<ParameterValues><ParameterValue><Name>SubAccCode</Name><Value>AS1882</Value></ParameterValue></ParameterValues>

*/



CREATE PROCEDURE [dbo].[exportClientConfirmationSubscription]

	@SubAccCodes varchar(4000) --= 'AS1882, AS1883'

AS

BEGIN



	SET NOCOUNT ON



	begin try



		declare @ResPath varchar(256) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\All Confirmations\Client Brokerage Confirmations'

		declare @TempPath varchar(256) = @ResPath + '\Temp'

		declare @FileName varchar(128)



		declare @resultStatus varchar(1024)

		declare @resultPath varchar(255)

		declare @resultColor varchar(32)

		declare @resultDateTime varchar(32)



		declare @res table(Num int identity, SubAccCode varchar(32), resultStatus varchar(1024), resultPath varchar(255), resultColor varchar(32), resultDateTime varchar(32))



		declare @Message varchar(1024)



		declare @SubAcss table(id int identity, SubAccCode varchar(32))



		insert into @SubAcss(SubAccCode)

		select val

		from QORT_ARM_SUPPORT.dbo.fnt_ParseString_Num(replace(@SubAccCodes, ' ', ','), ',')

		where val <> ''



		declare @id int = 0

		declare @SubAccCode varchar(32) = ''



		declare @fres table(r varchar(255))

		declare @cmd varchar(512)

		declare @execres varchar(1024)



		declare @SubscriptionID varchar(64)

		declare @ExtensionSettings varchar(8000)

		declare @Parameters varchar(8000)

		declare @LastStatus varchar(1024)

		declare @LastRunTime datetime

		declare @BeforeRun datetime

		declare @WaitCount int



		select top 1 @SubscriptionID = s.SubscriptionID, @ExtensionSettings = s.ExtensionSettings

			, @Parameters = s.Parameters, @LastStatus = s.LastStatus, @LastRunTime = s.LastRunTime

		from ReportServer.dbo.Catalog c with (nolock)

		inner join ReportServer.dbo.Subscriptions s with (nolock) on s.Report_OID = c.ItemID

		where c.Name = 'Client Brokerage Confirmation'



		if @SubscriptionID is null begin

			set @Message = 'Subscription for "Client Brokerage Confirmation" NOT FOUND'

			RAISERROR (@Message, 16, 1);

		end



		select @ExtensionSettings = QORT_ARM_SUPPORT.dbo.sf_SetParamExtensionSettings(@ExtensionSettings, 'PATH', @TempPath)





		while @SubAccCode is not null begin

			set @SubAccCode = null

			select top 1 @id = t.id, @SubAccCode = t.SubAccCode

			from @SubAcss t

			where t.id > @id

			order by 1

			if @SubAccCode is null break

			

			print @SubAccCode

			set @FileName = 'BrokConfo_' + @SubAccCode + '.docx'

			print @FileName



			select @ExtensionSettings = QORT_ARM_SUPPORT.dbo.sf_SetParamExtensionSettings(@ExtensionSettings, 'FILENAME', replace(@FileName, '.docx', ''))

			select @Parameters = QORT_ARM_SUPPORT.dbo.sf_SetParamExtensionSettings(@Parameters, 'SubAccCode', @SubAccCode)



			update s set s.ExtensionSettings = @ExtensionSettings, s.Parameters = @Parameters

			from ReportServer.dbo.Subscriptions s with (nolock)

			where s.SubscriptionID = @SubscriptionID



			select @WaitCount = 60, @BeforeRun = getdate()



			exec ReportServer.dbo.AddEvent @EventType = 'TimedSubscription', @EventData = @SubscriptionID



			while @WaitCount > 0 and @BeforeRun > @LastRunTime begin

				waitfor delay '00:00:01'

				set @WaitCount = @WaitCount - 1



				select @LastStatus = s.LastStatus, @LastRunTime = s.LastRunTime

				from ReportServer.dbo.Subscriptions s with (nolock)

				where s.SubscriptionID = @SubscriptionID

			end



			if @WaitCount > 0 and charindex('has been saved to', @LastStatus) > 0 begin



				set @cmd = 'copy "' + @TempPath +'\'+ @FileName + '" "' + @ResPath +'\'+ @FileName + '"'



				delete r from @fres r

				insert into @fres(r) exec master.dbo.xp_cmdshell @cmd



				select @execres = cast((select r + '; ' from @fres for xml path('') ) as varchar(1024))



				if charindex('copied', @execres) = 0 begin

					set @execres = 'File Copy Error: ' + @execres + ' - ' + @ResPath +'\'+ @FileName

					set @resultColor = 'red'

					set @resultPath = ''

					set @resultStatus = @execres

				end else begin

					set @resultColor = 'green'

					set @resultPath = @ResPath +'\'+ @FileName

					set @resultStatus = 'done'

				end

			end else begin

				set @execres = 'Report Error: ' + @LastStatus

				set @resultColor = 'red'

				set @resultPath = ''

				set @resultStatus = @execres

			end



			set @resultDateTime = convert(varchar, getdate(), 102) + ' ' + convert(varchar, getdate(), 108)



			insert into @res (SubAccCode, resultStatus, resultPath, resultColor, resultDateTime)

			select @SubAccCode, @resultStatus, @resultPath, @resultColor, @resultDateTime

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

