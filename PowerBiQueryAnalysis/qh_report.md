# Power BI SQL landscape — `workspace_jf.landscape.qh`

Parsed with sqlglot 30.14.0, dialect `databricks`.

| | |
|---|---|
| Distinct statements | 2,262 |
| Executions | 513,679 |
| Window | 2025-09-06T00:31:14.657Z → 2026-09-09T18:35:19.494Z |
| Power BI datasets | 31 |
| Distinct physical tables | 146 |
| Parse failures | 46 statements (0.3% of executions) |

## Statement kinds

Weighted by execution, because that is what the warehouse actually ran.

| Kind | Executions | Share | Distinct statements |
|---|---:|---:|---:|
| `select` | 259,970 | 50.6% | 1,458 |
| `schema_probe` | 252,021 | 49.1% | 759 |
| `unparsed` | 1,688 | 0.3% | 45 |

## Tables by execution

Names are canonical: lowercased, and a leading `main.` dropped, so a table
referenced both ways counts once.

| Table | Executions | Share | Distinct statements | Rows read by those statements |
|---|---:|---:|---:|---:|
| `prod_homecare_actransactional_homecare.referral` | 135,701 | 26.4% | 693 | 786,220,260,042 |
| `prod_homecare_actransactional_organization.provider` | 124,742 | 24.3% | 807 | 433,476,339,388 |
| `prod_homecare_insite_directory.hmcrequest` | 122,158 | 23.8% | 635 | 989,016,392,356 |
| `prod_homecare_insite_directory.hmclead` | 91,513 | 17.8% | 505 | 743,579,436,713 |
| `prod_homecare_actransactional_billing.homecarecharge` | 58,771 | 11.4% | 157 | 306,969,315,633 |
| `prod_homecare_acreporting_reporting.cartproviderhistory` | 56,274 | 11.0% | 543 | 132,390,106,507 |
| `prod_homecare_acreporting_reporting.dimdate` | 55,455 | 10.8% | 159 | 547,476,092 |
| `prod_homecare_actransactional_homecare.lead` | 48,443 | 9.4% | 79 | 364,970,291,543 |
| `prod_homecare_actransactional_ordermanagement.order` | 45,753 | 8.9% | 465 | 100,991,063,350 |
| `prod_homecare_insite_directory.hmcscreeningresult` | 43,405 | 8.4% | 332 | 466,619,291,616 |
| `prod_homecare_actransactional_auth.users` | 41,273 | 8.0% | 173 | 98,379,650,018 |
| `prod_homecare_acreporting_reporting.dimpostalcode` | 33,552 | 6.5% | 224 | 258,778,734,827 |
| `prod_homecare_actransactional_homecare.hottransferresult` | 31,221 | 6.1% | 106 | 116,172,891,756 |
| `prod_homecare_actransactional_homecare.deliverylog` | 31,085 | 6.1% | 66 | 212,590,341,185 |
| `prod_homecare_acreporting_import.five9dailycalllogs` | 30,604 | 6.0% | 77 | 226,714,901,784 |
| `prod_homecare_actransactional_ordermanagement.orderstatustype` | 30,260 | 5.9% | 379 | 95,493,871,296 |
| `prod_homecare_actransactional_ordermanagement.orderstatusreasontype` | 30,248 | 5.9% | 374 | 95,493,414,765 |
| `prod_homecare_insite_directory.hmcprospect` | 29,429 | 5.7% | 114 | 326,316,647,690 |
| `prod_homecare_acreporting_reporting.dimtime` | 28,761 | 5.6% | 15 | 499,028,387 |
| `prod_homecare_acreporting_import.five9dailyagentstatedetails` | 27,964 | 5.4% | 64 | 151,201,444,805 |
| `prod_homecare_insite_directory.affiliate` | 27,860 | 5.4% | 227 | 281,811,783,909 |
| `prod_homecare_actransactional_homecare.hottransferresponse` | 22,416 | 4.4% | 47 | 66,847,872,174 |
| `prod_homecare_acreporting_reporting.dimcampaign` | 21,461 | 4.2% | 18 | 3,630,013,665 |
| `prod_homecare_actransactional_billing.account` | 20,895 | 4.1% | 111 | 50,367,576,498 |
| `prod_homecare_acreporting_reporting.dimtimezone` | 20,249 | 3.9% | 206 | 211,246,224,998 |
| `prod_homecare_actransactional_ordermanagement.orderprovider` | 19,073 | 3.7% | 242 | 52,064,570,009 |
| `prod_homecare_actransactional_geo.stateprovince` | 17,493 | 3.4% | 34 | 33,506,914,544 |
| `prod.dim_funnel_channel` | 16,136 | 3.1% | 115 | 262,100,690,163 |
| `prod.funnel_lead` | 16,136 | 3.1% | 115 | 262,100,690,163 |
| `prod_homecare_actransactional_organization.providerorganization` | 15,447 | 3.0% | 127 | 16,047,460,656 |

> [!NOTE]
> **The rows-read column is per statement, not per table**
>
> Query history reports rows read for the whole statement. A statement
> touching six tables contributes its full count to all six, so two tables
> that always appear together show identical totals. Use it to rank, not to
> attribute volume to one table.

## Query shapes after normalization

Power BI envelope stripped, identifiers unquoted and lowercased, literals
placeholdered — so `SELECT * FROM (q)` and `` SELECT `Col` FROM (q) `` are one shape.
**Schema probes are excluded**: stripping `LIMIT 0` would otherwise merge a
probe into the real shape it probes.

