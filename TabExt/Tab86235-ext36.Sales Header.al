tableextension 86234 EDI_salesheader extends "Sales Header"
{
    fields
    {
        field(86230;"Edi Order-ID";integer)
        {     
            Caption = 'Edi Order-ID';
        }
        field(86232;"EDI Created";Date)
        {
            Caption = 'Edi Created';
        }     
        field(86233;"EDI Order";Boolean)
        {
            Caption = 'Edi Order';

            Trigger OnValidate();
            var
                EDIHeader:Record "EDI Header";
                EDiMgt:Codeunit EDI_Mgt;
            begin

                If "EDI Order" Then begin
                    If "Edi Order-ID" = 0 Then 
                        "Edi Adhock Order" := True;

                    EDiMgt.UpdateAdhockOrder(rec);
                End;
  
                If EDIHeader.Get("Edi Order-ID") then begin
                    If "EDI Order" then
                        EDIHeader."SO Order No." := "No."
                    else begin
                        If Not confirm(StrSubstNo(Txt1000,"Edi Order-ID")) then
                           exit;

                        EDIHeader."SO Order No." := Txt1001;
                    End;
                    EDIHeader.Modify;
                end;
            End;             
        }    
        field(86234;"EDI Filcounter";Code[10])
        {
            Caption = 'Edi Filcounter';
        }         
        field(86235;"Edi Adhock Order";Boolean)
        {
            Caption = 'Edi Adhock Order';
        }
        field(86236;"Edi Order NOT Confirmed";Integer)
        {
            Caption = 'EDI Order NOT Confirmed';
            CalcFormula = Count("sales header" Where ("Document Type" = const(order),"EDI Order" = Const(true),"EDI Created" = filter('')));

            FieldClass = FlowField;
        }
        field(86237;"EDI Order With Error";Integer)
        {
            Caption = 'Edi Order With Error';
            CalcFormula = Count("EDI Header" Where ("Import Error"= const(true)));
            FieldClass = FlowField;
        }
        field(86238;"Edi Invoice No.";Code[20])
        {
            Caption = 'Edi Invoice No.';
            
            trigger OnValidate();
            Var
                SalesInvHeader:Record "Sales Invoice Header";
            begin
                If (rec."Document Type" <> rec."Document Type"::"Credit Memo") and (rec."Edi Invoice No." <> '') then
                    Error(Txt1002);

                If not SalesInvHeader.Get(rec."Edi Invoice No.") then
                    Error(Txt1003);

                rec."Your Reference" := SalesInvHeader."Your Reference";
            End;

            trigger OnLookup();
            var
                SalesInvHeader:Record "Sales Invoice Header";
            Begin
                SalesInvHeader.SetRange("Sell-to Customer No.","Sell-to Customer No.");
                If page.RunModal(Page::"Posted Sales Invoices",SalesInvHeader) = "Action"::LookupOK then begin
                    "Edi Invoice No." := SalesInvHeader."No.";
                    rec."Your Reference" := SalesInvHeader."Your Reference";
                End;
            End;
        }
    }
    var
        Txt1000:Label 'Ordre er koblet til EDI-Ordre %1. Skal kobling oppheves ?';
        Txt1001:Label 'Deleted';
        Txt1002:Label 'Edi Invoice No. kan kun fylles ut ved kreditnota';
        Txt1003:Label 'Faktura for kreditering finnes ikke';
 }
