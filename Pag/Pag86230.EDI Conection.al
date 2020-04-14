page 86230 "EDI Connection"
{
    Caption = 'Edi Connection';
    CardPageID = "EDI Connection";
    PageType = List;
    SourceTable = 86230;
    SourceTableView = WHERE("GLN Type"=FILTER('Agreement'));
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Code;Code)
                {
                }
                field("Name";"Customer Name")
                {
                }
                field("GLN";"Owner GLN")
                {
                }
                field("EDI Type";"EDI Type")
                {
                }
                field("Validate GLN";"Validate GLN")
                {
                }
                field("Order";"Order")
                {
                }
                 field("Shipment";"Shipment")
                {
                }
                 field("Invoice";"Invoice")
                {
                }
                field(INVRPT;INVRPT)
                {
                }
                field("Allow Edi AdHock";"Allow Edi AdHock")
                {
                  }
                field("Credited Invoice Required";"Credited Invoice Required")
                {
                }
                field("INVRPT Location Filter";"INVRPT Location Filter")
                {
                    visible = false;
                }
                field("Item (Charge)";"Item (Charge)")
                {
                    Visible = false;
                }
                 field("Gln Customer";"Gln Customer")
                {
                }
                field("Gln Shipment";"Gln Shipment")
                {
                }
                field("Gln Invoice";"Gln Invoice")
                {
                }
                field("File Path in";"File Path in")
                {
                    Visible = False;

                    trigger OnAssistEdit();
                    var
                        FileMgt : Codeunit 419;
                        FileName : Text[1024];
                        OpenDialogCaption : Label 'Folder';
                        
                    begin
                        IF FileMgt.SelectFolderDialog(OpenDialogCaption,FileName) then
                            "File Path in" := FileName;
                        
                    end; 
                }
                field("File Path out";"File Path Out")
                {
                    Visible = False;
                    
                    trigger OnAssistEdit();
                    var
                        FileMgt : Codeunit 419;
                        FileName : Text[1024];
                        OpenDialogCaption : Label 'Folder';
                        
                    begin
                        IF FileMgt.SelectFolderDialog(OpenDialogCaption,FileName) then
                            "File Path Out" := FileName;
                        
                    end; 
                }
                field("File Path Archive Inn";"File Path Archive Inn")
                {
                    Visible = False;
                }
                field("File Path Archive Out";"File Path Archive Out")
                {
                    Visible = False;
                }
                field("Order Counter";"Order Counter")
                {
                    Visible = False;
                }
                field("Invoice Counter";"Invoice Counter")
                {
                    Visible = False;
                }
                field("InvRPT Counter";"InvRPT Counter")
                {
                }
                field("Filter Incomming Orders";"Filter Incomming Orders")
                {
                    Visible = False;
                }
                field("File Name Orders";"File Name Orders")
                {
                    Visible = False;
                }
                field("File Name Shipment";"File Name Shipment")
                {
                    Visible = False;
                }
                field("File Name Invoice";"File Name Invoice")
                {
                    Visible = False;
                }
                field("File Name Credit Memo";"File Name Credit Memo")
                {
                    Visible = False;
                }
                field("File Name INVRPT";"File Name INVRPT")
                {
                    Visible = False;
                }
            }   
            part(SubPage;86231)
            {
                SubPageLink = "GLN Type"=FILTER('<>Agreement'), code = field(Code);
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
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction();
                begin
                    Page.Run(Page::"EDI Connection Card",Rec);
                end;
            }
            action("Setup")
            {
                Caption = 'Edi Setup';
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
