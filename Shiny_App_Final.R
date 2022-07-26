library(shinythemes)
library(DBI)
library(RMySQL)
library(shiny)
library(dplyr)
library(shinyjs)
library(ggplot2)
library(sf)

db = dbConnect(MySQL(),
               user = "root",
               password = "xxxx", # Type your password
               dbname = "project", # Type your database name
               port = 3306)

dbListTables(db) # ran this code. This code will list all the tables inside your database
# "listings" table is just the raw airbnb listings data.

# Maybe getting our tables as variables so we can work with them.
host = dbGetQuery(db, "select * from host")
listing = dbGetQuery(db, "select * from listing")
location = dbGetQuery(db, "select * from location")
review = dbGetQuery(db, "select * from review")
specification = dbGetQuery(db, "select * from specification")
user = dbGetQuery(db, "select * from user")
exploratory = dbGetQuery(db, "select * from exploratory")
neighborhood_group = dbGetQuery(db,"select distinct neighbourhood_group_cleansed from exploratory")
neighborhood  = dbGetQuery(db,"select distinct neighbourhood_group_cleansed, neighbourhood_cleansed from exploratory")
min_price = dbGetQuery(db, "select min(price) price from exploratory")                           
max_price = dbGetQuery(db,  "select max(price) price from exploratory")
avg_price = dbGetQuery(db, "select avg(price) price from exploratory")

# New Tables
table1 = exploratory %>%
  select("listing_id", "room_type", "neighbourhood_group_cleansed", "neighbourhood_cleansed", "price")

boroughs =  table1$neighbourhood_group_cleansed
neigh =  table1$neighbourhood_cleansed
prices = table1$price

table2 = exploratory %>%
  select("listing_id", "accommodates", "beds", "minimum_nights", "maximum_nights", "host_id", "host_is_superhost", "price")

table3 = exploratory %>%
  select("listing_id","listing_url", "review_scores_rating", "price")

table4 = user

fieldsMandatory <- c("username", "password")

room_type_variable = exploratory %>%
  select("room_type", "neighbourhood_group_cleansed", "neighbourhood_cleansed", "price")


#########################

ui <- fluidPage(
  titlePanel("New York City Airbnb listing Web App"),
  #theme = shinythemes::themeSelector(), # theme: slate looks good
  theme = shinythemes::shinytheme("yeti"),
  shinyjs::useShinyjs(),
  sidebarLayout(
    sidebarPanel(
      #selectInput("borough_old", "Choose a borough", choices = sort(unique(table1$neighbourhood_group_cleansed))),
      #selectInput("neigh_old", "Choose a neighborhood", choices = c("N/A",sort(unique(        neigh        )))),
      fluidRow(
        selectizeInput(
          inputId = 'borough',
          label = 'Choose a borough',
          choices = c( sort(unique(table1$neighbourhood_group_cleansed))),
          multiple = TRUE,
          selected = 'All'),
        uiOutput(
          outputId = 'neigh')
      ),
      sliderInput("slide", "Select a max price (currency: U.S Dollar)", min = min_price$price, max = max_price$price, value = max_price$price, ticks=FALSE),
      
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Welcome to the App", img(src = "https://storage.googleapis.com/yk-cdn/photos/pdp/calder-wilson/new-york-city-sunset-from-helicopter.jpg", height = 500, width = 800, p("Hi there, welcome to the New York City listings Airbnb web app!"))),
        tabPanel("NYC Listings", plotOutput("plot1"), DT::dataTableOutput("dt_table1")),
        tabPanel("Nights", DT::dataTableOutput("dt_table2")),
        tabPanel("Ratings", plotOutput("plot2"), DT::dataTableOutput("dt_table3"), p("Copy and paste the above url into your web browser to look at the real Airbnb listing data!"), plotOutput("plot3")),
        tabPanel("Users", tableOutput("dt_table4")),
        tabPanel("Enter User",  
                 div(
                   id = "form",
                   
                   textInput("username", "Username *" ),
                   textInput("email", "Email"),
                   textInput("phone", "Phone"),
                   textInput("password", "Password *"),
                   actionButton("submit", "Submit", class = "btn-primary")
                 ),
                 
                 shinyjs::hidden(
                   div(
                     id = "thankyou_msg",
                     h3("Thanks, your response was submitted successfully!"),
                     actionLink("submit_another", "Submit another response")
                   )
                 )  
        )
      )
    )
  )
)

