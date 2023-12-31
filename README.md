# hpg-infant-health
This repository provides code to replicate [Reader (2023) The infant health effects of starting universal child benefits in pregnancy: evidence from England and Wales. Journal of Health Economics, 89, May 2023.](https://doi.org/10.1016/j.jhealeco.2023.102751)

Data Availability
1. [Birth registry microdata, 2006-2014](https://ons.metadata.works/browser/dataset?id=328&origin=0): individual-level administrative data from birth registrations in England and Wales. The data are provided by the Office for National Statistics (ONS). The data are not publicly available and must be accessed from the UK within the ONS's Secure Research Service environment. Details on how to apply for the data can be found [here](https://www.ons.gov.uk/aboutus/whatwedo/statistics/requestingstatistics/secureresearchservice/applyforanaccreditedresearchproject). It typically takes a few months to for a project application to be approved and to gain access to the data. You should request all years of birth registrations in England and Wales from 2006-2014 inclusive.
2. [Hospital Episode Statistics microdata, 2006-2014](https://digital.nhs.uk/data-and-information/data-tools-and-services/data-services/hospital-episode-statistics): individual-level administrative hospital records from England's National Health Service (NHS). The data are provided by NHS Digital under a bespoke data sharing agreement and are not publicly available. Details on how to apply for the data can be found [here](https://digital.nhs.uk/services/data-access-request-service-dars). NHS Digital charge researchers for data sharing agreements and it can take several months to gain access to the data. You should apply for individual-level data from all 'birth' and 'other birth' episodes in England from the financial years 2006/07 to 2014/15 inclusive. As noted in the paper, gaining access to confidential data (e.g. date of birth) in NHS data is difficult and requires approval from the Confidentiality Advisory Group. To avoid requesting confidential data on the date of birth of the baby, I requested two bespoke variables to be created by NHS Digital: a) a week of birth variable, centered at the policy cut-off of 6 April 2009, and b) a treatment dummy, equal to one if a baby is born between 6 April 2009 and 16 April 2011 inclusive. These variables should be requested in order to replicate the results from the paper. The author will assist with any reasonable replication attempts for two years following publication. 
3. [Statistics on Women's Smoking Status at Time of Delivery, England, 2007-2015](https://digital.nhs.uk/data-and-information/publications/statistical/statistics-on-women-s-smoking-status-at-time-of-delivery-england): published administrative data from NHS Digital on the proportion of women known to be smoking at delivery. The raw annual datasets are publicly available and can be downloaded separately from the NHS Digital website. A merged and cleaned data file is provided in the 'public data' folder.

Instructions
- Edit '#1 Birth registry data/00_master.do' to adjust the filepaths.
- Run '#1 Birth registry data/00_master.do' within the ONS Secure Research Service (SRS). This will automatically run all codes within the folder. The codes clean the birth registry data and produce all relevant tables and figures from the main paper and supplementary material.
- Edit '#2 Hospital data/00_master.do' to adjust the filepaths.
- Run '#2 Hospital data/00_master.do'. This will automatically run all codes within the folder. The codes clean the hospital data and produce all relevant tables and figures from the main paper and supplementary material.
- Edit '#3 Published data/00_Figure_S17.do' to adjust the filepaths.
- Run '#3 Published data/00_Figure_S17.do'. This produces Figure S17, based on published administrative data on women's smoking status at delivery.

All dependencies are specified in the '00' files.



