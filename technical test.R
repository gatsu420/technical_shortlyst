start_time <- Sys.time()

library(RSelenium) # to execute the core scraping engine
library(jsonlite) # to tidy job function into json format
library(dplyr) # to get estimated date on posting date section
library(stringr) # to trim whitespaces around timestamp differences

driver <- rsDriver(browser = c("chrome"),
                   chromever = "76.0.3809.68",
                   verbose = TRUE)

remote_driver <- driver[["client"]]

# open linkedin page 
remote_driver$navigate("https://id.linkedin.com/jobs/search?location=Indonesia&redirect=false&position=1&pageNum=0&f_TP=1")

# get individual links for each individual posting cards
# links needed to pull details of each job postings
all_cards <- remote_driver$findElement(using = "class",
                                       value = "jobs-search__results-list")
indiv_cards <- all_cards$findChildElements(using = "class",
                                           value = "result-card__full-card-link")

card_link <- NULL

for (i in 1:length(indiv_cards)) {
  foo <- indiv_cards[[i]]$getElementAttribute("href")[[1]]
  card_link <- rbind(foo, card_link)
} 

# loop to open each card using card_link
job_info <- NULL

for (i in 1:length(card_link)) {

remote_driver$navigate(card_link[[i]])

# company name
element_name <- tryCatch(remote_driver$findElement(using = "class",
                                                   value = "topcard__title"),
                         error = function(e) NA_character_)
name <- tryCatch(element_name$getElementText(),
                 error = function(e) NA_character_)

# job position
element_position <- tryCatch(remote_driver$findElement(using = "class",
                                                       value = "topcard__org-name-link"),
                             error = function(e) NA_character_)
position <- tryCatch(element_position$getElementText(),
                     error = function(e) NA_character_)

# job location
element_location <- tryCatch(remote_driver$findElement(using = "class",
                                                       value = "topcard__flavor--bullet"),
                             error = function(e) NA_character_)
location <- tryCatch(element_location$getElementText(),
                     error = function(e) NA_character_)

# company logo
element_logo_parent <- tryCatch(remote_driver$findElement(using = "class",
                                                          value = "topcard__logo-container"),
                                error = function(e) NA_character_)
element_logo <- tryCatch(element_logo_parent$findChildElement(using = "class",
                                                     value = "company-logo"),
                         error = function(e) NA_character_)
logo <- tryCatch(element_logo$getElementAttribute("src"),
                 error = function(e) NA_character_)

# job description
element_desc_parent <- tryCatch(remote_driver$findElement(using = "class",
                                                          value = "description"),
                                error = function(e) NA_character_)
element_desc <- tryCatch(element_desc_parent$findChildElement(using = "class",
                                                      value = "description__text--rich"),
                         error = function(e) NA_character_)
desc <- tryCatch(element_desc$getElementText(),
                 error = function(e) NA_character_)

# seniority level
element_level_grparent <- tryCatch(element_desc_parent$findChildElement(using = "class",
                                                               value = "job-criteria__list"),
                                   error = function(e) NA_character_)
element_level_parent <- tryCatch(element_level_grparent$findChildElements(using = "class",
                                                                  value = "job-criteria__item"),
                                 error = function(e) NA_character_)
element_level <- tryCatch(element_level_parent[[1]]$findChildElement(using = "class",
                                                            value = "job-criteria__text"),
                          error = function(e) NA_character_)
level <- tryCatch(element_level$getElementText(),
                  error = function(e) NA_character_)

# job function
element_func_parent <- tryCatch(element_level_parent[[3]]$findChildElements(using = "class",
                                                                   value = "job-criteria__text"),
                                error = function(e) NA_character_)
func <- NULL
for (i in 1:length(element_func_parent)) {
  wtf <- tryCatch(element_func_parent[[i]]$getElementText()[[1]],
                  error = function(e) NA_character_)
  func <- rbind(wtf, func)
  func <- toJSON(func)
}

# job industry
element_industry <- tryCatch(element_level_parent[[4]]$findChildElement(using = "class",
                                                               value = "job-criteria__text"),
                             error = function(e) NA_character_)
industry <- tryCatch(element_industry$getElementText(),
                     error = function(e) NA_character_)

# posting date
element_date <- remote_driver$findElement(using = "class",
                                          value = "posted-time-ago__text")
prefix <- gsub("yang lalu",
               "",
               element_date$getElementText())
number <- as.numeric(str_trim(gsub("[a-z]",
                        "",
                        prefix),
                   side = c("both")))
period <- str_trim(gsub("[0-9]",
                        "",
                        prefix),
                   side = c("both"))
date <- case_when(
  period == "menit" ~ as.character(as.POSIXct(as.numeric(Sys.time())-(60*number),
                                         origin = "1970-01-01")),
  period == "jam" ~ as.character(as.POSIXct(as.numeric(Sys.time())-(3600*number),
                                       origin = "1970-01-01")),
  period == "hari" ~ as.character(as.POSIXct(as.numeric(Sys.time())-(86400*number),
                                        origin = "1970-01-01")),
  TRUE ~ NA_character_
)


# bind job infos into one table
bar <- cbind(name[[1]], position[[1]], location[[1]], logo[[1]], desc[[1]], level[[1]], func, industry[[1]], date)
job_info <- rbind(bar, job_info)
colnames(job_info) <- c("company name",
                        "job position",
                        "job location",
                        "company logo link",
                        "job description",
                        "seniority level",
                        "job function",
                        "company industry",
                        "estimated posting date")

# tell remote_driver go back to previous page
remote_driver$goBack()

}

message("If Selenium tells that it can't find an element, just ignore it, the result would be just okay.
        Except, it would show some NA rows because the field in its corresponding job posting is nowhere
        to be found too...")

Sys.time()-start_time

# export into csv
write.csv(job_info, "job_info2.csv")

# # job function
# # kategori ini usahain pake length-adjusted loop karena involve narikin atomic vector
# element_func_parent <- element_level_parent[[3]]$findChildElements(using = "class",
#                                                                    value = "job-criteria__text")
# 
# func1 <- element_func_parent[[1]]$getElementText()
# func2 <- element_func_parent[[2]]$getElementText()
# func3 <- element_func_parent[[3]]$getElementText()
# 
# # job industry
# element_industry <- element_level_parent[[4]]$findChildElement(using = "class",
#                                                                value = "job-criteria__text")
# industry <- element_industry$getElementText()
# 
# # posting date
# # TBD....
# 
# # tambahin syntax ifnull juga...
# 
# remote_driver$goBack()

driver[["server"]]$stop()
