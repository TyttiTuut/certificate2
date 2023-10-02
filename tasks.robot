
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
...    
Library         RPA.Browser.Selenium
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.FileSystem
Library         RPA.HTTP
Library         RPA.Archive
Library         Dialogs
Library         RPA.Robocorp.Vault
Library         RPA.core.notebook
Library    Screenshot

*** Variables ***
${url}            https://robotsparebinindustries.com/#/robot-order


*** Tasks ***
Order robots from RobotSpareBin Industries Inc 

    Download the csv file
    ${orders}=  Read the csv file
    Open the robot order website
    Loop the orders  ${orders}
    Zip reciepts PDF

*** Keywords ***
Open the robot order website
    Open Available Browser     ${url}

***Keywords***
Download the csv file
    ${file_url}=    Set Variable    https://robotsparebinindustries.com/orders.csv  
    Download    ${file_url}    overwrite=True
    Sleep    2 seconds

***Keywords***
Read the csv file
    ${orders}=  Read Table From Csv  ${CURDIR}${/}orders.csv  header=True
    Return From Keyword  ${orders}

***Keywords***
Loop the orders
    [Arguments]  ${orders}
    FOR  ${row}  IN  @{orders}    
        Fill the form  ${row}
        Checking Receipt data processed or not
        Store receipt PDFs  ${row}      
    END  

***Keywords***
Fill the form
    [Arguments]  ${row}
    Wait Until Page Contains Element  //button[@class="btn btn-dark"]
    Click Button  //button[@class="btn btn-dark"]
    Select From List By Value  //select[@name="head"]  ${row}[Head]
    Click Element  //input[@value="${row}[Body]"]
    Input Text  //input[@placeholder="Enter the part number for the legs"]  ${row}[Legs]
    Input Text  //input[@placeholder="Shipping address"]  ${row}[Address] 
    Click Button  //button[@id="preview"]
    Wait Until Page Contains Element  //div[@id="robot-preview-image"]
    Sleep  5 seconds
    Click Button  //button[@id="order"]
    Sleep  5 seconds

***Keywords***
Store receipt PDFs
    [Arguments]  ${row} 
    Sleep  5 seconds
    ${reciept_data}=  Get Element Attribute  //div[@id="receipt"]  outerHTML
    Html To Pdf  ${reciept_data}  ${CURDIR}${/}reciepts${/}${row}[Order number].pdf
    Screenshot  //div[@id="robot-preview-image"]  ${CURDIR}${/}robots${/}${row}[Order number].png 
    Add Watermark Image To Pdf  ${CURDIR}${/}robots${/}${row}[Order number].png  ${CURDIR}${/}reciepts${/}${row}[Order number].pdf  ${CURDIR}${/}reciepts${/}${row}[Order number].pdf 
    Click Button  //button[@id="order-another"]

***Keywords***
Zip reciepts PDF
    Archive Folder With Zip  ${CURDIR}${/}reciepts  ${OUTPUT_DIR}${/}reciepts.zip

*** Keywords ***
Checking Receipt data processed or not 
    FOR  ${i}  IN RANGE  ${100}
        ${alert}=  Is Element Visible  //div[@class="alert alert-danger"]  
        Run Keyword If  '${alert}'=='True'  Click Button  //button[@id="order"] 
        Exit For Loop If  '${alert}'=='False'       
    END
    
    Run Keyword If  '${alert}'=='True'  Close and start Browser prior to another transaction 

***Keywords***
Close and start Browser prior to another transaction
    Close Browser
    Open the robot order website
    Continue For Loop