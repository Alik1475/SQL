/*

exec QORT_ARM_SUPPORT.dbo.SendMail_LetterForClients @sendmail = 1 , @SendText = '', @SendSubject = 'Notice: Please Ignore the Report Email Sent Today'

*/

CREATE PROCEDURE [dbo].[SendMail_LetterForClients]

	@SendMail bit,

	@SendText varchar(1024) ,

	@SendSubject varchar(1024)

AS

BEGIN



	SET NOCOUNT ON



	begin try



									



declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\SendMail'

declare @Sheet varchar(16) 

if right(@FilePath, 1) <> '\' set @FilePath = @FilePath + '\'

declare @Message varchar (1024)									

declare @NotifyEmail varchar(1024) 

declare @NotifyMessage varchar(1024)



select @NotifyMessage = bulkColumn 

from openrowset(bulk '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\SendMail\NotifyMessage.txt', SINGLE_CLOB) as FileData

--print @NotifyMessage return

declare @NotifyTitle varchar(1024)

declare @subaccode varchar(1024)

declare @ConstitutorCode varchar(1024)

declare @Name varchar(1024)

declare @ContactsEmail varchar(1024)

declare @n int

declare @n1 int

if OBJECT_ID('tempdb..#RESULT', 'U') is not null drop table #RESULT



 select distinct ROW_NUMBER() OVER(order by SubAccCode asc) as Num

	, s.SubAccCode

	, f.Name

	, replace(f.Email,',',';')+IIF(s.MarginEMail = '','',';'+s.MarginEMail) email--, s.ConstitutorCode

	, s.OwnerFirm_ID firm_id

	, '' MarginEMail

	, IIF((f.FT_Flags > 4194304 and f.FT_Flags < 8388608) or f.FT_Flags > 8500000, 'y','n') own_clerk

	, f.Email emailBP

	, f.BOCode

	, f.Sales_ID

 into #result

 from QORT_BACK_DB..Subaccs s

   right outer join QORT_BACK_DB..Firms f on f.id = s.OwnerFirm_ID

 where s.SubAccCode in ('closeAS1527','AS1691','AS1745','AS1777','AS1826','AS1894','AS1866','AS1909','AS1907','AS1914','AS1917','AS1923','AS1926','AS1927','AS1920','AS1932','AS1936','AS1937','AS1938','AS1939','AS1940','AS1942','AS1943','AS1946','AS1949','
AS1948','AS1959','AS1960','AS1963','AS1967','AS1970','AS1973','AS1974','AS1975','AS1978','AS1979','AS1987','AS1991','AS1992','AS1995','AS2000','AS2004','AS2010','AS2011') --and (f.FT_Flags > 4194304 and f.FT_Flags < 8388608) or f.FT_Flags > 8500000 --and 
SubAccCode = 'AS1105'--and (c.FCT_Const = 2 or c.FCT_Const is null) and c.IsCancel = 'n'

  --and s.SubAccCode in ('AS1935')

--and f.Sales_ID in(273)

  order by SubAccCode asc





	set @n = 0--CAST ((select max (num) from #result) as int)



 while @n > 0

   begin

	 if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t

	  

	  select ROW_NUMBER() OVER(order by email asc) as Num1, email 

	  into #t

	  from QORT_BACK_DB..FirmContacts fc

	  where fc.Firm_ID = CAST((select Firm_ID from #result where Num = @n) as varchar(1024)) and FCT_Const = 2 and IsCancel = 'n'



     set @n1 = CAST ((select max (Num1) from #t) as int)

	

	while @n1 > 0

	 begin   



	  set @ContactsEmail = CAST((select iif(charindex('@',email) > 0, email, '') from #result where Num = @n) as varchar(1024))+iif((select iif(charindex('@',email) > 0, email, '') from #t where Num1 = @n1) = '','',';'+CAST((select email from #t where Num1 =
 @n1) as varchar(1024)))

	  

	  update #result

	  set email = @ContactsEmail

	  where Num = @n

	  

	  set @n1 = @n1-1



	 end



	set @n = @n-1

   end

	

	SELECT * FROM #RESULT order by SubAccCode



	

	-------------------------------------блок отправки сообщений----------------------------------------

if @SendMail = 1 begin



	 set @n = CAST ((select max (num) from #result) as int)

	 while @n > 0

	  begin

	   set @Name = cast((select Name from #result where Num = @n) as varchar(1024))

	   set @NotifyTitle = @SendSubject

	   set @subaccode = cast((select SubAccCode from #result where Num = @n) as varchar(1024))

	 -- /* 

	  set @NotifyMessage = ' We would like to inform you that due to a technical issue, a report was mistakenly sent to your email. This report contains no operational data and should be disregarded.<br/> 
We sincerely apologize for any inconvenience this ma
y have caused and appreciate your understanding.<br/> <br/> 

Best regards,<br/> 

            ARMBROK Team'

			--*/

	   set @NotifyEmail = cast((select email from #result where Num = @n ) as varchar(1024) )

	  

	  if @NotifyEmail = '' --уведомление, что емаил клиента не найден



	 begin

	    set @NotifyEmail = 'aleksandr.mironov@armbrok.am;sona.nalbandyan@armbrok.am;onboarding@armbrok.am'

	    set @NotifyTitle = 'Error. Client without email!!! '+@subaccode+' '+@Name

	 end

	

	print @NotifyEmail

	--/*

	EXEC msdb.dbo.sp_send_dbmail

			@profile_name =  'onboarding-sql'--'onboarding-test-sql'--

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage 

		--	, @file_attachments = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Статика\02_SSI_ARMBROK_GENERAL_CLIENT_USD.pdf'

			--*/

			set @n = @n - 1

			--print @NotifyEmail

			end

	   





	 end

	else 

	 begin

	 set @NotifyEmail = 'qort@armbrok.am'

	 set @Name = '--ClientName--'

	 set @NotifyTitle = 'Information letter for '+@Name+': '+@SendSubject

	 /*

	 EXEC msdb.dbo.sp_send_dbmail

			@profile_name =  'onboarding-sql'--'onboarding-test-sql'--

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage 

		--	, @file_attachments = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Статика\02_SSI_ARMBROK_GENERAL_CLIENT_USD.pdf'

		*/

	 end

	-------------------------------------------------------------------------конец блока отправки сообщений-------------------------------------------

	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		select @Message result, 'STATUS' defaultTask, 'red' color

	end catch



END

