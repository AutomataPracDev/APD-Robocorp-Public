*** Settings ***
Documentation       Order robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file
...                 Saves the screenshot of the ordered robots
...                 embeds thh screenshot of the robot to the PDF receipt
...                 Creates ZIP archive of the receipt and the image

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${My_Test_Vault}=    Get Secret    My_Test_Vault
    ${URL}=    Request File URL    ${My_Test_Vault}[DefaultURL]
    Open the robot order website
    ${receipt_folder}=    Create receipts folder for zip
    ${orders}=    Get orders    ${URL}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order until Success
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]    ${receipt_folder}
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts and delete folder    ${receipt_folder}


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Create receipts folder for zip
    #Create Directory    ${OUTPUT_DIR}${/}receipts
    #RETURN    ${OUTPUT_DIR}${/}receipts
    RETURN    ${OUTPUT_DIR}${/}

Get orders
    [Arguments]    ${URL}
    Download    ${URL}    overwrite=${True}
    ${orders_table}=    Read table from CSV    orders.csv
    RETURN    ${orders_table}

Close the annoying modal
    Click Button    css:.btn-dark

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

Preview the robot
    Click Button    id:preview

Submit the order until Success
    Wait Until Keyword Succeeds    1 min    1 sec    Submit the order

Submit the order
    Click Button    id:order
    Wait Until Page Contains Element    css:.alert-success

Store the receipt as a PDF file
    [Arguments]    ${order_number}    ${receipt_folder}
    Wait Until Element Is Visible    css:.alert-success
    ${receipt}=    Get Element Attribute    css:.alert-success    outerHTML
    Html To Pdf    ${receipt}    ${receipt_folder}${/}${order_number}.pdf
    RETURN    ${receipt_folder}${/}${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${order_number}.png
    RETURN    ${OUTPUT_DIR}${/}${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close All Pdfs
    #Remove File    ${screenshot}

Go to order another robot
    Click Button    id:order-another

Create a ZIP file of the receipts and delete folder
    [Arguments]    ${receipt_folder}
    Archive Folder With Zip    ${receipt_folder}    ${OUTPUT_DIR}${/}receipts.zip
    #Remove Directory    ${receipt_folder}    recursive=${True}

Request File URL
    [Arguments]    ${DefaultURL}
    Add heading    Load File from URL
    Add text    Please enter the URL to the Orders CSV file.
    Add text input    name=URL    label=URL:    placeholder=Enter URL    rows=2
    Add text    Vault URL: ${DefaultURL}
    ${dialog}=    Run dialog    title=TestDialog    on_top=True
    RETURN    ${dialog.URL}
