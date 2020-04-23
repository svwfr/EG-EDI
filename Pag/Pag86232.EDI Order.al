page 86232 "EDI Order"
{
    Caption = 'Edi Order';
    PageType = List;
    SourceTable = 86231;
    //Editable = False;
    UsageCategory = Administration;
    InsertAllowed = false;

    
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                 field("Entry No";"Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Message Ref.";"Message Ref.")
                {
                    ApplicationArea = All;
                    Visible = False;
                }
                field("Message Date"; "Message Date")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Document Type";"Document Type")
                {
                }
                field("Customer Order No."; "Customer Order No.")
                {
                    ApplicationArea = All;
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = All;
                }
                field("Delivery Date"; "Delivery Date")
                {
                    ApplicationArea = All;
                }
                field("GLN Supplier"; "GLN SU")
                {
                    ApplicationArea = All;
                    ToolTip = 'GLN Supplier: Selskapet som produserer eller på annen måte eier varer og gjør dem tilgjengelig ved handel. Denne parten oppfattes som leverandøren av varene.';
                }
                field("GLN Owner";"GLN Owner")
                {
                    ApplicationArea = All;
                    ToolTip = 'GLN Owner: Kjede-eier som EDI kontrakt er inngått med';
                }
                field("GLN SellTo"; "GLN By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Selskap som varer skal selges til.';
                }
                field("GLN ShipTo"; "GLN DP")
                {
                    ApplicationArea = All;
                    ToolTip = 'Selskap som varer skal leveres til. (Part (selskap) varen stilles til disposisjon for.)';
                }
                field("GLN BillTo"; "GLN IV")
                {
                    ApplicationArea = All;
                    ToolTip = 'Selskap som faktura skal sendes til.';
                }
                field("Bill-to Customer No.";"Bill-to Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Sette av "Check Order" etter EDI-Connection oppsett av hvem som er betaler';
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Sette av "Check Order" etter EDI-Connection oppsett av hvem som er kjøper';
                }
                field("Sell-to Customer Name";"Sell-to Customer Name")
                {
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = All;
                }
                field("SO Order No."; "SO Order No.")
                {
                    ApplicationArea = All;

                    trigger OnLookup(var Text : Text) : Boolean;
                    Var 
                        SalesOrder:Record "Sales Header";
                    begin
                        If SalesOrder.get(SalesOrder."Document Type"::Order,"SO Order No.") then begin
                            SalesOrder.SetRecFilter;                            
                            page.Run(Page::"Sales Order",SalesOrder);
                        End;
                    end;
                }
                field("Order send";"Order send")
                {
                    ApplicationArea = All;
                }
                field("Invoice send";"Invoice send")
                {}
                field("Import Error"; "Import Error")
                {
                    ApplicationArea = All;
                }
                field("Import message"; "Import message")
                {
                    ApplicationArea = All;
                }
                field("Shipment method Code"; "Shipment method Code")
                {
                    Visible = false;
                    ApplicationArea = All;
                }
                field("Currency Code"; "Currency Code")
                {   
                    Visible = false;
                    ApplicationArea = All;
                }
                 field("Order Instruction"; "Order Instruction")
                {
                    Visible = false;
                    ApplicationArea = All;
                }
                field("Order Type"; "Order Type")
                {
                    Visible = False;
                    ApplicationArea = All;
                }
                field("Adhock Order";"Adhock Order")
                {
                    ApplicationArea = All;
                }
                field("Credited Invoice No.";"Credited Invoice No.")
                {
                }
                field("Applies-to ID";"Applies-to ID")
                {
                }
                field("EDI File Name";"EDI File Name")
                {
                    Visible = False;
                }

            }   
            part(SubPage;86233)
            {
                SubPageLink = "Entry No."= Field("Entry No.");
            }
           
        }
    } 

    actions
    {
        area(processing)
        {
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
                Caption = 'Import Orders';
                Image = GetOrder;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction();
                var
                    EDImgt: Codeunit 86230;
                begin
                    EDImgt.ImportOrders;
                end;
            }
            action("UpdateSalesLine")
            {
                Caption = 'Update Sales Line';
                Image = NewOrder;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Visible = False;

                trigger OnAction();
                var
                    EDImgt: Codeunit 86230;
                begin
                    EDImgt.UpdateSalesLine;
                end;
            }     
            action("UpdateItemCharge")
            {
                Caption = 'Update Item Charge';
                Image = NewOrder;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Visible = False;

                trigger OnAction();
                var
                    EDImgt: Codeunit 86230;
                begin
                    EDImgt.FixItemChargeInvLine;
                end;
            }   

            action("UpdateEDICustAddress")
            {
                Caption = 'Update EDI Cust Addr.';
                Image = NewOrder;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Visible = False;

                trigger OnAction();
                var
                    EDImgt: Codeunit 86230;
                begin
                    EDImgt.UpdateEDICustAddress();
                end;
            }   

            action("CheckOrders")
            {
                Caption = 'Check Orders';
                Image = NewOrder;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction();
                var
                    EDImgt: Codeunit 86230;
                begin
                    EDImgt.CheckOrders();
                end;
            }           
         action("CreateOrders")
            {
                Caption = 'Create Orders';
                Image = NewOrder;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction();
                var
                    EDImgt: Codeunit 86230;
                begin
                    EDImgt.CreateOrders;
                end;
            }
            action("EDI Logg")
            {
                Caption = 'Edi logg';
                Image = InteractionLog;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction();
                Var 
                    EdiLogg:Record EDI_Document_Logg;
                begin
                    EdiLogg.setrange("Customer Order No.","Customer Order No.");
                    Page.Run(Page::"EDI Document Logg",Edilogg);
                end;
            }
            action("View Edi File")
            {
                Caption = '"View Edi File"';
                Image = View;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Visible = True;

                trigger OnAction();
                var
                    EdiMgt:Codeunit EDI_Mgt;
                    FileMgt:Codeunit "File Management";
                    EdiConn:Record EDI_Connection;
                    EdiLogg:Record EDI_Document_Logg;
                    FilePath:text[250];
                begin
                    EdiConn.Setrange("GLN Type",EdiConn."GLN Type"::Agreement);
                    EdiConn.setrange("Owner GLN","GLN Owner");
                    EdiConn.FindFirst;
                    FilePath := EdiMgt.GetFileNameIn(EdiConn,true);

                    If "EDI File Name" = '' Then Begin
                        EdiLogg.Setrange("Customer Order No.","Customer Order No.");
                        EdiLogg.SetFilter("Document No.",'<>%1','DELETED');
                        If EdiLogg.findfirst then begin
                            "EDI File Name" := EdiLogg.Filename;
                            CurrPage.SaveRecord;
                        End;
                    End;

                    If FileMgt.ServerFileExists(DelChr(FilePath,'>','\')+'\'+"EDI File Name") then
                        Hyperlink(DelChr(FilePath,'>','\')+'\'+"EDI File Name");
                    
 
                End;
            }

            action("Download")
            {
                Caption = 'Download Files';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Visible=False;

                trigger OnAction();
                begin
                    Page.Run(Page::"EDI Document Logg");
                end;
            }
            action("Upload")
            {
                Caption = 'upload files';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Visible=False;

                trigger OnAction();
                begin
                    Page.Run(Page::"EDI Document Logg");
                end;
            }
        }
    }
    
    trigger OnOpenPage();
    begin
        If GetFilter("Entry No.") = '' Then
            setrange("SO Order No.",'');
    end;

    var
        txt001:label 'Upload Files';
 }
