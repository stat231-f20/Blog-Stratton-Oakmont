# Imports
library(tidyverse) 
library(rvest)
library(robotstxt)
library(janitor)
library(RSelenium)
library(dplyr)
library(lubridate)
library(stringr)
library(httr)
library(jsonlite)
library(xlsx)
library(zoo)
library(rvest)


# Grab Table from Wiki
wiki <- read_html("https://en.m.wikipedia.org/wiki/List_of_largest_companies_in_the_United_States_by_revenue")
tables <- html_nodes(wiki, "table")
top_75 <- html_table(tables[[2]])

top_75 <- top_75 %>%
  filter(`Name` != "AT&T") %>%
  filter(`Name` != "Fannie Mae") %>% 
  filter(`Name` != "Freddie Mac") %>% 
  filter(`Name` != "State Farm") %>% 
  filter(`Name` != "Albertsons") %>% 
  filter(`Name` != "Nationwide Mutual Insurance Company") %>% 
  filter(`Name` != "Massachusetts Mutual Life Insurance Company") %>% 
  filter(`Name` != "Energy Transfer Partners") %>% 
  filter(`Name` != "Tech Data") %>% 
  filter(`Name` != "World Fuel Services") %>% 
  filter(`Name` != "TIAA") %>% 
  filter(`Name` != "Publix") %>%
  filter(`Name` != "John Deere") %>% 
  filter(`Name` != "Plains GP") %>%
  filter(`Name` != "USAA") %>% 
  filter(`Name` != "INTL FCStone") %>% 
  filter(`Name` != "Enterprise Products") %>%
  filter(`Name` != "Northwestern Mutual") %>%
  mutate(`Name` = ifelse(`Name` == "ExxonMobil","Exxon Mobil", `Name`)) %>% 
  mutate(`Name` = ifelse(`Name` == "Facebook, Inc.","Facebook", `Name`)) %>%
  mutate(`Name` = ifelse(`Name` == "HP Inc.","HP Inc", `Name`)) %>%
  mutate(`Name` = ifelse(`Name` == "Caterpillar Inc.","Caterpillar", `Name`)) %>%
  mutate(`Name` = ifelse(`Name` == "Archer Daniels Midland","Archer-Daniels-Midland", `Name`)) %>%
  mutate(`Name` = ifelse(`Name` == "New York Life Insurance Company","New York Life", `Name`)) %>%
  mutate(`Name` = ifelse(`Name` == "Bestbuy","Best Buy", `Name`)) %>%
  mutate(`Name` = ifelse(`Name` == "Dow Chemical Company","Dow, Inc", `Name`)) %>%
  mutate(`Name` = ifelse(`Name` == "Oracle Corporation","Oracle", `Name`)) %>%
  mutate(`Name` = ifelse(`Name` == "Progressive Corporation","Progressive", `Name`)) %>%
  mutate(`Name` = ifelse(`Name` == "Coca-Cola Company","Coca-Cola", `Name`)) %>%
  mutate(`Name` = ifelse(`Name` == "AbbVie Inc.","AbbVie", `Name`)) %>%
  mutate(`Name` = ifelse(`Name` == "The Walt Disney Company","Walt Disney", `Name`)) %>%
  head(75)


# Start Chrome Driver
# Make sure your driver version matches the version of chrome you have installed
rD <- rsDriver(browser="chrome",chromever = "85.0.4183.83")
remDr <- rD[["client"]]
remDr$open()

# List of companies to scrape for 
companies <- top_75$Name %>% as.matrix()
all_esg <- c()

# Loop to scrape ESG for each ticker
for (t in companies){
  # Go to the Website Homepage
  remDr$navigate("https://www.sustainalytics.com/esg-ratings/")
  
  #Find Search Bar & Type Ticker into it
  searchbar <- remDr$findElement(using = "xpath", '//*[@id="searchInput"]')
  searchbar$sendKeysToElement(list(t))
  
  #Wait for it to load
  Sys.sleep(1)
  
  #Find first Dropdown Menu item and click on it
  dropdown <- remDr$findElement(using = "xpath", '//*[@id="searchResults"]/div/div/div/div/a')
  dropdown$clickElement()
  
  #Wait for it to load
  Sys.sleep(2.5)
  
  #Grab the ESG score for this company
  esg_xpath <- '//*[@id="main"]/section[2]/section[1]/div/div[1]/div[1]/div[3]/div[1]/div[1]/div[1]/span'
  esg <- as.numeric(remDr$findElement(using = 'xpath', esg_xpath)$getElementText()[[1]])
  
  #Add it to the list of ESG scores
  all_esg <- c(all_esg,esg)
}

# Quit the Chrome Driver
remDr$close()
rD[["server"]]$stop()
gc(rD)

#Combine Data
top_75 <- top_75 %>% cbind(as.data.frame(all_esg)) %>% rename(`ESG` = all_esg)
write.csv(top_75,"/Users/MatthewKaneb/Desktop/ESG_Data", row.names = FALSE)


