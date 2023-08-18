*** Settings ***
Documentation     Para ejecutar este robot es necesario que lo haga con este comando --->      robot -d outputs_info tasks.robot
Library    RPA.Browser.Selenium    auto_close=${FALSE}  screenshot_root_directory=${CURDIR}${/}img_errors
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    OperatingSystem
Library    Screenshot

Suite Teardown    Cleaup

*** Variables ***
${Cont_imgErrros}    ${OUTPUT_DIR}${/}img_errors/
${Cont_Folder}    ${CURDIR}${/}outputs_info/
${csv_link}=    https://robotsparebinindustries.com/orders.csv
${receipt_directory}=       ${OUTPUT_DIR}${/}receipts/
${image_directory}=         ${OUTPUT_DIR}${/}images/
${zip_directory}=           ${OUTPUT_DIR}${/}zip_files/

*** Tasks ***
Execute task
    Create Directory   ${Cont_Folder}
    Create Directory   ${Cont_imgErrros}
    Open the website orders
    ${orders_of_csv}=     Get orders    ${csv_link}
    FOR    ${order}    IN    @{orders_of_csv}
        Close modal
        Fill in order parameters    ${order}
        Save PDF and IMG
        Return to order form
    END
    Create the ZIP

*** Keywords ***
Open the website orders
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order


Get orders
    [Documentation]    Descargar el CSV y retornarlo como tabla
    [Arguments]        ${order_file_url}
    RPA.HTTP.Download    ${order_file_url}    overwrite=true     # O tambien         Open Available Browser    https://robotsparebinindustries.com/orders.csv
    ${orders} =    Read table from CSV    orders.csv
    Remove File    ${CURDIR}${/}orders.csv
    [Return]    ${orders}

Close modal    
    Wait Until Page Contains Element    class:alert-buttons
    Click Button    OK
    
Make order
    Click Button    Order
    Page Should Contain Element    id:receipt

Fill in order parameters
    [Documentation]    Rellenar los campos y enviar el formulario
    [Arguments]          ${orders}
    Wait Until Page Contains Element    class:form-group
    Select From List By Index    head    ${orders}[Head]
    Select Radio Button    body    ${orders}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${orders}[Legs]
    Input Text    address    ${orders}[Address]
    Click Button    Preview
    Wait Until Keyword Succeeds    1min    500ms    Make order

Return to order form
    [Documentation]    Volver a la pagina de inicio para crear un nuevo robot
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another

Combine receipt with robot image to a PDF
    [Documentation]    Insertar la imagen alineada en el centro en un pdf
    [Arguments]    ${receipt_filename}    ${image_filename}
    Add Watermark Image To Pdf    ${image_filename}    ${receipt_filename}    ${receipt_filename}    0.2

Save PDF and IMG
    # Guardando PDF     Crear un pdf con el cuerpo de un html
    Wait Until Element Is Visible    id:receipt
    ${order_id}=    Get Text    //*[@id="receipt"]/p[1]
    Set Local Variable    ${receipt_filename}    ${receipt_directory}receipt_${order_id}.pdf
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    content=${receipt_html}    output_path=${receipt_filename}

    # Guardando IMG
    Wait Until Element Is Visible    id:robot-preview-image
    Set Local Variable    ${image_filename}    ${image_directory}robot_${order_id}.png
    Screenshot    id:robot-preview-image    ${image_filename}

    # Abrir el pdf e insertar la imagen    
    Combine receipt with robot image to a PDF    ${receipt_filename}    ${image_filename}
    

Create the ZIP
    Create Directory   ${zip_directory}
    Archive Folder With Zip    ${CURDIR}${/}outputs_info/receipts  outputs_info/zip_files/orders_pdf.zip

Cleaup
    [Documentation]    Cerrar el navegador y eliminar los directorios sobrantes (Imagenes/Pdfs)
    RPA.Browser.Selenium.Close Browser
    Remove Directory    ${image_directory}    recursive=True        #Eliminar carpeta de imagenes
    Remove Directory    ${receipt_directory}       recursive=True    #Eliminar carpeta de pdfs
