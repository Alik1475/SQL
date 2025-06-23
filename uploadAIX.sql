



-- exec QORT_ARM_SUPPORT..uploadAIX







CREATE PROCEDURE [dbo].[uploadAIX]

	

AS



BEGIN



	begin try

		declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\AIX\'

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

		DECLARE @FileCount INT

		SET NOCOUNT ON







		declare @cmd varchar(255)

		declare @sql varchar(1024)

	

		set @cmd = 'md "' + @HistPath + '"'

		exec master.dbo.xp_cmdshell @cmd, no_output



		-----------------Список файлов в папке.

			declare @files table (fileId int identity, filename nvarchar(max));

		set @cmd = 'dir /b "'+@FilePath+'*.xls*"'

		insert into @files(filename) exec master..xp_cmdshell @cmd--, no_output

		/*

		declare @files table (fileId int identity, filename nvarchar(max));

		set @cmd = 'dir /b "'+@FilePath+'*.xls*"'

		PRINT @CMD --RETURN

		insert into @files(filename) exec master..xp_cmdshell @cmd, no_output

		*/

		SELECT * FROM @files

		DELETE FROM @files WHERE filename IS NULL OR LEFT(filename,3) <> '202'

	

				-- Проверка, есть ли файлы
SELECT @FileCount = COUNT(*) FROM @files WHERE filename IS NOT NULL OR LEFT(filename,3) = '202';

-- Если файлы найдены, продолжаем выполнение
IF @FileCount > 0

begin	

		SELECT * FROM @FILES 

		declare @FileId int = 0

		declare @FileName varchar(255)

		declare @NewFileName varchar(255)

/*		-- Подсчёт количества файлов
SET @cmd = 'dir /b "' + @filePath + '*.xls*"';
INSERT INTO @files(filename) 
EXEC master.dbo.xp_cmdshell @cmd;
*/


		select top 1 @FileId = f.fileId, @FileName = f.filename

		from @files f

		where f.fileId > @FileId AND filename IS NOT NULL AND LEFT(filename,4) = '2024'

		SET @rowsInFile = (SELECT MAX(fileId) FROM @FILES)

		

		while (@rowsInFile > 0)

	

	begin

		select @FileName = f.filename

		from @files f

		where f.fileId = @rowsInFile

			print @FileName





			set @Sheet = 'AIX'



		  if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms

			--IF OBJECT_ID('tempdb..#comms', 'U') IS NOT NULL DROP TABLE #comms;

	

			SET @sql = 'SELECT * INTO ##comms

			FROM OPENROWSET (

				''Microsoft.ACE.OLEDB.12.0'',

				''Excel 12.0; Database='+ @FilePath + @FileName + '; HDR=YES;IMEX=0'',

				''SELECT * FROM [' + @Sheet + '$A1:R10000]'')'



			exec(@sql)

			select * from ##comms 

			--return

			select row_number() over(order by [F1]) rn

			   , ISNULL(

					TRY_CAST(CONVERT(VARCHAR, [TradeTime_NOT_AIX], 112) AS INT),

					TRY_CAST(CONVERT(VARCHAR, [Trade Time], 112) AS INT)

				) AS TradeDate

				, CAST(

					RIGHT('0' + CAST(DATEPART(HOUR, ISNULL([TradeTime_NOT_AIX], [Trade Time])) AS VARCHAR), 2) +

					RIGHT('0' + CAST(DATEPART(MINUTE, ISNULL([TradeTime_NOT_AIX], [Trade Time])) AS VARCHAR), 2) +

					RIGHT('0' + CAST(DATEPART(SECOND, ISNULL([TradeTime_NOT_AIX], [Trade Time])) AS VARCHAR), 2) +

					RIGHT('00' + CAST(DATEPART(MILLISECOND, ISNULL([TradeTime_NOT_AIX], [Trade Time])) AS VARCHAR), 3)

				AS INT) AS TimeInt

				, [F1] SubAcc

				, [F2] Comment

				, [Account] ACC_ExportCode

				, [TSSection_Name] TSS_name

				, [TradeTime_NOT_AIX] TradeTime_NOT_AIX

				, [ISIN] Security_Code

				, [Quantity] Qty

				, [Base Currency] CurrPriceAsset_ShortName

				, [Trade Value] Volume

				, [Price] Price

				, [Buy Account] BUY

				, [Sell Account] SELL

				, [Ref] Ref

				, CONVERT(INT, CONVERT(VARCHAR,dbo.fGetBusinessDay([Trade Time], 2), 112)) AS PutPlannedDate

				, CAST(
						RIGHT('0' + CAST(DATEPART(HOUR, DATEADD(HOUR, 4, [Trade Time])) AS VARCHAR), 2) + 
						RIGHT('0' + CAST(DATEPART(MINUTE, DATEADD(HOUR, 4, [Trade Time])) AS VARCHAR), 2) + 
						RIGHT('0' + CAST(DATEPART(SECOND, DATEADD(HOUR, 4, [Trade
 Time])) AS VARCHAR), 2) + 
						RIGHT('00' + CAST(DATEPART(MILLISECOND, DATEADD(HOUR, 4, [Trade Time])) AS VARCHAR), 3) 
					AS INT) AS TimeIntUpdate

			into #comms

			from ##comms

			where [Trade Value] is not null

			select * from #comms 

			--return

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

			, PutAccount_ExportCode, PayAccount_ExportCode, SubAcc_Code

			--, AgreeNum

			, TT_Const

			, Comment

			--, AgreePlannedDate, Accruedint

			--, TraderUser_ID, SalesManager_ID

			, PT_Const

			--, TSCommission, IsAccrued

			, IsSynchronize

			--, CpSubacc_Code

			--, SS_Const

			, FunctionType

			, CurrPayAsset_ShortName

			, TradeNum

			, OrdExchCode

			--, CpFirm_BOCode

		) 

