-- Power BI query shape 25 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,430
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             24,517,012,945
-- Rows returned         2,868,052,945
-- Avg duration          36,957 ms
-- Power BI datasets     2cceff05-ca68-44c0-8f76-545dd698db36
-- Tables                prod_homecare_acreporting_reporting.dimpostalcode, prod_homecare_acreporting_reporting.dimtimezone, prod_homecare_insite_directory.affiliate, prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcscreeningresult
--
-- Verbatim as executed; no Power BI envelope to strip.

select `hmcrequestid`,
    `firstname`,
    `gender`,
    `leadtype`,
    `formname`,
    cast(`createdate` as DATE) as `C1`,
    `sessionid`,
    `requeststatusid`,
    `affiliateid`,
    `affiliateinquiryid`,
    `relation`,
    `userkey`,
    `culturallanguageaccommodations`,
    `campaigngroup`,
    `modifydate`,
    `djstepid`,
    `processleadqueue`,
    `sfrecordid`,
    `readytoprescreen`,
    `postalcode`,
    `besttimetocall`,
    `parenthmcrequestid`,
    `customflow`,
    `hmcprospectid`,
    `whencareisneededid`,
    `residentname`,
    `submissiondetails`,
    `djtypeid`,
    `emailaddress`,
    `url`,
    `lastname`,
    `hoursperweekid`,
    `campaignkeyword`,
    `formverificationkey`,
    `firstlookemailcompanyid`,
    `requestid`,
    `originalnote`,
    `requeststatuscode`,
    `leadsource`,
    `leadinfoid`,
    `leadsearchlocid`,
    `slaemailaddress`,
    `screenqueueat`,
    `age`,
    `_fivetran_deleted`,
    `_fivetran_synced`,
    `AdjChannel`,
    `Adjust_CreateDate`,
    `affiliatename`,
    `userid`,
    `hours`,
    `minute`,
    `TimeID`,
    `Time`,
    `Source`,
    `userid1`,
    { fn concat(`AdjChannel`, `Source`) } as `C2`