| Executions | Share of real | Tables | Shape (truncated) |
|---:|---:|---|---|
| 8,372 | 3.2% | `prod_homecare_acreporting_reporting.dimtime` | `SELECT * FROM prod_homecare_acreporting_reporting.dimtime` |
| 6,181 | 2.4% | `prod_homecare_acreporting_reporting.dimdate` | `SELECT dateid, date, dayofyear, dayofmonth, dayofweek, weekdayname, month, monthname, year, monthyearid FROM p` |
| 5,081 | 2.0% | `prod_homecare_actransactional_billing.homecarecharge`, `prod_homecare_actransactional_homecare.deliverylog`, `prod_homecare_actransactional_homecare.lead` | `WITH cte AS (SELECT DISTINCT r.referralid, r.leadid, l.hmcprospectid, hmcr.hmcrequestid, l.externalidentifier ` |
| 5,059 | 1.9% | `prod_homecare_acreporting_reporting.dimcampaign`, `prod_homecare_acreporting_reporting.factdailycampaigncost` | `WITH cte AS (SELECT fdcc.campaignkey, dc.campaignname, dc.campaignsource, dc.campaignid, CASE WHEN dc.campaign` |
| 4,867 | 1.9% | `prod_homecare_acreporting_reporting.dimdate` | `SELECT * FROM prod_homecare_acreporting_reporting.dimdate` |
| 4,125 | 1.6% | `prod_homecare_actransactional_billing.homecarecharge`, `prod_homecare_actransactional_homecare.deliverylog`, `prod_homecare_actransactional_homecare.lead` | `SELECT DISTINCT r.referralid, r.leadid, l.hmcprospectid, hmcr.hmcrequestid, l.externalidentifier AS ygl_lead_i` |
| 3,233 | 1.2% | `prod_homecare_actransactional_homecare.hottransferresponse`, `prod_homecare_actransactional_homecare.hottransferresult` | `SELECT hrt.referralid, hrt.hottransferresponseid, hr.name FROM prod_homecare_actransactional_homecare.hottrans` |
| 3,224 | 1.2% | `prod_homecare_actransactional_homecare.hottransferresponse`, `prod_homecare_actransactional_homecare.hottransferresult`, `prod_homecare_actransactional_homecare.referral` | `WITH cte AS (SELECT ref.leadid FROM prod_homecare_actransactional_homecare.hottransferresult AS hrt LEFT JOIN ` |
| 3,210 | 1.2% | `prod_homecare_acreporting_reporting.dimcampaign` | `SELECT campaignkey, campaignsource, campaignid, CASE WHEN campaignid = ? THEN ? WHEN campaignid = ? THEN ? WHE` |
| 2,971 | 1.1% | `prod_homecare_actransactional_homecare.referral` | `SELECT DISTINCT COUNT(DISTINCT ref.referralid) AS referrals, ref.orderid, CAST(ref.referredon AS DATE) AS refe` |
| 2,967 | 1.1% | `prod_homecare_acreporting_import.five9dailyagentstatedetails` | `SELECT agentstatedetailid, agent, agentgroup, agentfirstname, agentlastname, time, LAG(time) OVER (PARTITION B` |
| 2,966 | 1.1% | `prod_homecare_acreporting_import.five9dailyagentstatedetails` | `WITH cte AS (SELECT CONCAT(agentfirstname, ?, agentlastname) AS agentname, DATE_FORMAT(agentstatetime, ?) AS h` |
| 2,963 | 1.1% | `prod_homecare_acreporting_import.five9dailyagentstatedetails`, `prod_homecare_acreporting_reporting.dimdate`, `prod_homecare_acreporting_reporting.dimtime` | `WITH cte AS (SELECT agentstatedetailid, agent, agentgroup, agentfirstname, agentlastname, time, state, SECOND(` |
| 2,959 | 1.1% | `prod_homecare_acreporting_import.five9dailycalllogs` | `WITH cte AS (SELECT calllogid, agentname, timestamp, LAG(timestamp) OVER (PARTITION BY agentname, CAST(timesta` |
| 2,954 | 1.1% | `prod_homecare_acreporting_import.five9dailycalllogs` | `WITH cte AS (SELECT calllogid, agentname, timestamp, LAG(timestamp) OVER (PARTITION BY agentname, CAST(timesta` |
| 2,949 | 1.1% | `prod_homecare_insite_directory.hmclead`, `prod_homecare_insite_directory.hmcrequest` | `SELECT r.hmcrequestid, l.hmcleadid, r.postalcode, r.requeststatusid, r.createdate FROM prod_homecare_insite_di` |
| 2,948 | 1.1% | `prod_homecare_actransactional_homecare.referral`, `prod_homecare_actransactional_organization.provider` | `SELECT r.*, p.name FROM prod_homecare_actransactional_homecare.referral AS r JOIN prod_homecare_actransactiona` |
| 2,757 | 1.1% | `prod_homecare_actransactional_billing.homecarecharge` | `SELECT homecarechargeid, accountid, referralid, amount, CASE WHEN accountid = ? AND iscredit = ? THEN ? WHEN a` |
| 2,750 | 1.1% | `prod_homecare_actransactional_seniorliving.referral`, `prod_homecare_insite_directory.hmcprospect` | `SELECT referralid, providerid, homecarereferralid, r.firstname, r.lastname, r.emailaddress, phone, carerecipie` |
| 2,749 | 1.1% | `prod_homecare_actransactional_homecare.hottransferresult`, `prod_homecare_actransactional_homecare.lead`, `prod_homecare_actransactional_homecare.referral` | `SELECT hottransferresultid, htr.providerid, lid.leadid, hottransferresponseid, DATE_ADD(HOUR, -?, hottransferr` |
| 2,741 | 1.1% | `prod_homecare_actransactional_homecare.referralbilling` | `SELECT referralbillingid, referralid, providerid, amount, rate, billingperiodid, reportedon, invoicedon, modif` |
| 2,482 | 1.0% | `prod_homecare_actransactional_auth.users`, `prod_homecare_actransactional_organization.provider` | `SELECT providerid, u.firstname AS csm, u2.firstname AS hcam FROM prod_homecare_actransactional_organization.pr` |
| 2,473 | 1.0% | `prod_homecare_acreporting_reporting.dimcustomeracquisition`, `prod_homecare_acreporting_reporting.dimhomecarerequest`, `prod_homecare_actransactional_billing.homecarecharge` | `WITH cte AS (SELECT r.referralid, r.leadid, r.providerid, l.hmcprospectid, l.externalidentifier AS ygl_lead_id` |
| 2,461 | 0.9% | `prod_homecare_insite_dbo.users` | `SELECT u.userid, u.userkey, CASE WHEN u.usercode = ? THEN ? ELSE u.usercode END AS usercode, CASE WHEN u.userc` |
| 2,430 | 0.9% | `prod_homecare_acreporting_reporting.dimpostalcode`, `prod_homecare_acreporting_reporting.dimtimezone`, `prod_homecare_insite_directory.affiliate` | `WITH cte AS (SELECT DISTINCT hmcr.*, CASE WHEN hmcr.affiliateid = ? THEN ? WHEN hmcr.affiliateid IN (?) THEN ?` |
| 2,424 | 0.9% | `prod_homecare_actransactional_billing.homecarecharge` | `SELECT * FROM main.prod_homecare_actransactional_billing.homecarecharge WHERE createdon >= ?` |
| 2,422 | 0.9% | `prod_homecare_acreporting_reporting.dimtime` | `SELECT *, CASE WHEN timeid >= ? AND timeid < ? THEN ? ELSE ? END AS in_business_hours FROM prod_homecare_acrep` |
| 2,418 | 0.9% | `prod_homecare_acreporting_reporting.cartproviderhistory` | `SELECT * FROM prod_homecare_acreporting_reporting.cartproviderhistory WHERE date >= ?` |
| 2,265 | 0.9% | `prod_homecare_acreporting_reporting.cartproviderhistory`, `prod_homecare_actransactional_auth.users`, `prod_homecare_actransactional_ordermanagement.order` | `SELECT cph.providerid, cph.providername, cph.orderid, o.createdon AS ordercreatedate, MIN(date) AS firstactive` |
| 2,263 | 0.9% | `prod_homecare_actransactional_auth.users`, `prod_homecare_actransactional_billing.account`, `prod_homecare_actransactional_ordermanagement.order` | `SELECT DISTINCT o.accountid, a.name AS accountname, hcamacc.hcam FROM prod_homecare_actransactional_ordermanag` |

Collapse: 2,262 distinct statements → 911 shapes, of which **663 are real queries** and the rest are probe-only. 469,533 executions (91.4%) carried a Power BI envelope that was stripped.

## Columns actually referenced, per table

Unqualified columns in a multi-source scope are not attributed — see the
unattributed list below rather than treating this as complete.

**`prod_homecare_actransactional_homecare.referral`** — 23 columns referenced

