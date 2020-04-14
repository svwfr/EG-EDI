page 86250 "EDI Connection Card"
{
    Caption = 'EDI Connection Card';
    PageType = Card;
    SourceTable = 86230;

    layout
    {
        area(content)
        {
            Group(General)
            {
                field(Code; Code)
                { }
                field("Customer No."; "Customer No.")
                { }
                field("Customer Name"; "Customer Name")
                { }
                field(GLN; GLN)
                { }
                field("EDI Type"; "EDI Type")
                { }
                field(Order; Order)
                { }
                field(Shipment; Shipment)
                { }
                field(Invoice; Invoice)
                { }
                Group("EDI Settings")
                {
                    field("Gln Customer"; "Gln Customer")
                    { }
                    field("Gln Shipment"; "Gln Shipment")
                    { }
                    field("Gln Invoice"; "Gln Invoice")
                    { }
                    Field("Allow Edi AdHock"; "Allow Edi AdHock")
                    { }
                    field("Empty Order Date when Adhock"; "Empty Order Date when Adhock")
                    { }
                    field("Skip By VAT Registration No."; "Skip By VAT Registration No.")
                    { }
                    field("Credited Invoice Required"; "Credited Invoice Required")
                    { }
                    field("Validate GLN"; "Validate GLN")
                    { }
                    field("Item (Charge)"; "Item (Charge)")
                    {
                    }
                    field("INVRPT Location Filter"; "INVRPT Location Filter")
                    {
                    }
                }
            }
            group(FileNames)
            {
                field("File Path in"; "File Path in")
                {
                    trigger OnAssistEdit();
                    var
                        FileMgt: Codeunit 419;
                        FileName: Text[1024];
                        OpenDialogCaption: Label 'Folder';

                    begin
                        IF FileMgt.SelectFolderDialog(OpenDialogCaption, FileName) then
                            "File Path in" := FileName;

                    end;
                }
                field("File Path out"; "File Path Out")
                {
                    trigger OnAssistEdit();
                    var
                        FileMgt: Codeunit 419;
                        FileName: Text[1024];
                        OpenDialogCaption: Label 'Folder';

                    begin
                        IF FileMgt.SelectFolderDialog(OpenDialogCaption, FileName) then
                            "File Path Out" := FileName;

                    end;
                }
                field("File Path Archive Inn"; "File Path Archive Inn")
                {
                }
                field("File Path Archive Out"; "File Path Archive Out")
                {

                }
                field("Filter Incomming Orders"; "Filter Incomming Orders")
                {

                }
                field("File Name Orders"; "File Name Orders")
                {

                }
                field("File Name Shipment"; "File Name Shipment")
                {

                }
                field("File Name Invoice"; "File Name Invoice")
                {

                }
                field("File Name Credit Memo"; "File Name Credit Memo")
                {

                }
                field("File Name INVRPT"; "File Name INVRPT")
                {

                }
            }
        }
    }

    trigger OnOpenPage();
    begin

    End;
}
