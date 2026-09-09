USE [APFM]
GO

/****** Object:  View [dbo].[X_REFInvoiceAllDetail]    Script Date: 9/9/2026 10:43:28 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW [dbo].[X_REFInvoiceAllDetail]
AS
SELECT 
A.BACHNUMB [Batch Name],
A.CUSTNMBR [Customer Number], 
B.CUSTNAME [Customer Name], 
B.USERDEF2 [YGL Master Acct],
S.STATE [State],
A.DOCNUMBR [Document Number],
CASE S.SOPTYPE
	when 3 then 'Invoice'
	when 4 then 'Return'
	else ''
	end [SOP Type],
CAST(A.DOCDATE as date) [Document Date],
CAST(A.DUEDATE as date) [Due Date],
CAST(A.SLSAMNT as money) [Subtotal],
CASE
	WHEN A.TAXAMNT is NULL or A.TAXAMNT = 0 THEN ''
	ELSE CAST(CAST((A.TAXAMNT) as money) as varchar(20))
END AS [Tax Amount],
-----CAST(A.TAXAMNT as money) [Tax Amount],
CAST(A.ORTRXAMT as money) [Original Trx Amount],
CAST(A.CURTRXAM as money) [Current Trx Amount],
S.ITEMNMBR [Item Number],
S.ITEMDESC [Item Description],
CAST(S.QUANTITY as decimal (19,2)) [Qty],
S.UNITPRCE [Unit Price],
S.XTNDPRCE [Extended Price],
L.[Lead ID],
C.[RESIDENT NAME] [Resident Name],
D.[Referral Date],
M.[Move-In Date],
R.[Resident Charge],
F.[Referral Fee %],
O.[Original Invoice],
CAST(A.GLPOSTDT as date) [GL Date],
CAST(A.POSTDATE as date) [Posting Date],
GL.ACTNUMST [Account],
N.ACTDESCR [Account Description]

FROM
RM20101 A
inner join SOP30300 S
ON
A.DOCNUMBR=S.SOPNUMBE
inner join RM00101 B
ON
A.CUSTNMBR=B.CUSTNMBR
left outer join _FINE_vw_RESIDENTNAME C
ON 
A.DOCNUMBR=C.SOPNUMBE
left outer join 
(Select SOPNUMBE,ITEMDESC as [Move-In Date] from SOP30300 with(nolock) where ITEMNMBR = 'MOVE-IN DATE' 
and SOPTYPE in ('3','4')) M
ON
A.DOCNUMBR=M.SOPNUMBE
left outer join 
(Select SOPNUMBE,ITEMDESC as [Lead ID] from SOP30300 with(nolock) where ITEMNMBR = 'LEAD ID' 
and SOPTYPE in ('3','4')) L
ON
A.DOCNUMBR=L.SOPNUMBE
left outer join 
(Select SOPNUMBE,ITEMDESC as [Referral Date] from SOP30300 with(nolock) where ITEMNMBR = 'REFERRAL DATE' 
and SOPTYPE in ('3','4')) D
ON
A.DOCNUMBR=D.SOPNUMBE
left outer join 
(Select SOPNUMBE,ITEMDESC as [Resident Charge] from SOP30300 with(nolock) where ITEMNMBR = 'RESIDENT CHARGE' 
and SOPTYPE in ('3','4')) R
ON
A.DOCNUMBR=R.SOPNUMBE
left outer join 
(Select SOPNUMBE,ITEMDESC as [Referral Fee %] from SOP30300 with(nolock) where ITEMNMBR = 'REFERRAL FEE %' 
and SOPTYPE in ('3','4')) F
ON
A.DOCNUMBR=F.SOPNUMBE
left outer join 
(Select SOPNUMBE,ITEMDESC as [Original Invoice] from SOP30300 with(nolock) where ITEMNMBR = 'ORIGINAL INVOICE' 
and SOPTYPE in ('3','4')) O
ON
A.DOCNUMBR=O.SOPNUMBE


left outer join SOP10102 G
on S.SOPTYPE=G.SOPTYPE
and S.SOPNUMBE=G.SOPNUMBE
and S.LNITMSEQ=G.SEQNUMBR
left outer join GL00100 N
on G.ACTINDX=N.ACTINDX
left outer join GL00105 GL
on N.ACTINDX=GL.ACTINDX


where G.ACTINDX not like '6'
and N.ACTDESCR not like '%Receivable%'

-----and S.ITEMNMBR like 'REF-%'
-----and S.ITEMNMBR not like 'REF-H%'

UNION ALL

SELECT 
A.BACHNUMB [Batch Name],
A.CUSTNMBR [Customer Number], 
B.CUSTNAME [Customer Name], 
B.USERDEF2 [YGL Master Acct],
S.STATE [State],
A.DOCNUMBR [Document Number],
CASE S.SOPTYPE
	when 3 then 'Invoice'
	when 4 then 'Return'
	else ''
	end [SOP Type],
CAST(A.DOCDATE as date) [Document Date],
CAST(A.DUEDATE as date) [Due Date],
CAST(A.SLSAMNT as money) [Subtotal],
CASE
	WHEN A.TAXAMNT is NULL or A.TAXAMNT = 0 THEN ''
	ELSE CAST(CAST((A.TAXAMNT) as money) as varchar(20))
END AS [Tax Amount],
-----CAST(A.TAXAMNT as money) [Tax Amount],
CAST(A.ORTRXAMT as money) [Original Trx Amount],
CAST(A.CURTRXAM as money) [Current Trx Amount],
S.ITEMNMBR [Item Number],
S.ITEMDESC [Item Description],
CAST(S.QUANTITY as decimal (19,2)) [Qty],
S.UNITPRCE [Unit Price],
S.XTNDPRCE [Extended Price],
L.[Lead ID],
C.[RESIDENT NAME] [Resident Name],
D.[Referral Date],
M.[Move-In Date],
R.[Resident Charge],
F.[Referral Fee %],
O.[Original Invoice],
CAST(A.GLPOSTDT as date) [GL Date],
CAST(A.POSTDATE as date) [Posting Date],
GL.ACTNUMST [Account],
N.ACTDESCR [Account Description]

FROM
RM30101 A
inner join SOP30300 S
ON
A.DOCNUMBR=S.SOPNUMBE
inner join RM00101 B
ON
A.CUSTNMBR=B.CUSTNMBR
left outer join _FINE_vw_RESIDENTNAME C
ON 
A.DOCNUMBR=C.SOPNUMBE
left outer join 
(Select SOPNUMBE,ITEMDESC as [Move-In Date] from SOP30300 with(nolock) where ITEMNMBR = 'MOVE-IN DATE' 
and SOPTYPE in ('3','4')) M
ON
A.DOCNUMBR=M.SOPNUMBE
left outer join 
(Select SOPNUMBE,ITEMDESC as [Lead ID] from SOP30300 with(nolock) where ITEMNMBR = 'LEAD ID' 
and SOPTYPE in ('3','4')) L
ON
A.DOCNUMBR=L.SOPNUMBE
left outer join 
(Select SOPNUMBE,ITEMDESC as [Referral Date] from SOP30300 with(nolock) where ITEMNMBR = 'REFERRAL DATE' 
and SOPTYPE in ('3','4')) D
ON
A.DOCNUMBR=D.SOPNUMBE
left outer join 
(Select SOPNUMBE,ITEMDESC as [Resident Charge] from SOP30300 with(nolock) where ITEMNMBR = 'RESIDENT CHARGE' 
and SOPTYPE in ('3','4')) R
ON
A.DOCNUMBR=R.SOPNUMBE
left outer join 
(Select SOPNUMBE,ITEMDESC as [Referral Fee %] from SOP30300 with(nolock) where ITEMNMBR = 'REFERRAL FEE %' 
and SOPTYPE in ('3','4')) F
ON
A.DOCNUMBR=F.SOPNUMBE
left outer join 
(Select SOPNUMBE,ITEMDESC as [Original Invoice] from SOP30300 with(nolock) where ITEMNMBR = 'ORIGINAL INVOICE' 
and SOPTYPE in ('3','4')) O
ON
A.DOCNUMBR=O.SOPNUMBE


left outer join SOP10102 G
on S.SOPTYPE=G.SOPTYPE
and S.SOPNUMBE=G.SOPNUMBE
and S.LNITMSEQ=G.SEQNUMBR
left outer join GL00100 N
on G.ACTINDX=N.ACTINDX
left outer join GL00105 GL
on N.ACTINDX=GL.ACTINDX


where G.ACTINDX not like '6'
and N.ACTDESCR not like '%Receivable%'

-----and S.ITEMNMBR like 'REF-%'
-----and S.ITEMNMBR not like 'REF-H%'

GO