server <- function(input, output) {
  
  output$dt_table1 <- DT::renderDataTable({
    table1 %>%
      filter( boroughs %in% input$borough  & neigh %in% input$neigh & price < input$slide)
  })
  
  
  output$dt_table2 <- DT::renderDataTable({
    table2 %>%
      filter(boroughs %in% input$borough & neigh %in% input$neigh & price < input$slide)
  })
  
  
  output$dt_table3 <- DT::renderDataTable({
    table3 %>%
      filter(boroughs %in% input$borough & neigh %in% input$neigh & price < input$slide)
  })
  
  output$dt_table4 <- renderTable({
    table4
  })
  
  output$plot1 <- renderPlot({
    rt_b <- ggplot(room_type_variable, aes(x = neighbourhood_group_cleansed, y = price, fill = room_type)) + geom_col(position = "dodge") 
    rt_b + labs(title = "Room Types x Borough", x = "Boroughs", y = "Price") + theme(plot.title = element_text(hjust = 0.5)) + theme(legend.title = element_blank())
  })
  
  output$plot2 <- renderPlot({
    cord <- st_as_sf(location, coords = c("longitude","latitude"))
    ggplot(cord) + geom_sf(aes(color = neighbourhood_group_cleansed)) + labs(title = "Boroughs", x = "Longitude", y = "Latitude") + theme(plot.title = element_text(hjust = 0.5)) + theme(legend.title = element_blank())
  })
  
  output$plot3 <- renderPlot({
    cord <- st_as_sf(location, coords = c("longitude","latitude"))
    ggplot(cord) + geom_sf(aes(color = review$review_scores_rating)) + labs(title = "Boroughs - Review Stars Rating", x = "Longitude", y = "Latitude") + theme(plot.title = element_text(hjust = 0.5)) + labs(col = "Stars Ratings")
  })
  
  output$neigh <- renderUI({
    
    # check whether user wants to filter by bor;
    # if not, then filter by selection
    if ('All' %in% input$borough) {
      df <- neighborhood
    } else {
      df <- neighborhood %>%
        filter(
          neighbourhood_group_cleansed %in% input$borough)
    }
    
    # get available carb values
    n <- sort(unique(df$neighbourhood_cleansed))
    
    # render selectizeInput
    selectizeInput(
      inputId = 'neigh',
      label = 'Select neighborhood',
      choices = c( n),
      multiple = TRUE,
      selected = 'All')
  })
  
  
  
  observe({
    # check if all mandatory fields have a value
    mandatoryFilled <-
      vapply(fieldsMandatory,
             function(x) {
               !is.null(input[[x]]) && input[[x]] != ""
             },
             logical(1))
    mandatoryFilled <- all(mandatoryFilled)
    
    # enable/disable the submit button
    shinyjs::toggleState(id = "submit", condition = mandatoryFilled)
  })
  
  formData <- reactive({
    data <- sapply(fields, function(x) input[[x]])
    data
  })
  
  observeEvent(input$submit, {
    
    "INSERT INTO user (username, password, email, phone) VALUES ('test','testpw','testemail','testphone')"
    table<-"user"
    query <- sprintf(
      "INSERT INTO user (username, password, email, phone) values ('%s','%s','%s','%s')",
      input$username,
      input$password,
      input$email,
      input$phone
    )
    # Submit the update query and disconnect
    dbGetQuery(db, query)
    
    table4 = dbGetQuery(db, "select * from user")
    output$dt_table4 <- renderTable({
      table4
    })
    shinyjs::reset("form")
    shinyjs::hide("form")
    shinyjs::show("thankyou_msg")
    
  })
  
  observeEvent(input$submit_another, {
    shinyjs::show("form")
    shinyjs::hide("thankyou_msg")
  })   
  
  
}


shinyApp(ui, server)