| Column | Executions |
|---|---:|
| `hmcleadid` | 106,458 |
| `referralid` | 93,418 |
| `providerid` | 83,217 |
| `billingtypeid` | 65,978 |
| `leadid` | 61,922 |
| `createdon` | 52,920 |
| `referredon` | 49,850 |
| `orderid` | 33,813 |
| `addontypeid` | 27,123 |
| `istopoff` | 27,104 |
| `digitaljourney` | 26,880 |
| `activatedon` | 25,326 |
| `returnapproved` | 16,958 |
| `modifiedon` | 12,663 |
| `modifiedby` | 9,218 |
| `createdby` | 9,218 |
| `referralstatustypeid` | 3,939 |
| `startedcareon` | 2,333 |
| `endedcareon` | 2,333 |
| `referraldisplaystatustypeid` | 2,217 |
| `hmcleadidupdateby` | 2,217 |
| `sysstarttime` | 116 |
| `referralendcarereasontypeid` | 116 |

**`prod_homecare_actransactional_organization.provider`** — 69 columns referenced

| Column | Executions |
|---|---:|
| `providerid` | 119,659 |
| `providerorganizationid` | 34,516 |
| `name` | 29,553 |
| `ispace` | 28,585 |
| `postalcode` | 7,962 |
| `postalcodeid` | 7,956 |
| `deleted` | 4,514 |
| `orgid` | 2,555 |
| `hcamuserid` | 2,290 |
| `nowarmtransferallowed` | 2,086 |
| `providerstatustypeid` | 2,025 |
| `warmtransferphonenumber` | 2,003 |
| `billingtypeid` | 1,917 |
| `modifiedby` | 1,552 |
| `createdon` | 1,552 |
| `modifiedon` | 1,552 |
| `createdby` | 1,552 |
| `agingcareprofilepage` | 1,481 |
| `sfrecordid` | 1,481 |
| `sysstarttime` | 1,481 |
| `warmtransferafterhoursphonetypeid` | 1,481 |
| `profiledescription` | 1,481 |
| `profilesupplieddescription` | 1,481 |
| `primaryphonetypeid` | 1,481 |
| `carecoordinatoruserid` | 1,481 |

**`prod_homecare_insite_directory.hmcrequest`** — 20 columns referenced

| Column | Executions |
|---|---:|
| `hmcrequestid` | 117,184 |
| `createdate` | 101,277 |
| `affiliateid` | 56,469 |
| `requeststatusid` | 53,654 |
| `url` | 52,524 |
| `hmcprospectid` | 45,957 |
| `postalcode` | 45,419 |
| `djtypeid` | 35,897 |
| `djstepid` | 33,748 |
| `customflow` | 24,785 |
| `affiliateinquiryid` | 16,136 |
| `lastname` | 5,849 |
| `firstname` | 5,849 |
| `emailaddress` | 4,170 |
| `requeststatuscode` | 3,804 |
| `hoursperweekid` | 3,687 |
| `formname` | 3,687 |
| `leadsource` | 271 |
| `residentname` | 20 |
| `campaigngroup` | 4 |

**`prod_homecare_insite_directory.hmclead`** — 6 columns referenced

| Column | Executions |
|---|---:|
| `hmcleadid` | 88,978 |
| `hmcrequestid` | 83,441 |
| `hottransferred` | 35,817 |
| `companyid` | 7,381 |
| `createdate` | 6,152 |
| `hmcprospectid` | 5,843 |

**`prod_homecare_actransactional_billing.homecarecharge`** — 15 columns referenced

| Column | Executions |
|---|---:|
| `referralid` | 51,496 |
| `amount` | 51,034 |
| `iscredit` | 49,969 |
| `createdon` | 42,743 |
| `accountid` | 37,183 |
| `ishottransfer` | 27,697 |
| `homecarechargeid` | 10,332 |
| `entryid` | 7,252 |
| `modifiedby` | 6,813 |
| `tohomecarechargeid` | 6,813 |
| `statementid` | 6,813 |
| `modifiedon` | 6,813 |
| `createdby` | 6,813 |
| `_fivetran_deleted` | 544 |
| `_fivetran_synced` | 544 |

**`prod_homecare_acreporting_reporting.cartproviderhistory`** — 14 columns referenced

| Column | Executions |
|---|---:|
| `providerid` | 42,235 |
| `orderid` | 40,826 |
| `date` | 28,728 |
| `orderstatus` | 25,563 |
| `orderstatusreason` | 24,373 |
| `providername` | 13,704 |
| `contracttype` | 13,107 |
| `monthlycap` | 10,088 |
| `accountid` | 8,993 |
| `monthlysent` | 8,203 |
| `cartproviderhistoryid` | 2,804 |
| `csm` | 1,814 |
| `ccfail` | 880 |
| `ordername` | 273 |

**`prod_homecare_acreporting_reporting.dimdate`** — 14 columns referenced

| Column | Executions |
|---|---:|
| `date` | 35,033 |
| `year` | 29,723 |
| `monthname` | 26,547 |
| `dateid` | 26,044 |
| `dayofyear` | 26,044 |
| `month` | 26,044 |
| `dayofmonth` | 26,044 |
| `dayofweek` | 26,044 |
| `monthyearid` | 26,044 |
| `weekdayname` | 23,933 |
| `quarter` | 5,150 |
| `weekstartdate` | 4,865 |
| `weekenddate` | 4,865 |
| `weekofyear` | 4 |

**`prod_homecare_actransactional_homecare.lead`** — 10 columns referenced

| Column | Executions |
|---|---:|
| `leadid` | 48,385 |
| `externalidentifier` | 36,989 |
| `hmcprospectid` | 36,873 |
| `contactphone` | 11,512 |
| `contactemail` | 11,512 |
| `lastname` | 6,131 |
| `contactfirstname` | 6,131 |
| `firstname` | 6,131 |
| `contactlastname` | 6,131 |
| `advisor` | 555 |

**`prod_homecare_actransactional_ordermanagement.order`** — 55 columns referenced

| Column | Executions |
|---|---:|
| `orderid` | 44,862 |
| `createdon` | 36,928 |
| `orderstatustypeid` | 34,713 |
| `orderstatusreasontypeid` | 34,691 |
| `accountid` | 18,916 |
| `billingtypeid` | 11,922 |
| `servicetypeid` | 10,366 |
| `costperlead` | 7,403 |
| `name` | 6,066 |
| `prepaidtotal` | 5,324 |
| `prepaidautorenew` | 5,252 |
| `orderstatussubreasontypeid` | 4,555 |
| `orderstatusreasonnote` | 4,447 |
| `sfrecordid` | 4,443 |
| `sysstarttime` | 4,443 |
| `packagetotalcap` | 4,443 |
| `rate` | 4,443 |
| `monthlyavailable` | 4,443 |
| `matchrulesetid` | 4,443 |
| `dailysent` | 4,443 |
| `postalmatch` | 4,443 |
| `modifiedby` | 4,443 |
| `highpriority` | 4,443 |
| `totalavailable` | 4,443 |
| `activationdate` | 4,443 |

**`prod_homecare_insite_directory.hmcscreeningresult`** — 10 columns referenced

