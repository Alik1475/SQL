



-- exec QORT_ARM_SUPPORT.dbo.upload_Conversions







CREATE PROCEDURE [dbo].[upload_Conversions]

	

AS



BEGIN



	begin try

		declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Conversions'

		declare @Sheet varchar(16) 

		if right(@FilePath, 1) <> '\' set @FilePath = @FilePath + '\'

		declare @HistPath varchar(255) = @FilePath + 'history\'

		declare @InfoSource varchar(64) = object_name(@@procid)

		declare @TodayDate date = getdate()

		declare @TodayDateInt int = cast(convert(varchar, @TodayDate, 112) as int)

		declare @Message varchar(1024)

		declare @aid int = 0

		declare @n int = 0

		declare @WaitCount int

		declare @rowsInFile int

		declare @rowsNew int

		declare @rowsDone int

		declare @rowsError int

		declare @CheckDate as varchar(16)

		declare @CheckDateInt int 

		SET NOCOUNT ON







		declare @cmd varchar(255)

		declare @sql varchar(1024)



		set @cmd = 'md "' + @HistPath + '"'

		exec master.dbo.xp_cmdshell @cmd, no_output



		-----------------Список файлов в папке.

		declare @files table (fileId int identity, filename nvarchar(max));

		set @cmd = 'dir /b "'+@FilePath+'*.xls*"'

		insert into @files(filename) exec master..xp_cmdshell @cmd

		

		SELECT * FROM @FILES 



		delete f

		from @files f

		where not filename like '%.xlsx'



		SELECT * FROM @FILES 

		declare @FileId int = 0

		declare @FileName varchar(255)

		declare @NewFileName varchar(255)



		select top 1 @FileId = f.fileId, @FileName = f.filename

		from @files f

		where f.fileId > @FileId

		SET @rowsInFile = (SELECT MAX(fileId) FROM @FILES where filename is not null)

		

		while (@rowsInFile > 0)

	

	begin

		select @FileName = f.filename

		from @files f

		where f.fileId = @rowsInFile

			print @FileName





			set @Sheet = 'Sheet'

		  if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms

			IF OBJECT_ID('tempdb..#comms', 'U') IS NOT NULL DROP TABLE #comms;

	

			SET @sql = 'SELECT * INTO ##comms

			FROM OPENROWSET (

				''Microsoft.ACE.OLEDB.12.0'',

				''Excel 12.0; Database='+ @FilePath + @FileName + '; HDR=YES;IMEX=0'',

				''SELECT * FROM [' + @Sheet + '$A1:H10000]'')'



			exec(@sql)

			--select * from ##comms --return



			select row_number() over(order by [Qort]) rn

				, cast( RIGHT([tradedate],4)+left(RIGHT([tradedate],7),2)+left([tradedate],2) as int) TradeDate

				, [Qort] SubAcc

				, [Sell currency] Security_Code

				, [Sell Amount] Qty

				, [Buy currency] CurrPriceAsset_ShortName

				, [Buy Amount] Volume

				, [Rate] Price

			into #comms

			from ##comms

			where [Qort] is not null

----------------------- формирование сделОК в Корт---------------------------------------------------



		set @n = (select max(rn) from #comms) 

			

				while @n > 0

	begin



				set @WaitCount = 1200 -------------------- задержка, не передаем в ТДБ сделку, пока предыдущая не закончила грузиться----------------------

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB.dbo.ImportTrades t with (nolock) where t.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end

		

--/*

		insert into QORT_BACK_TDB.dbo.ImportTrades (

			IsProcessed, ET_Const, IsDraft

			, TradeDate, TradeTime, TSSection_Name

			, BuySell, Security_Code, Qty, Price

			, Volume1

			, CurrPriceAsset_ShortName, PutPlannedDate, PayPlannedDate

			, PutAccount_ExportCode

			, PayAccount_ExportCode

			, ForbidSyncPayAccs

			, CPPutAccount_ExportCode

			, CPPayAccount_ExportCode	

			, SubAcc_Code

			--, AgreeNum

			, TT_Const

			--, Comment

			--, AgreePlannedDate, Accruedint

			--, TraderUser_ID, SalesManager_ID

			, PT_Const

			--, TSCommission, IsAccrued

			, IsSynchronize

			, CpSubacc_Code

			--, SS_Const

			, FunctionType

			, CurrPayAsset_ShortName

			, TradeNum

			, CpFirm_BOCode

		) 

--*/		

			select 1 as IsProcessed, 2 as ET_Const, 'y' as IsDraft

			, TradeDate as TradeDate, replace(convert(varchar,getdate(),108), ':', '')+'000' TradeTime, 'OTC_FX' TSSection_Name

			, 2 as BuySell, Security_Code as Security_Code, Qty as Qty, Price as Price

			, Volume as Volume

			, CurrPriceAsset_ShortName as CurrPriceAsset_ShortName, TradeDate PutPlannedDate, TradeDate PayPlannedDate

			, 'Armbrok_Mn_Client' PutAccount_ExportCode

			, 'Armbrok_Mn_Client' PayAccount_ExportCode

			, 'y' ForbidSyncPayAccs

			, 'Armbrok_Mn_OWN' CPPutAccount_ExportCode

			, 'Armbrok_Mn_OWN' CPPayAccount_ExportCode		

			, SubAcc as SubAcc_Code

		--	, AgreeNum

			, 8 as TT_Const

			--, Comment

			--, AgreePlannedDate, Accruedint

			--, TraderUser_ID, SalesManager_ID

			, 2 as PT_Const

			--, TSCommission, IsAccrued

			, 'y' IsSynchronize

			, 'ARMBR_Subacc' as CpSubacc_Code

			--, SS_Const

			, 0 as FunctionType

			, CurrPriceAsset_ShortName as CurrPayAsset_ShortName

			--, right(replace(replace(replace(replace(convert(varchar, getdate(),121), ':', ''), '-', ''), ' ', ''), '.', ''),15) TradeNum

			, cast(

				(cast(

						right(SubAcc,4) as varchar(8))+cast(isnull((select max(ID) from QORT_BACK_DB.dbo.Trades with (nolock))+1,0) as varchar(8))) as int) TradeNum

			, '00001' CpFirm_BOCode

			from #comms

			where rn = @n



			set @n = @n - 1



		end		

--*/

--/*

					-- весь файл обработан, надо переложить в history

			select @NewFileName = convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':','-') + '_' + @FileName

			set @cmd = 'move "' + @FilePath + @FileName + '" "' + @HistPath + @NewFileName + '"'

			exec master.dbo.xp_cmdshell @cmd, no_output

			--select @NewFileName, @cmd



			SET @rowsInFile = @rowsInFile - 1

			PRINT @rowsInFile

		end

--*/

		

			

	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE() + ISNULL(', ' + @FileName, '');  

		if @message not like '%12345 Cannot initialize the data source%' insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END
