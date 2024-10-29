











/*

	exec QORT_ARM_SUPPORT.dbo.exportClientConfirmation @SubAccCode = 'AS1882'

*/



CREATE PROCEDURE [dbo].[exportClientConfirmation]

	@SubAccCode varchar(32) --= 'AS1882'

AS

BEGIN



	SET NOCOUNT ON



	select top 1 s.id--, f.id, s.SubAccCode, s.SubaccName, f.BOCode, f.FirmShortName, f.Name, fp.NameU

		, isnull(nullif(fp.NameU, ''), f.Name) AccountName

		, ltrim(rtrim(isnull(f.IDocSeries, '') + ' ' + isnull(f.IDocNum, ''))) ClientsPassport

		, ClientAgree.BrokerageAgreementNum

		, s.SubAccCode ClientIdentificationCode

		, DepoAcc.DEPODivisionCode

	from QORT_BACK_DB.dbo.SubAccs s with (nolock)

	left outer join QORT_BACK_DB.dbo.Firms f with (nolock) on f.id = s.OwnerFirm_ID

	left outer join QORT_BACK_DB.dbo.FirmProperties fp with (nolock) on fp.Firm_ID = s.OwnerFirm_ID

	outer apply (select cast(convert(varchar, getdate(), 112) as int) Today) Today

	outer apply (

		select top 1 ca.Num BrokerageAgreementNum

		from QORT_BACK_DB.dbo.ClientAgrees ca with (nolock)

		inner join QORT_BACK_DB.dbo.ClientAgreeTypes cat with (nolock) on cat.id = ca.ClientAgreeType_ID and cat.Name = 'AGREEMENT FOR PROVISION OF BROKERAGE SERVICES'

		where ca.SubAcc_ID = s.id and (ca.DateEnd = 0 or ca.DateEnd >= Today) and ca.Enabled = 0

		order by ca.id desc

	) ClientAgree

	outer apply (

		select top 1 fda.DEPODivisionCode

		from QORT_BACK_DB.dbo.FirmDEPOAccs fda with (nolock)

		where fda.Firm_ID = s.OwnerFirm_ID

			and fda.Code = s.SubAccCode collate Cyrillic_General_CI_AS

			and (fda.DateEnd = 0 or fda.DateEnd >= Today)

		order by iif(fda.Code = s.SubAccCode collate Cyrillic_General_CI_AS, 0, 1)

			, fda.id desc

	) DepoAcc

	where s.SubAccCode = UPPER(@SubAccCode) and s.Enabled = 0 and s.IsAnalytic = 'n'

	order by s.id



END