| Column | Executions |
|---|---:|
| `hmcrequestid` | 42,634 |
| `createdate` | 30,308 |
| `userid` | 29,697 |
| `hmcscreeningresultid` | 26,284 |
| `outcomeid` | 26,220 |
| `hmcprospectid` | 21,866 |
| `attemptcount` | 7,295 |
| `secondsinprospect` | 7,295 |
| `followupdate` | 782 |
| `hottransferred` | 782 |

**`prod_homecare_actransactional_auth.users`** — 2 columns referenced

| Column | Executions |
|---|---:|
| `userid` | 41,273 |
| `firstname` | 40,590 |

**`prod_homecare_acreporting_reporting.dimpostalcode`** — 6 columns referenced

| Column | Executions |
|---|---:|
| `code` | 32,085 |
| `timezoneid` | 20,249 |
| `stateprovinceid` | 13,210 |
| `postalcodeid` | 6,359 |
| `cityid` | 6,186 |
| `countryid` | 273 |

**`prod_homecare_actransactional_homecare.hottransferresult`** — 9 columns referenced

| Column | Executions |
|---|---:|
| `hottransferresponseid` | 25,728 |
| `referralid` | 22,315 |
| `leadid` | 8,906 |
| `providerid` | 7,995 |
| `modifiedby` | 5,493 |
| `createdon` | 5,493 |
| `modifiedon` | 5,493 |
| `createdby` | 5,493 |
| `hottransferresultid` | 4,936 |

**`prod_homecare_actransactional_homecare.deliverylog`** — 4 columns referenced

| Column | Executions |
|---|---:|
| `referralid` | 31,079 |
| `deliveryname` | 31,079 |
| `deliverylogid` | 31,079 |
| `deliverystatustypeid` | 31,079 |

**`prod_homecare_acreporting_import.five9dailycalllogs`** — 22 columns referenced

| Column | Executions |
|---|---:|
| `timestamp` | 30,604 |
| `agentgroup` | 14,249 |
| `calltype` | 12,766 |
| `callid` | 12,766 |
| `agentname` | 11,971 |
| `calllogid` | 11,971 |
| `agent` | 6,023 |
| `manualtime` | 58 |
| `handletime` | 58 |
| `disposition` | 58 |
| `calltime` | 58 |
| `consulttime` | 58 |
| `dialtime` | 58 |
| `dnis` | 58 |
| `dispositionpath` | 58 |
| `totalqueuetime` | 58 |
| `aftercallworktime` | 58 |
| `skill` | 58 |
| `campaign` | 58 |
| `talktime` | 58 |
| `holdtime` | 58 |
| `ringtime` | 58 |

**`prod_homecare_actransactional_ordermanagement.orderstatustype`** — 2 columns referenced

| Column | Executions |
|---|---:|
| `orderstatustypeid` | 30,260 |
| `name` | 30,260 |

**`prod_homecare_actransactional_ordermanagement.orderstatusreasontype`** — 2 columns referenced

| Column | Executions |
|---|---:|
| `orderstatusreasontypeid` | 30,248 |
| `name` | 29,652 |

**`prod_homecare_insite_directory.hmcprospect`** — 17 columns referenced

| Column | Executions |
|---|---:|
| `hmcprospectid` | 23,942 |
| `emailaddress` | 18,391 |
| `lastname` | 13,578 |
| `firstname` | 13,578 |
| `slppsourcetypeid` | 10,682 |
| `disqualifier` | 7,331 |
| `disqualifierreason` | 7,311 |
| `hmcwhencareneededid` | 4,301 |
| `hoursperweekid` | 4,281 |
| `relation` | 3,687 |
| `age` | 3,687 |
| `besttimetocall` | 3,687 |
| `gender` | 3,687 |
| `createdate` | 3,159 |
| `carebudget` | 594 |
| `postalcode` | 129 |
| `residentname` | 20 |

**`prod_homecare_acreporting_reporting.dimtime`** — 1 columns referenced

| Column | Executions |
|---|---:|
| `timeid` | 4,848 |

**`prod_homecare_acreporting_import.five9dailyagentstatedetails`** — 14 columns referenced

| Column | Executions |
|---|---:|
| `agentgroup` | 27,964 |
| `agent` | 27,964 |
| `detaildate` | 27,964 |
| `agentstatetime` | 27,964 |
| `state` | 27,964 |
| `agentfirstname` | 25,785 |
| `agentlastname` | 25,785 |
| `time` | 22,037 |
| `agentstatedetailid` | 20,770 |
| `minute` | 17,776 |
| `hours` | 17,776 |
| `reasoncode` | 16,089 |
| `mediaavailability` | 8,922 |
| `skillavailability` | 8,922 |

**`prod_homecare_insite_directory.affiliate`** — 2 columns referenced

| Column | Executions |
|---|---:|
| `affiliatename` | 27,860 |
| `affiliateid` | 27,860 |

**`prod_homecare_actransactional_homecare.hottransferresponse`** — 7 columns referenced

| Column | Executions |
|---|---:|
| `hottransferresponseid` | 20,441 |
| `name` | 13,992 |
| `hottransferresponsetypeid` | 1,746 |
| `_fivetran_deleted` | 1,746 |
| `_fivetran_synced` | 1,746 |
| `createdon` | 1,746 |
| `createdby` | 1,746 |

**`prod_homecare_acreporting_reporting.dimcampaign`** — 4 columns referenced

| Column | Executions |
|---|---:|
| `campaignkey` | 21,461 |
| `campaignname` | 21,461 |
| `campaignsource` | 20,903 |
| `campaignid` | 20,342 |

**`prod_homecare_actransactional_billing.account`** — 8 columns referenced

| Column | Executions |
|---|---:|
| `accountid` | 20,450 |
| `name` | 7,926 |
| `accountstatusreasontypeid` | 6,544 |
| `accountstatustypeid` | 648 |
| `iscorporateaccount` | 108 |
| `paymentmethodtypeid` | 57 |
| `accountstatusreasonnote` | 44 |
| `balance` | 18 |

**`prod_homecare_acreporting_reporting.dimtimezone`** — 2 columns referenced

| Column | Executions |
|---|---:|
| `timezoneid` | 20,249 |
| `systimezone` | 3,741 |

**`prod_homecare_actransactional_ordermanagement.orderprovider`** — 19 columns referenced

| Column | Executions |
|---|---:|
| `orderid` | 19,073 |
| `providerid` | 18,637 |
| `monthlycap` | 1,567 |
| `sfrecordid` | 1,481 |
| `monthlyavailable` | 1,481 |
| `modifiedby` | 1,481 |
| `totalavailable` | 1,481 |
| `htmonthlycap` | 1,481 |
| `modifiedon` | 1,481 |
| `_fivetran_synced` | 1,481 |
| `orderproviderid` | 1,481 |
| `totalcap` | 1,481 |
| `totalsent` | 1,481 |
| `createdby` | 1,481 |
| `createdon` | 1,481 |
| `htmonthlysent` | 1,481 |
| `monthlysent` | 1,481 |
| `_fivetran_deleted` | 1,481 |
| `dmproviderid` | 1,481 |

**`prod_homecare_actransactional_geo.stateprovince`** — 4 columns referenced

| Column | Executions |
|---|---:|
| `stateprovinceid` | 14,545 |
| `iso2code` | 6,123 |
| `name` | 4,417 |
| `countryid` | 436 |

