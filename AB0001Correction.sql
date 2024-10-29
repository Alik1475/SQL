

--exec QORT_ARM_SUPPORT.dbo.AB0001Correction



CREATE PROCEDURE [dbo].[AB0001Correction]



AS

BEGIN



	SET NOCOUNT ON



	begin try



	

		declare @todayDate date = getdate()

		declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)

		declare @Message varchar(1024)

	

		insert into QORT_BACK_TDB.dbo.CorrectPositions (ET_Const,Isprocessed, CT_Const, RegistrationDate

			, Subacc_Code, Asset, Size, Account_ExportCode, Comment2)

		SELECT 2 as ET_Const, 1 as Isprocessed, 7 as CT_Const, @todayInt as RegistrationDate

			, sa.SubAccCode as Subacc_Code, ass.ShortName as Asset, ph.VolFree*(-1) as Size, acc.ExportCode as Account_ExportCode, 'For execution' Comment2	

		FROM QORT_BACK_DB.dbo.Subaccs sa with (nolock) 

		left outer join  QORT_BACK_DB.dbo.Position ph with (nolock) on ph.Subacc_ID = sa.id

		left outer join QORT_BACK_DB.dbo.Assets ass with (nolock) on ass.id = ph.Asset_ID 

		left outer join QORT_BACK_DB.dbo.Accounts acc with (nolock) on acc.id = ph.Account_ID 

		where sa.SubAccCode = 'AB0001' and ph.VolFree > 0



	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		select @Message result, 'STATUS' defaultTask, 'red' color

	end catch



END

