How the script works:

1) Opens the job posting page on linkedin
2) Get individual job postings links
3) Navigate to each of those links
4) While in corresponding page, scrap needed date such as job title, company name, job location, etc...
5) Any field that left blank by job poster (such as company name) will result in NA field
6) All data scraped will be bound to one table and can be exported to csv

Report can be seen here: https://docs.google.com/spreadsheets/d/1ocJ2JZX6Hs_3YGFzNAXPyi7YJEGTZCUgP5XitgACtHE/edit?usp=sharing

Weakness of this script:
Currently can only scrap top 25 jobs from linkedin page. Can not "press" show more button and scrap more job info.
Solution: run the job in short interval (ie: 5/10 minutes)

Chrome version: 76.0.3809.68
R version: 3.6.0
RStudio version: 1.2.1335