**`prod.dim_funnel_channel`** — 5 columns referenced

| Column | Executions |
|---|---:|
| `lt_form_submit_channel` | 16,136 |
| `lt_form_submit_domain` | 16,136 |
| `lt_form_submit_utm_campaign` | 16,136 |
| `funnel_lead_id` | 16,136 |
| `lt_form_submit_sub_channel` | 16,136 |

**`prod.funnel_lead`** — 7 columns referenced

| Column | Executions |
|---|---:|
| `inquiry_created_at` | 16,136 |
| `beacon_inquiry_id` | 16,136 |
| `close_inquiry_reason` | 16,136 |
| `status` | 16,136 |
| `is_default_exclusion` | 16,136 |
| `funnel_lead_id` | 16,136 |
| `inquiry_method` | 16,136 |

**`prod_homecare_actransactional_organization.providerorganization`** — 2 columns referenced

| Column | Executions |
|---|---:|
| `providerorganizationid` | 15,376 |
| `name` | 15,202 |

### Unattributed columns

Referenced without a qualifier in a scope with several sources.

| Column | Executions |
|---|---:|
| `providerid` | 106,317 |
| `rn` | 93,171 |
| `orderid` | 88,933 |
| `referralid` | 88,145 |
| `date` | 87,256 |
| `hmcrequestid` | 79,256 |
| `createdon` | 78,061 |
| `referralstatustypeid` | 64,696 |
| `referredon` | 63,842 |
| `hmcprospectid` | 59,640 |
| `minute` | 58,809 |
| `billingtypeid` | 56,396 |
| `returnapproved` | 55,882 |
| `createdby` | 54,807 |
| `_fivetran_deleted` | 54,141 |
| `_fivetran_synced` | 54,141 |
| `modifiedon` | 51,081 |
| `hours` | 47,400 |
| `timeid` | 46,906 |
| `leadid` | 46,078 |
| `modifiedby` | 44,017 |
| `adjchannel` | 43,174 |
| `postalcode` | 41,238 |
| `affiliateid` | 41,167 |
| `hmcleadid` | 40,796 |
| `hcamuserid` | 40,698 |
| `accountspecialistuserid` | 40,698 |
| `dateid` | 40,549 |
| `outcomeid` | 38,258 |
| `requeststatusid` | 37,557 |

## Join graph

What the reporting layer actually joins, and on what.

| Left | Right | Keys | Side | Executions |
|---|---|---|---|---:|
| `prod_homecare_actransactional_homecare.referral` | `prod_homecare_insite_directory.hmclead` | `hmcleadid` = `hmcleadid` | LEFT | 60,123 |
| `prod_homecare_insite_directory.hmclead` | `prod_homecare_insite_directory.hmcrequest` | `hmcrequestid` = `hmcrequestid` | LEFT | 59,437 |
| `prod_homecare_actransactional_homecare.referral` | `prod_homecare_actransactional_organization.provider` | `providerid` = `providerid` | LEFT | 54,726 |
| `prod_homecare_actransactional_billing.homecarecharge` | `prod_homecare_actransactional_homecare.referral` | `referralid` = `referralid` | LEFT | 43,806 |
| `prod_homecare_actransactional_homecare.lead` | `prod_homecare_actransactional_homecare.referral` | `leadid` = `leadid` | LEFT | 42,370 |
| `prod_homecare_acreporting_reporting.cartproviderhistory` | `prod_homecare_actransactional_organization.provider` | `providerid` = `providerid` | LEFT | 32,761 |
| `prod_homecare_actransactional_ordermanagement.order` | `prod_homecare_actransactional_ordermanagement.orderstatustype` | `orderstatustypeid` = `orderstatustypeid` | LEFT | 30,242 |
| `prod_homecare_actransactional_ordermanagement.order` | `prod_homecare_actransactional_ordermanagement.orderstatusreasontype` | `orderstatusreasontypeid` = `orderstatusreasontypeid` | LEFT | 30,230 |
| `prod_homecare_acreporting_reporting.cartproviderhistory` | `prod_homecare_actransactional_ordermanagement.order` | `orderid` = `orderid` | LEFT | 28,181 |
| `prod_homecare_insite_directory.affiliate` | `prod_homecare_insite_directory.hmcrequest` | `affiliateid` = `affiliateid` | LEFT | 24,676 |
| `prod_homecare_acreporting_reporting.dimpostalcode` | `prod_homecare_acreporting_reporting.dimtimezone` | `timezoneid` = `timezoneid` | LEFT | 20,249 |
| `prod_homecare_actransactional_homecare.hottransferresponse` | `prod_homecare_actransactional_homecare.hottransferresult` | `hottransferresponseid` = `hottransferresponseid` | LEFT | 18,695 |
| `prod.dim_funnel_channel` | `prod.funnel_lead` | `funnel_lead_id` = `funnel_lead_id` | LEFT | 16,136 |
| `prod_homecare_insite_directory.hmclead` | `prod_homecare_insite_directory.hmcrequest` | `hmcrequestid` = `hmcrequestid` | INNER | 15,942 |
| `prod_homecare_actransactional_ordermanagement.order` | `prod_homecare_actransactional_ordermanagement.orderprovider` | `orderid` = `orderid` | LEFT | 15,678 |
| `prod_homecare_actransactional_organization.provider` | `prod_homecare_actransactional_organization.providerorganization` | `providerorganizationid` = `providerorganizationid` | LEFT | 15,045 |
| `prod_homecare_actransactional_billing.account` | `prod_homecare_actransactional_ordermanagement.order` | `accountid` = `accountid` | LEFT | 14,384 |
| `prod_homecare_actransactional_ordermanagement.orderprovider` | `prod_homecare_actransactional_organization.provider` | `providerid` = `providerid` | LEFT | 14,250 |
| `prod_homecare_actransactional_homecare.hottransferresult` | `prod_homecare_actransactional_homecare.referral` | `referralid` = `referralid` | LEFT | 11,673 |
| `prod_homecare_insite_directory.hmcprospect` | `prod_homecare_insite_directory.hmcrequest` | `hmcprospectid` = `hmcprospectid` | LEFT | 11,043 |
| `prod_homecare_acreporting_reporting.dimcampaign` | `prod_homecare_acreporting_reporting.factdailycampaigncost` | `campaignkey` = `campaignkey` | LEFT | 10,685 |
| `prod_homecare_actransactional_homecare.referral` | `prod_homecare_insite_directory.hmclead` | `hmcleadid` = `hmcleadid` | INNER | 10,682 |
| `prod_homecare_actransactional_seniorliving.referral` | `prod_homecare_insite_directory.hmcprospect` | `lastname` = `lastname` | LEFT | 10,682 |
| `prod_homecare_actransactional_seniorliving.referral` | `prod_homecare_insite_directory.hmcprospect` | `emailaddress` = `emailaddress` | LEFT | 10,682 |
| `prod_homecare_actransactional_seniorliving.referral` | `prod_homecare_insite_directory.hmcprospect` | `firstname` = `firstname` | LEFT | 10,682 |
| `prod_homecare_acreporting_reporting.dimcustomeracquisition` | `prod_homecare_acreporting_reporting.dimhomecarerequest` | `customeracquisitionkey` = `customeracquisitionkey` | LEFT | 9,822 |
| `prod_homecare_actransactional_homecare.hottransferresult` | `prod_homecare_actransactional_homecare.referral` | `leadid` = `leadid` | LEFT | 8,906 |
| `prod_homecare_acreporting_reporting.dimhomecarerequest` | `prod_homecare_insite_directory.hmcrequest` | `requestid` = `hmcrequestid` | LEFT | 8,330 |
| `prod_homecare_acreporting_reporting.cartproviderhistory` | `prod_homecare_actransactional_organization.providerservicecoverage` | `providerid` = `providerid` | LEFT | 7,444 |
| `prod_homecare_insite_directory.hmclead` | `prod_homecare_insite_directory.lead` | `hmcleadid` = `hmcleadid` | LEFT | 7,381 |

