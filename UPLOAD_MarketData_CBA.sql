
-- exec QORT_ARM_SUPPORT..UPLOAD_MarketData_CBA

CREATE PROCEDURE [dbo].[UPLOAD_MarketData_CBA]


	

AS



BEGIN





		begin try

		declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\MarketData_CBA\'

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

		--print @cmd

		SELECT * FROM @FILES 

		declare @FileId int = 0

		declare @FileName varchar(255)

		declare @NewFileName varchar(255)

		SELECT * FROM @FILES 

		



		select top 1 @FileId = f.fileId, @FileName = f.filename

		from @files f

		where f.fileId > @FileId

		SET @rowsInFile = (SELECT MAX(fileId-1) FROM @FILES)

		

		while (@rowsInFile > 0)

	

	begin

		select @FileName = f.filename

		from @files f

		where f.fileId = @rowsInFile

			print @FileName





			set @Sheet = 'YC_ENG'



		  if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms

			IF OBJECT_ID('tempdb..#comms', 'U') IS NOT NULL DROP TABLE #comms;

	

			SET @sql = 'SELECT * INTO ##comms

			FROM OPENROWSET (

				''Microsoft.ACE.OLEDB.12.0'',

				''Excel 12.0; Database='+ @FilePath + @FileName + '; HDR=YES;IMEX=0'',

				''SELECT * FROM [' + @Sheet + '$J5:O43]'')'



			exec(@sql)

			select * from ##comms 

			

			--/*

				  INSERT INTO QORT_BACK_TDB..ImportMarketInfo (
            OldDate
          , TSSection_Name
          , Asset_ShortName
          , LastPrice
          , IsProcessed
          , isprocent
          , PriceAsset_ShortName
        )

		--*/

		select 

		REPLACE(SUBSTRING(@FileName, PATINDEX('%[0-9][0-9][0-9][0-9]-%', @FileName), 10), '-', '') as OldDate

		, 'AMX_REPO' as TSSection_Name

		, ass.ShortName Asset_ShortName

		, t.E as LastPrice

		, 1 as IsProcessed

		, iif(t.B not in('AMEUBDB22ER6','XS2010043904','XS2010028939'), 'y', 'n') as IsProcent

		, iif(t.B in('AMEUBDB22ER6','XS2010043904','XS2010028939'), 'AMD', null) as PriceAsset_ShortName



		from ##comms t

			left outer join QORT_BACK_DB.dbo.Assets ass on IIF(isnull(ass.ISIN,'-') = '', '-',isnull(ass.ISIN,'-')) = t.B and ass.Enabled <> ass.id

			WHERE ass.ShortName IS NOT NULL

		



--/*

					-- весь файл обработан, надо переложить в history

			select @NewFileName = convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':','-') + '_' + @FileName

			set @cmd = 'move "' + @FilePath + @FileName + '" "' + @HistPath + @NewFileName + '"'

			exec master.dbo.xp_cmdshell @cmd, no_output

			--select @NewFileName, @cmd



			SET @rowsInFile = @rowsInFile - 1

			PRINT @rowsInFile

			--RETURN

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
