page 86230 "EDI Connection"
{
    Caption = 'Edi Connection';
    CardPageID = "EDI Connection";
    PageType = List;
    SourceTable = 86230;
    SourceTableView = WHERE("GLN Type" = FILTER('Agreement'));
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Code; Code)
                {
                    ApplicationArea = All;
                }
                field("Name"; "Customer Name")
                {
                    ApplicationArea = All;
                }
                field("GLN"; "Owner GLN")
                {
                    ApplicationArea = All;
                    ToolTip = 'GLN Owner: Kjede eier som EDI kontrakt er inngått med';
                }
                field("EDI Type"; "EDI Type")
                {
                    ApplicationArea = All;
                }
                field("Validate GLN"; "Validate GLN")
                {
                    ApplicationArea = All;
                }
                field("Order"; "Order")
                {
                    ApplicationArea = All;
                }
                field("Shipment"; "Shipment")
                {
                    ApplicationArea = All;
                }
                field("Invoice"; "Invoice")
                {
                    ApplicationArea = All;
                }
                field(INVRPT; INVRPT)
                {
                    ApplicationArea = All;
                }
                field("Allow Edi AdHock"; "Allow Edi AdHock")
                {
                    ApplicationArea = All;
                }
                field("Credited Invoice Required"; "Credited Invoice Required")
                {
                    ApplicationArea = All;
                }
                field("INVRPT Location Filter"; "INVRPT Location Filter")
                {
                    ApplicationArea = All;
                    visible = false;
                }
                field("Item (Charge)"; "Item (Charge)")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Gln Customer"; "Gln Customer")
                {
                    ApplicationArea = All;
                    ToolTip = 'GLN BY: Selskap som varer skal selges til.';
                }
                field("Gln Shipment"; "Gln Shipment")
                {
                    ApplicationArea = All;
                    ToolTip = 'GLN DP: Selskap som varer skal leveres til. (Part (selskap) varen stilles til disposisjon for.)';
                }
                field("Gln Invoice"; "Gln Invoice")
                {
                    ApplicationArea = All;
                    ToolTip = 'GLN IV: Selskap som faktura skal sendes til.';
                }
                field("File Path in"; "File Path in")
                {
                    ApplicationArea = All;
                    Visible = False;

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
                    Visible = False;

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
                    Visible = False;
                }
                field("File Path Archive Out"; "File Path Archive Out")
                {
                    ApplicationArea = All;
                    Visible = False;
                }
                field("Order Counter"; "Order Counter")
                {
                    ApplicationArea = All;
                    Visible = False;
                }
                field("Invoice Counter"; "Invoice Counter")
                {
                    ApplicationArea = All;
                    Visible = False;
                }
                field("InvRPT Counter"; "InvRPT Counter")
                {
                    ApplicationArea = All;
                }
                field("Filter Incomming Orders"; "Filter Incomming Orders")
                {
                    ApplicationArea = All;
                    Visible = False;
                }
                field("File Name Orders"; "File Name Orders")
                {
                    ApplicationArea = All;
                    Visible = False;
                }
                field("File Name Shipment"; "File Name Shipment")
                {
                    ApplicationArea = All;
                    Visible = False;
                    ToolTip = '%1=dokumentnr., %2=GLN SU og %3=dato-tid';
                }
                field("File Name Invoice"; "File Name Invoice")
                {
                    ApplicationArea = All;
                    Visible = False;
                    ToolTip = '%1=dokumentnr., %2=GLN SU og %3=dato-tid';
                }
                field("File Name Credit Memo"; "File Name Credit Memo")
                {
                    ApplicationArea = All;
                    Visible = False;
                    ToolTip = '%1=dokumentnr., %2=GLN SU og %3=dato-tid';
                }
                field("File Name INVRPT"; "File Name INVRPT")
                {
                    ApplicationArea = All;
                    Visible = False;
                }
            }
            part(SubPage; 86231)
            {
                SubPageLink = "GLN Type" = FILTER('<>Agreement'), code = field(Code);
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Connection Card")
            {
                Caption = 'Connection Card';
                ApplicationArea = All;
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction();
                begin
                    Page.Run(Page::"EDI Connection Card", Rec);
                end;
            }
            action("Setup")
            {
                Caption = 'Edi Setup';
                ApplicationArea = All;
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction();
                begin
                    Page.Run(Page::"EDI Setup");
                end;
            }
            action("ImportOrders")
            {
                Caption = 'Send Inventory Report';
                ApplicationArea = All;
                Image = NewOrder;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction();
                var
                    InvRep: report EDI_Create_InvRPT;
                begin
                    InvRep.Run;
                end;
            }

        }
    }
}