## SQL Server function spellings

Found by scanning the raw text, because sqlglot canonicalizes these while
parsing -- `CHARINDEX` becomes `LOCATE`, `getdate()` becomes
`CURRENT_TIMESTAMP` -- so a parse-tree scan never sees them.

`alias` means Databricks accepts the spelling and the statement runs
normally; the rows-returned column is the evidence. `no equivalent` means
Databricks has no function of that name, so those statements do error.

| Function | Class | Executions | Rows returned | Statement kinds | Example |
|---|---|---:|---:|---|---|
| `charindex` | alias | 74,463 | 356,095,166,282 | select (37,258), schema_probe (37,143), unparsed (62) | `select `OnCall`, `TimeDateID`, `DimDate`, `DimTimeID`, `Mont` |
| `getdate` | alias | 54,113 | 10,458,606,671 | schema_probe (27,185), select (26,799), unparsed (129) | `select `OnCall`, `TimeDateID`, `DimDate`, `DimTimeID`, `Mont` |
| `dateadd` | alias | 47,156 | 16,675,792,078 | select (23,598), schema_probe (23,558) | `select `accountid`, `amount`, `PaymentDate` from ( WITH CTE ` |
| `len` | alias | 27,979 | 37,807,768,128 | schema_probe (13,988), select (13,929), unparsed (62) | `select * from ( SELECT ReferralNoteID ,ReferralProcessStageI` |

> [!NOTE]
> **These run correctly -- portability signal, not a defect**
>
> Every spelling found is one Databricks supports as an alias, and the
> rows-returned column confirms the statements execute. The 11
> unsupported spellings scanned for (`choose`, `datediff_big`, `datename`, `eomonth`, `getutcdate`, `newid`, `patindex`, `scope_identity`, `square`, `stuff`, `sysdatetime`)
> appear nowhere. So nothing here needs fixing: it is a provenance
> signal -- SQL authored against SQL Server, still carrying its
> original spelling. Worth normalizing only to keep one dialect.

## Most-used functions

These are sqlglot's canonical node names, not Databricks spellings, so
don't look them up in the Databricks docs: `str_position` is `charindex` /
`locate`, `time_to_str` is `date_format`, `ts_or_ds_to_date` is `to_date`.
`case` and `if` track the same expression and so report the same count.

| Function | Executions |
|---|---:|
| `and` | 331,719 |
| `if` | 287,023 |
| `case` | 287,023 |
| `cast` | 170,532 |
| `or` | 165,305 |
| `row_number` | 105,548 |
| `concat` | 88,015 |
| `time_str_to_time` | 81,759 |
| `time_to_str` | 81,759 |
| `str_position` | 74,329 |
| `left` | 72,149 |
| `lower` | 69,470 |
| `ts_or_ds_to_date` | 65,417 |
| `count` | 53,765 |
| `current_timestamp` | 53,056 |
| `timestamp_add` | 52,563 |
| `lag` | 48,711 |
| `datediff` | 44,078 |
| `substring` | 43,667 |
| `sum` | 37,569 |
| `trim` | 31,777 |
| `min` | 28,103 |
| `length` | 27,917 |
| `right` | 27,712 |
| `timestamp_trunc` | 24,462 |
| `year` | 23,844 |
| `month` | 23,012 |
| `max` | 20,682 |
| `convert_timezone` | 20,335 |
| `timestampdiff` | 11,913 |

## Predicate columns

Filter and join columns — the evidence for clustering and partitioning.

| Column | Executions |
|---|---:|
| `createdate` | 100,261 |
| `rn` | 89,177 |
| `hmcleadid` | 69,582 |
| `date` | 62,247 |
| `referredon` | 53,147 |
| `createdon` | 47,553 |
| `agentgroup` | 47,311 |
| `billingtypeid` | 47,281 |
| `orderstatusreason` | 39,408 |
| `outcomeid` | 38,532 |
| `orderstatus` | 35,326 |
| `contracttype` | 34,521 |
| `deliveryname` | 31,085 |
| `detaildate` | 27,964 |
| `agentstatetime` | 27,964 |
| `timestamp` | 24,621 |
| `firstname` | 23,152 |
| `hmcrequestid` | 19,895 |
| `status` | 19,199 |
| `state` | 19,042 |
| `requeststatusid` | 17,945 |
| `providerid` | 16,568 |
| `inquiry_created_at` | 16,136 |
| `close_inquiry_reason` | 16,136 |
| `is_default_exclusion` | 16,136 |
| `affiliateid` | 15,685 |
| `referralid` | 15,384 |
| `accountid` | 14,087 |
| `hottransferresponseid` | 13,861 |
| `servicetypeid` | 13,318 |

## Heaviest statements by rows read

