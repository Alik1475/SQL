
-- exec QORT_ARM_SUPPORT.dbo.UploadGlocalRate 

CREATE PROCEDURE [dbo].[UploadGlocalRate]

AS



BEGIN



	begin try

		declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\CustomUpload'

		declare @Sheet varchar(16) 

		if right(@FilePath, 1) <> '\' set @FilePath = @FilePath + '\'

		declare @HistPath varchar(255) = @FilePath + 'history\'

		

		declare @TodayDate date = getdate()

		declare @TodayDateInt int = cast(convert(varchar, @TodayDate, 112) as int)

		declare @Message varchar(1024)

		declare @FileName varchar(255)



		declare @FileId int = 0



		SET NOCOUNT ON







		declare @cmd varchar(255)

		declare @sql varchar(1024)

	

		set @cmd = 'md "' + @HistPath + '"'

		exec master.dbo.xp_cmdshell @cmd, no_output



		-----------------Список файлов в папке.

			declare @files table (fileId int identity, filename nvarchar(max));

		set @cmd = 'dir /b "'+@FilePath+'*.xls*"'

		insert into @files(filename) exec master..xp_cmdshell @cmd--, no_output



		SELECT * FROM @files

		DELETE FROM @files WHERE filename IS NULL OR LEFT(filename,8) <> 'PROFIX_U'--OR LEFT(filename,3) <> 'AYB'

		SELECT * FROM @files



	

		select top 1 @FileId = f.fileId, @FileName = f.filename

		from @files f

		where f.fileId > @FileId AND filename IS NOT NULL 

		

	



	

	

		select @FileName = f.filename

		from @files f

		--where f.fileId = @rowsInFile

			print @FileName

		



			set @Sheet = 'NAV'



		  if OBJECT_ID('tempdb..##comms', 'U') is not null drop table ##comms

			

	

			SET @sql = 'SELECT * INTO ##comms

			FROM OPENROWSET (

				''Microsoft.ACE.OLEDB.12.0'',

				''Excel 12.0; Database='+ @FilePath + @FileName + '; HDR=NO;IMEX=0'',

				''SELECT * FROM [' + @Sheet + '$A6:R10000]'')'

				

			exec(@sql)

			select * from ##comms 

/*

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

				cast(convert(varchar,[1], 112) as int)  DataOld

				, 'OTC_SWAP' as TSSection_Name 

				, 'Glocal Profix USD Fund' Asset_ShortName

				,  [10] LastPrice

				, 1 IsProcessed
          , 'n' isprocent
          , 'USD' PriceAsset_ShortName

				

			from ##comms

			--where [10] <> '#DIV/0!' --is not null --AND cast(convert(varchar,[1], 112) as int) = 20231018-

			--select * from #comms 

			--return



	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE() + ISNULL(', ' + @FileName, '');  

		if @message not like '%12345 Cannot initialize the data source%' insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END