from 
(
    WITH CTE AS (Select DISTINCT hmcr.*
,CASE  WHEN hmcr.affiliateid = 72 THEN 'APFM'
          WHEN hmcr.affiliateID IN (98,100,101,102,103,104,105,109,110,123,124,125,126,127,128,129,130,131,132) THEN 'SEM'
          WHEN hmcr.affiliateID = 87 THEN 'SEO'
          WHEN hmcr.affiliateID = 92 THEN 'SEO'
          WHEN hmcr.affiliateID IN (90,107,113,133) THEN 'Affiliates'
          WHEN hmcr.affiliateID IN (93,94,95,96,97,99,106,108,117,119,136,121,136)THEN 'APFM DQ'
          WHEN hmcr.url LIKE '%msclkid%' OR hmcr.url LIKE '%gclid%' OR hmcr.url LIKE '%campaignid%' THEN 'SEM'
          WHEN hmcr.url LIKE '%email%' OR hmcr.affiliateID = 111 then 'Email'
          WHEN hmcr.affiliateid IN (6,49) OR hmcr.url LIKE '%/local%' OR hmcr.url LIKE '%local/%' THEN 'SEO'
          WHEN hmcr.affiliateID = 112 THEN 'SEO'
          WHEN hmcr.url IS NULL AND hmcr.affiliateid IN (36,47) THEN 'Unknown'
        ELSE 'Affiliates'
        END AdjChannel
 ,CASE WHEN tz.timezoneid = 4 then convert_timezone('America/Detroit','Pacific/Honolulu',CAST(hmcr.createdate as TIMESTAMP))
              WHEN tz.timezoneid = 6 then convert_timezone('America/Detroit','US/Alaska',CAST(hmcr.createdate as TIMESTAMP))
              WHEN tz.timezoneid = 10 then convert_timezone('America/Detroit','US/Pacific',CAST(hmcr.createdate as TIMESTAMP))
              WHEN tz.timezoneid = 13 then convert_timezone('America/Detroit','America/Boise',CAST(hmcr.createdate as TIMESTAMP))
              WHEN tz.timezoneid = 15 then convert_timezone('America/Detroit','America/Chicago',CAST(hmcr.createdate as TIMESTAMP))
              WHEN tz.timezoneid = 26 then convert_timezone('America/Detroit','America/Glace_Bay',CAST(hmcr.createdate as TIMESTAMP))
              WHEN tz.timezoneid = 20 then convert_timezone('America/Detroit','America/Detroit',CAST(hmcr.createdate as TIMESTAMP))
              ELSE hmcr.createdate
              END Adjust_CreateDate
,aff.affiliatename
FROM prod_homecare_insite_directory.hmcrequest hmcr
LEFT JOIN prod_homecare_acreporting_reporting.dimpostalcode pc on pc.code = trim(hmcr.postalcode)
LEFT JOIN prod_homecare_acreporting_reporting.dimtimezone tz on tz.timezoneid = pc.timezoneid
LEFT JOIN prod_homecare_insite_directory.affiliate aff on aff.affiliateid = hmcr.affiliateid
where hmcr.createdate >= '2024')

Select CTE.*,sr.userid
,date_format(Adjust_CreateDate, 'HH') hours
,date_format(Adjust_CreateDate, 'mm') minute
, (hours*100)+minute TimeID 
        ,date_format(Adjust_CreateDate,'HH:mm' ) Time
         ,CASE
          WHEN affiliateID = 87 THEN 'Convertful'
          WHEN affiliateID = 92 THEN 'Typeform'
          WHEN affiliateID = 90 THEN 'Elderlife'
          WHEN affiliateID = 93 THEN 'LNSTF'
          WHEN affiliateID = 94 THEN 'SLA DQ'
          WHEN affiliateID = 95 THEN 'LNSTF - CN'
          WHEN affiliateID = 96 THEN 'LNSTF - WS'
          WHEN affiliateID = 97 THEN 'LNSTF Inbound'
          WHEN affiliateID = 99 THEN 'LNSTF - MaxZip'
          WHEN affiliateID = 106 THEN 'SLADQ - WT'
          WHEN affiliateID = 108 THEN 'No Tours'
          when affiliateID = 112 THEN 'APFM SEO'
          WHEN affiliateID = 113 THEN 'Elderlife API'
          WHEN affiliateID = 117 THEN 'Resistant to Referral'
          WHEN affiliateID = 119 THEN 'SLA DQ LP'
          WHEN affiliateID = 121 THEN 'HC Max Attempts'
          WHEN affiliateID = 133 THEN 'Brand Verticles'
          WHEN AdjChannel = 'SEM'
          AND url like '%msclkid%' THEN 'SEM - Bing'
          WHEN AdjChannel = 'SEM'
          AND url like '%gclid%' THEN 'SEM - Google'
          WHEN AdjChannel = 'SEM'
          and url LIKE '%campaignid%' THEN 'SEM - Unknown'
          WHEN AdjChannel = 'SEO'
          AND affiliateid = 6 THEN 'AgingCare.com'
          WHEN AdjChannel = 'SEO'
          AND affiliateid = 49 THEN 'Caregivers.com'
          WHEN AdjChannel = 'APFM' THEN 'APFM Screened Leads'
          WHEN AdjChannel = 'Email' THEN 'Email'
          ELSE 'null'
        END as Source
        ,sr.userid userid1
FROM CTE
 LEFT JOIN (SELECT hmcrequestid 
                    ,ROW_NUMBER() OVER(PARTITION BY hmcrequestid ORDER BY createdate) rn
                    ,userid
                      ,CASE WHEN userid = 1702946 
                              AND datediff(minute,LAG(createdate) OVER (Partition BY sr.hmcrequestid ORDER BY hmcscreeningresultid),createdate) < 480
                              AND LAG(outcomeid) OVER (Partition BY sr.hmcrequestid ORDER BY hmcscreeningresultid) IN (12,13,14,16,17,22,24) THEN 1 ELSE 0 END AS APFMMisattribute
              FROM prod_homecare_insite_directory.hmcscreeningresult sr
              WHERE outcomeid NOT IN (5,15,19) and createdate >= '2023-11-01') sr on sr.hmcrequestid = CTE.hmcrequestid and rn =1
) as `_`
where (`AdjChannel` <> 'APFM' or `AdjChannel` is null) and (`AdjChannel` <> 'APFM DQ' or `AdjChannel` is null)