| Rows read | Executions | Avg ms | Tables | SQL |
|---:|---:|---:|---|---|
| 61,683,573,312 | 1,149 | 10,209 | `prod.dim_funnel_channel`, `prod.funnel_lead`, `prod_homecare_acreporting_reporting.dimpostalcode` | `select `HMCRequestID`, `HMCProspectID`, `disqualifier`, `Channel`, `userid`, `requeststatu` |
| 61,269,440,363 | 4,125 | 18,146 | `prod_homecare_actransactional_billing.homecarecharge`, `prod_homecare_actransactional_homecare.deliverylog`, `prod_homecare_actransactional_homecare.lead` | `select `ReferralID`, `LeadID`, `HMCProspectID`, `HMCRequestID`, `YGL_Lead_ID`, `ProviderID` |
| 58,248,225,552 | 2,059 | 80,434 | `prod_homecare_acreporting_import.five9dailyagentstatedetails`, `prod_homecare_acreporting_import.five9dailycalllogs` | `select `callid`, `First_LogIn`, `agent`, `Date`, `hours`, `minute`, `TimeID`, `detaildate`` |
| 56,961,312,351 | 1,847 | 28,103 | `prod_homecare_acreporting_reporting.dimhomecarerequeststatus`, `prod_homecare_actransactional_homecare.leadhoursperweek`, `prod_homecare_actransactional_homecare.referral` | `select `hmcrequestid`, `hmcprospectid`, `url`, cast(`createdate` as DATE) as `C1`, `formna` |
| 48,891,039,523 | 3,224 | 7,475 | `prod_homecare_actransactional_homecare.hottransferresponse`, `prod_homecare_actransactional_homecare.hottransferresult`, `prod_homecare_actransactional_homecare.referral` | `select `leadid`, `Family_HT_Attempts`, `Accepted_HT_Families` from ( With CTE AS ( Select ` |
| 47,337,462,809 | 1,905 | 17,817 | `prod.dim_funnel_channel`, `prod.funnel_lead`, `prod_homecare_insite_directory.affiliate` | `select `HMCRequestID`, `HMCProspectID`, `Flow`, `lastoutcomeid`, `affiliateID`, `dma`, `Ch` |
| 45,636,463,188 | 1,481 | 23,555 | `prod_homecare_actransactional_homecare.lead`, `prod_homecare_actransactional_homecare.referral`, `prod_homecare_insite_directory.companyinfo` | `select `HMCProspectID`, cast(`ReferralDate` as DATE) as `C1`, `NumProv`, `ActDate`, `HMCLe` |
| 43,968,850,006 | 1,152 | 16,153 | `prod_homecare_actransactional_homecare.referral`, `prod_homecare_insite_directory.hmclead`, `prod_homecare_insite_directory.hmcoutcomes` | `select `hmcrequestid`, `hmcprospectid`, `ContactName`, `RequestCreateDate`, `phonenumber`,` |
| 39,255,094,078 | 3,234 | 12,770 | `prod_homecare_actransactional_billing.homecarecharge`, `prod_homecare_actransactional_homecare.deliverylog`, `prod_homecare_actransactional_homecare.lead` | `select `ReferralID`, `LeadID`, `HMCProspectID`, `HMCRequestID`, `YGL_Lead_ID`, `ProviderID` |
| 38,342,968,179 | 2,471 | 6,093 | `prod_homecare_acreporting_reporting.dimcustomeracquisition`, `prod_homecare_acreporting_reporting.dimhomecarerequest`, `prod_homecare_actransactional_billing.homecarecharge` | `select `ReferralID`, `LeadID`, `ProviderID`, `ActDate`, `NumProv`, cast(`ReferredOn` as DA` |
| 37,753,483,651 | 2,064 | 9,862 | `prod_homecare_acreporting_reporting.dimpostalcode`, `prod_homecare_acreporting_reporting.dimtimezone`, `prod_homecare_insite_directory.hmcprospect` | `select `HMCRequestID`, `HMCProspectID`, `disqualifier`, `userid`, `Time`, `disqualifierfix` |
| 37,424,038,317 | 1,855 | 15,975 | `prod_homecare_acreporting_import.five9dailycalllogs` | `select `CallId`, `Timestamp`, `Agent`, `AgentName`, `CallType`, `Disposition`, `Dispositio` |
| 37,197,983,896 | 1,083 | 17,210 | `prod_homecare_acreporting_import.five9dailycalllogs` | `select `CallId`, `Timestamp`, `hours`, `minute`, `((lateralAliasReference(hours) * 100) + ` |
| 31,835,091,772 | 2,212 | 6,909 | `prod_homecare_acreporting_reporting.diminternaluser`, `prod_homecare_acreporting_reporting.facthomecarerequestsummary`, `prod_homecare_actransactional_seniorliving.referral` | `select `ReferralID`, `ProviderID`, `HomeCareReferralID`, `FirstName`, `LastName`, `EmailAd` |
| 29,215,800,607 | 1,848 | 17,543 | `prod_homecare_actransactional_billing.homecarecharge`, `prod_homecare_actransactional_homecare.deliverylog`, `prod_homecare_actransactional_homecare.lead` | `select `ReferralID`, `LeadID`, `HMCProspectID`, `HMCRequestID`, `YGL_Lead_ID`, `ProviderID` |
| 28,542,474,348 | 992 | 18,219 | `prod_homecare_actransactional_homecare.lead`, `prod_homecare_actransactional_homecare.referral`, `prod_homecare_insite_directory.companyinfo` | `select `HMCProspectID`, cast(`ReferralDate` as DATE) as `C1`, `NumProv`, `ActDate`, `HMCLe` |
| 27,689,472,283 | 1,670 | 18,720 | `prod_homecare_actransactional_billing.homecarecharge`, `prod_homecare_actransactional_homecare.deliverylog`, `prod_homecare_actransactional_homecare.lead` | `select `ReferralID`, `LeadID`, `HMCProspectID`, `HMCRequestID`, `YGL_Lead_ID`, `ProviderID` |
| 24,517,012,945 | 2,430 | 36,957 | `prod_homecare_acreporting_reporting.dimpostalcode`, `prod_homecare_acreporting_reporting.dimtimezone`, `prod_homecare_insite_directory.affiliate` | `select `hmcrequestid`, `firstname`, `gender`, `leadtype`, `formname`, cast(`createdate` as` |
| 23,211,511,074 | 536 | 50,481 | `grace.grace_prod_public.consumer`, `grace.grace_prod_public.lead`, `grace.grace_prod_public.referral` | `select `HMCRequestID`, `HMCProspectID`, `Flow`, `lastoutcomeid`, `affiliateID`, `Channel`,` |
| 23,208,442,030 | 1,013 | 21,693 | `prod.dim_funnel_channel`, `prod.funnel_lead`, `prod_homecare_insite_directory.affiliate` | `select `HMCRequestID`, `HMCProspectID`, `Flow`, `lastoutcomeid`, `affiliateID`, `Channel`,` |

## Tables per dataset

| Dataset | Tables | Executions |
|---|---:|---:|
| `f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0` | 28 | 149,797 |
| `3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d` | 42 | 120,502 |
| `aa36e346-e2cc-4210-a366-8c48278fcdbd` | 37 | 112,572 |
| `728529db-9b31-4ce3-9fd4-4fdf844d7334` | 27 | 98,294 |
| `b23c969a-4a6b-4d76-bea0-6e46dcac27aa` | 36 | 78,675 |
| `b19514eb-b858-44d5-81a1-2c1a2e9f1483` | 29 | 70,838 |
| `7d311f0f-60c1-430c-b0dc-ad78a0550d05` | 29 | 64,517 |
| `75a0183c-2c90-4d23-9c69-cdb19108448e` | 21 | 53,659 |
| `c65e1078-f986-4629-8d3f-50f7370b5719` | 26 | 52,856 |
| `eda315a6-a542-4102-b6ce-3551c75b1bdd` | 28 | 42,803 |
| `af940fd5-99cd-4e93-a620-822230b10ce8` | 11 | 42,113 |
| `da74b405-09e2-41e3-bed6-583fc3c4acae` | 17 | 39,461 |
| `a16a1e37-9a12-408d-ad05-9ea2571cb037` | 15 | 30,383 |
| `6af1511e-31cf-4529-b5ce-58c26f7ebcc8` | 27 | 29,238 |
| `36a8e73a-5aae-46e5-a621-b847af424af7` | 29 | 28,183 |
| `e9d48e9c-bb12-4860-b411-434978fd49fe` | 24 | 22,977 |
| `fe02549c-24f9-4a63-88e9-89efbaf400ed` | 18 | 22,353 |
| `0e88940d-a1f3-4c92-b384-af62bb64e2e4` | 22 | 16,435 |
| `498b5b81-ab8e-41ee-8683-f1b802ec8635` | 15 | 12,078 |
| `2cceff05-ca68-44c0-8f76-545dd698db36` | 13 | 11,826 |
| `2bcc3123-33ee-429b-9609-ef5534b5441c` | 24 | 6,733 |
| `95e62086-9ac7-4ac5-81fb-5c045316c4fc` | 13 | 4,656 |
| `146cde38-6c07-42a1-97e7-30a21a563d0d` | 6 | 2,953 |
| `c38af845-cf82-47a4-9373-12845eb51d16` | 9 | 2,951 |
| `c510df23-2b0d-4820-90d4-7aa0d70d29f0` | 20 | 2,339 |
| `392d03ed-c952-4264-963d-fc700b0edcda` | 16 | 1,049 |
| `981c2152-e626-4c9c-a7e3-c5876773579b` | 5 | 782 |
| `6f367367-19b7-4314-b324-b8f6a041aa2e` | 6 | 739 |
| `9385d9b6-44eb-425a-97c7-734e023fef3f` | 11 | 93 |
| `63ec2920-bf98-4110-937f-db0c27aa74bd` | 6 | 30 |

## Parse failures

sqlglot could not parse these. Each is either genuinely invalid or a
dialect gap — check before concluding the statement is broken.

| Executions | Error | SQL |
|---:|---|---|
| 1,473 | Expecting ). Line 16, Col: 96. | `select `dateid`, `quarter`, `dayofweek`, `weekenddate`, `dayofmonth`, `monthyear` |
| 121 | Invalid expression / Unexpected token. Line 20, Col: 31. | `select `dateid`, `quarter`, `dayofweek`, `dayofmonth`, `monthyearid`, `date`, `m` |
| 20 | Required keyword: 'this' missing for <class 'sqlglot.expressions.core.Column'>. Line 237, Col: 34. | `select `HMCRequestID`, `HMCProspectID`, `disqualifier`, `userid`, `Time`, `disqu` |
| 9 | Required keyword: 'this' missing for <class 'sqlglot.expressions.core.Column'>. Line 224, Col: 20. | `select `HMCRequestID`, `HMCProspectID`, `Flow`, `lastoutcomeid`, `affiliateID`, ` |
| 9 | Error tokenizing 'Email' AND url LIKE '%specialofferb%...(truncated' | `select `HMCRequestID`, `HMCProspectID`, `Flow`, `lastoutcomeid`, `affiliateID`, ` |
| 7 | Invalid expression / Unexpected token. Line 19, Col: 31. | `select `dateid`, `quarter`, `dayofweek`, `dayofmonth`, `monthyearid`, `date`, `m` |
| 3 | Required keyword: 'this' missing for <class 'sqlglot.expressions.core.Column'>. Line 232, Col: 35. | `select `HMCRequestID`, `HMCProspectID`, `Flow`, `lastoutcomeid`, `affiliateID`, ` |
| 3 | Required keyword: 'this' missing for <class 'sqlglot.expressions.core.Column'>. Line 221, Col: 14. | `select `HMCRequestID`, `HMCProspectID`, `Flow`, `lastoutcomeid`, `affiliateID`, ` |
| 3 | Error tokenizing 'ampaignID = '20159729695' THEN 'Mobi...(truncated' | `select * from ( WITH CTE3 AS (WITH CTE2 AS (WITH CTE AS (SELECT distinct hmcr.HM` |
| 2 | Required keyword: 'this' missing for <class 'sqlglot.expressions.core.Column'>. Line 217, Col: 9. | `select `HMCRequestID`, `HMCProspectID`, `Flow`, `lastoutcomeid`, `affiliateID`, ` |
| 2 | Required keyword: 'this' missing for <class 'sqlglot.expressions.core.Column'>. Line 183, Col: 145. | `select `SLRl`, `hmcrequestid`, `Funnel`, `createdate`, `RequestStatusId`, `AdjCh` |
| 2 | Expecting ). Line 1, Col: 66. | `select { fn timestampadd(SQL_TSI_DAY, `AccountID`, {d '1899-12-30'}) } as `C1`, ` |
| 2 | Error tokenizing 'HEN 'Newsletter B' | `select * from ( WITH CTE3 AS (WITH CTE2 AS (WITH CTE AS (SELECT distinct hmcr.HM` |
| 1 | Required keyword: 'true' missing for <class 'sqlglot.expressions.functions.If'>. Line 172, Col: 52. | `select `Time`, `SLRl`, `hmcrequestid`, `Funnel`, `createdate`, `RequestStatusId`` |
| 1 | Required keyword: 'this' missing for <class 'sqlglot.expressions.core.Column'>. Line 218, Col: 27. | `select `HMCRequestID`, `HMCProspectID`, `Flow`, `lastoutcomeid`, `affiliateID`, ` |
| 1 | Required keyword: 'this' missing for <class 'sqlglot.expressions.core.Column'>. Line 205, Col: 2. | `select `HMCRequestID`, `HMCProspectID`, `disqualifier`, `Channel`, `userid`, `re` |
| 1 | Required keyword: 'this' missing for <class 'sqlglot.expressions.core.Column'>. Line 205, Col: 10. | `select `HMCRequestID`, `HMCProspectID`, `Flow`, `lastoutcomeid`, `affiliateID`, ` |
| 1 | Required keyword: 'this' missing for <class 'sqlglot.expressions.core.Column'>. Line 202, Col: 96. | `select `HMCRequestID`, `HMCProspectID`, `disqualifier`, `Channel`, `userid`, `re` |
| 1 | Required keyword: 'this' missing for <class 'sqlglot.expressions.core.Column'>. Line 187, Col: 35. | `select * from ( WITH CTE2 AS( WITH CTEB AS( WITH CTEA AS ( WITH CTE1 AS ( WITH C` |
| 1 | Required keyword: 'this' missing for <class 'sqlglot.expressions.core.Column'>. Line 171, Col: 26. | `select `Time`, `SLRl`, `hmcrequestid`, `Funnel`, `createdate`, `RequestStatusId`` |
| 1 | Required keyword: 'this' missing for <class 'sqlglot.expressions.core.Column'>. Line 158, Col: 8. | `select `Time`, `SLRl`, `hmcrequestid`, `Funnel`, `createdate`, `RequestStatusId`` |
| 1 | Required keyword: 'expression' missing for <class 'sqlglot.expressions.core.EQ'>. Line 216, Col: 16. | `select `HMCRequestID`, `HMCProspectID`, `Flow`, `lastoutcomeid`, `affiliateID`, ` |
| 1 | Required keyword: 'expression' missing for <class 'sqlglot.expressions.core.Dot'>. Line 253, Col: 32. | `select `HMCRequestID`, `HMCProspectID`, `disqualifier`, `userid`, `Time`, `disqu` |
| 1 | Required keyword: 'expression' missing for <class 'sqlglot.expressions.core.Dot'>. Line 219, Col: 24. | `select `HMCRequestID`, `HMCProspectID`, `Flow`, `lastoutcomeid`, `affiliateID`, ` |
| 1 | Required keyword: 'expression' missing for <class 'sqlglot.expressions.core.Dot'>. Line 187, Col: 55. | `select * from ( WITH CTE2 AS( WITH CTEB AS( WITH CTEA AS ( WITH CTE1 AS ( WITH C` |