--*/		

			select 1 as IsProcessed, 2 as ET_Const, 'y' as IsDraft

			, TradeDate as TradeDate

			, isnull(com.TimeIntUpdate, com.TimeInt) TradeTime

			, com.TSS_name TSSection_Name

			, iif(BUY = '-', 2, 1) as BuySell

			, sec.SecCode as Security_Code, Qty as Qty, Price as Price

			, Volume as Volume

			, CurrPriceAsset_ShortName as CurrPriceAsset_ShortName

			, isnull(com.PutPlannedDate, com.TradeDate) PutPlannedDate			

			, isnull(com.PutPlannedDate, com.TradeDate) PayPlannedDate

			, ACC_ExportCode PutAccount_ExportCode, 'Armbrok_Mn_Client' PayAccount_ExportCode, sub.SubAccCode as SubAcc_Code

		--	, AgreeNum

			, tss.tt_const as TT_Const --TT_M_FORWARD(Exchange forward)

			, com.Comment as Comment

			--, AgreePlannedDate, Accruedint

			--, TraderUser_ID, SalesManager_ID

			, 2 as PT_Const

			--, TSCommission, IsAccrued

			, 'n' IsSynchronize

			--, 'ARMBR_Subacc' as CpSubacc_Code

			--, SS_Const

			, 0 as FunctionType

			, CurrPriceAsset_ShortName as CurrPayAsset_ShortName

			--, right(replace(replace(replace(replace(convert(varchar, getdate(),121), ':', ''), '-', ''), ' ', ''), '.', ''),15) TradeNum

			, cast(

				(cast(isnull(Sub.id,'') as varchar(8))+cast(isnull((select max(ID) from QORT_BACK_DB.dbo.Trades with (nolock))+1,0) as varchar(8))) as int) TradeNum

			, Ref as OrdExchCode

			--, '00001' CpFirm_BOCode

					from #comms com

					outer apply (

						select top 1 *

						from QORT_BACK_DB.dbo.TSSections tss

						where tss.Name = com.TSS_name COLLATE Cyrillic_General_CI_AS

					) tss

					outer apply (

						select top 1 *

						from QORT_BACK_DB.dbo.Assets ass

						where ass.ISIN = com.Security_Code COLLATE Cyrillic_General_CI_AS

						  and ass.Enabled = 0

					) ass

					outer apply (

						select top 1 *

						from QORT_BACK_DB.dbo.Securities sec

						where sec.Asset_ID = ass.id

						  and sec.TSSection_ID = tss.id

						  and sec.IsTrading = 'y'

					) sec

					outer apply (

						select top 1 id, SubAccCode

						from QORT_BACK_DB.dbo.Subaccs sub

						where sub.SubAccCode = com.SubAcc COLLATE Cyrillic_General_CI_AS

						  and ass.Enabled = 0

					) sub

					where com.rn = @n and sec.SecCode is not null



			set @n = @n - 1



		end	

		

--/*



					-- весь файл обработан, надо переложить в history

			select @NewFileName = convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':','-') + '_' + @FileName

			set @cmd = 'move "' + @FilePath + @FileName + '" "' + @HistPath + @NewFileName + '"'

			exec master.dbo.xp_cmdshell @cmd, no_output

			--select @NewFileName, @cmd

--*/

			SET @rowsInFile = @rowsInFile - 1

			PRINT @rowsInFile



		end



	end

	ELSE
BEGIN
    PRINT 'No files found';
END;

			

	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE() + ISNULL(', ' + @FileName, '');  

		if @message not like '%12345 Cannot initialize the data source%' insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END
