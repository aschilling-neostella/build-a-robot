*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Desktop
Library             RPA.PDF
Library             RPA.Archive
Library             OperatingSystem
Library             DateTime
Library             Dialogs


*** Variables ***
${receipt_directory}=       ${OUTPUT_DIR}${/}orders/receipts/
${image_directory}=         ${OUTPUT_DIR}${/}orders/images/


*** Tasks ***
Order robots from RobotSpareBin Industries Inn
    Open the robot order website
    Download the CSV file
    Fill the form using the data from the CSV file
    Name and create the zip file
    [Teardown]    Close the browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download the CSV file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}

Get rid of the modal
    Click Button    OK

Fill and submit the form for one order
    [Arguments]    ${order}
    Get rid of the modal
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    preview
    Wait Until Keyword Succeeds    10x    2s    Submit order

Fill the form using the data from the CSV file
    ${orders}=    Read table from CSV    orders.csv
    Log    Found columns: ${orders.columns}
    FOR    ${order}    IN    @{orders}
        Fill and submit the form for one order    ${order}
        Save order details
        Order another
    END

Submit order
    Click Button    order
    Assert order submitted

Assert order submitted
    Element Should Be Visible    order-another

Save order details
    Wait Until Element Is Visible    id:receipt
    ${order_id}=    Get Text    //*[@id="receipt"]/p[1]
    Set Local Variable    ${receipt_filename}    ${receipt_directory}receipt_${order_id}.pdf
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    content=${receipt_html}    output_path=${receipt_filename}

    Wait Until Element Is Visible    id:robot-preview-image
    Set Local Variable    ${image_filename}    ${image_directory}robot_${order_id}.PNG
    Screenshot    id:robot-preview-image    ${image_filename}
    Create PDF with receipt and image    ${receipt_filename}    ${image_filename}

Order another
    Click Button    order-another

Create PDF with receipt and image
    [Arguments]    ${receipt_filename}    ${image_filename}
    Open Pdf    ${receipt_filename}
    Add Watermark Image To Pdf    ${image_filename}    ${receipt_filename}
    Close Pdf

Name and create the zip file
    ${date}=    Get Current Date    result_format=%Y-%m-%d_%H%M    exclude_millis=yes
    Archive Folder With Zip    ${receipt_directory}    robot_orders_${date}.zip

Close the browser
    Close Browser
