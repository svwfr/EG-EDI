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
                { ApplicationArea = All; }
                field("Customer No."; "Customer No.")
                { ApplicationArea = All; }
                field("Customer Name"; "Customer Name")
                { ApplicationArea = All; }
                field(GLN; GLN)
                { ApplicationArea = All; }
                field("EDI Type"; "EDI Type")
                { ApplicationArea = All; }
                field(Order; Order)
                { ApplicationArea = All; }
                field(Shipment; Shipment)
                { ApplicationArea = All; }
                field(Invoice; Invoice)
                { ApplicationArea = All; }
                Group("EDI Settings")
                {
                    field("Gln Customer"; "Gln Customer")
                    { ApplicationArea = All; }
                    field("Gln Shipment"; "Gln Shipment")
                    { ApplicationArea = All; }
                    field("Gln Invoice"; "Gln Invoice")
                    { ApplicationArea = All; }
                    Field("Allow Edi AdHock"; "Allow Edi AdHock")
                    { ApplicationArea = All; }
                    field("Empty Order Date when Adhock"; "Empty Order Date when Adhock")
                    { ApplicationArea = All; }
                    field("Skip By VAT Registration No."; "Skip By VAT Registration No.")
                    { ApplicationArea = All; }
                    field("Credited Invoice Required"; "Credited Invoice Required")
                    { ApplicationArea = All; }
                    field("Validate GLN"; "Validate GLN")
                    { ApplicationArea = All; }
                    field("Item (Charge)"; "Item (Charge)")
                    {
                        ApplicationArea = All;
                    }
                    field("INVRPT Location Filter"; "INVRPT Location Filter")
                    {
                        ApplicationArea = All;
                    }
                }
            }
            group(FileNames)
            {
                field("File Path in"; "File Path in")
                {
                    ApplicationArea = All;
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
                    ApplicationArea = All;
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
                    ApplicationArea = All;
                }
                field("File Path Archive Out"; "File Path Archive Out")
                {
                    ApplicationArea = All;
                }
                field("Filter Incomming Orders"; "Filter Incomming Orders")
                {
                    ApplicationArea = All;
                }
                field("File Name Orders"; "File Name Orders")
                {
                    ApplicationArea = All;
                    ToolTip = '%1=dokumentnr., %2=GLN SU og %3=dato-tid';
                }
                field("File Name Shipment"; "File Name Shipment")
                {
                    ApplicationArea = All;
                    ToolTip = '%1=dokumentnr., %2=GLN SU og %3=dato-tid';
                }
                field("File Name Invoice"; "File Name Invoice")
                {
                    ApplicationArea = All;
                    ToolTip = '%1=dokumentnr., %2=GLN SU og %3=dato-tid';
                }
                field("File Name Credit Memo"; "File Name Credit Memo")
                {
                    ApplicationArea = All;
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
