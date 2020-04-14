codeunit 86231 "EDI_Events"
{

    EventSubscriberInstance = StaticAutomatic;

    [EventSubscriber(ObjectType::Table, 37, 'OnAfterValidateEvent', 'No.', false, false)]
    local procedure EDI_SalesLineOnAfterValidateNo(var Rec : Record "sales line";var xRec : Record "sales line";CurrFieldNo : Integer);
    var
        SalesHeader:Record "Sales Header";
        EDIConnection:Record EDI_Connection;
        EDILine:Record "EDI Lines";
        ItemCrossref:Record "Item Cross Reference";
        EDIMgt:Codeunit EDI_Mgt;
        EAN:Code[30];

    begin
             
        SalesHeader.Get(Rec."Document Type",Rec."Document No.");
        If Not SalesHeader."EDI Order" then
            Exit;

        If SalesHeader."Edi Adhock Order" then Begin
            if Not EDIMgt.CheckEAN(rec."No.",rec."Unit of Measure Code",EAN,true) then
                If EDIMgt.CheckChargeitem(rec."Sell-to Customer No.",rec."No.") Then
                    rec."EDI Item (Charge)" := true
                else
                    Error(Txt1001);      
        End
        Else Begin
            EDILine.setrange("SO Order No.",rec."Document No.");
            EDILine.setrange("SO Line No.",REC."Line No.");
            If EDILine.FindFirst then Begin
                If rec."No." <> EDILine."SO Item No." then
                    Error(Txt1002);
            End
            else begin
                If EDIMgt.CheckChargeitem(rec."Sell-to Customer No.",rec."No.") Then
                    rec."EDI Item (Charge)" := true
                else
                    Error(StrSubstNo(Txt1003,Rec."no.",Rec."Line No."));      
            End;
        End;
        rec.Validate("Unit of Measure Code");
    end;

    [EventSubscriber(ObjectType::Table, 37, 'OnAfterValidateEvent', 'Quantity', false, false)]
    local procedure EDI_SalesLineOnAfterValidateQty(var Rec : Record "sales line";var xRec : Record "sales line";CurrFieldNo : Integer);
    var
        EDIOrderLine:Record "EDI Lines";

    begin
        If CurrFieldNo <> Rec.FIELDNO("Line Discount %") Then
            If EDIOrderLine.Get(Rec."Edi Order ID",Rec."EDI Order Line") then 
                If EDIOrderLine."PO Line Discount" <> 0 then
                    Rec.Validate("Line Discount %",EDIOrderLine."PO Line Discount");
    End;


    [EventSubscriber(ObjectType::Codeunit, 6620, 'OnBeforeModifySalesHeader', '', false, false)]
    local procedure EDI_CopyDocument_OnBeforeModifySalesHeader(VAR ToSalesHeader : Record "Sales Header";FromDocType : Option;FromDocNo : Code[20];IncludeHeader : Boolean);
    begin
        Clear(ToSalesHeader."EDI Created");
        ToSalesHeader."Edi Adhock Order" := False;
        ToSalesHeader."EDI Filcounter" := '';
        ToSalesHeader."EDI Order" := False;
        ToSalesHeader."Edi Order-ID" := 0;
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnBeforeModifyEvent', '', false, false)]
    local procedure EDI_SalesHeader_Before_Modify(var Rec : Record "Sales Header";var xRec : Record "Sales Header";RunTrigger : Boolean);
    Var
        EDIMgt: codeunit EDI_Mgt;
    begin
        If rec."Edi Adhock Order" Then
            If (Rec."Sell-to Customer No." <> xRec."Sell-to Customer No.") or
                (Rec."Bill-to Customer No." <> xRec."Bill-to Customer No.") or
                (rec."Your Reference" <> xrec."Your Reference") or
                (Rec."EDI Order" <> xRec."EDI Order") or 
                (rec."Edi Invoice No." <> xRec."Edi Invoice No.") then
                EDIMgt.UpdateAdhockOrder(Rec);
    end;

    [EventSubscriber(ObjectType::codeunit, 80, 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforePostSalesDoc(VAR SalesHeader : Record "Sales Header");
    Var 
        SalesLine:Record "Sales Line";
        EdiConn:Record EDI_Connection;
        EdiOrderLine:Record "EDI Lines";
        ItemCrossRef:Record "Item Cross Reference";
        EDIMgt:codeunit EDI_Mgt;
        EAN:Code[30];
    begin
        If Not SalesHeader."EDI Order" then
            Exit;

        SalesLine.setrange("Document No.",SalesHeader."No.");
        SalesLine.setrange("Document Type",SalesHeader."Document Type");
        if SalesLine.findset then
        repeat
            
            EDIMgt.GetParnerConnection(SalesHeader."Sell-to Customer No.",EdiConn);
            If EdiConn."Credited Invoice Required" Then
                If SalesHeader."Your Reference" = '' then
                    Error(Txt1004);

            If SalesHeader."Edi Adhock Order" Then begin
                If Not EDIMgt.CheckEAN(SalesLine."No.",SalesLine."Unit of Measure Code",Ean,false) Then
                    If Not SalesLine."EDI Item (Charge)" then
                        Error(StrSubstNo(Txt1005,SalesLine."No.",SalesLine."Line No."));    
            End
            Else begin
                If EdiOrderLine.Get(SalesLine."Edi Order ID",SalesLine."EDI Order Line") Then begin
                    If SalesLine."No." <> EDIOrderLine."SO Item No." then
                        Error(StrSubstNo(Txt1006,SalesLine."No.",EDIOrderLine."PO Item No.",SalesLine."Line No."));
                    If SalesLine."Unit of Measure Code" <> EDIOrderLine."SO Unit of Measure" then
                        Error(StrSubstNo(Txt1007,SalesLine."No.",EDIOrderLine."PO Item No.",SalesLine."Line No."));    
                End 
                Else Begin
                    If Not SalesLine."EDI Item (Charge)" then
                        Error(Txt1008)
                End;
            End;
            If (SalesLine."Qty. to Invoice" > 0) and (SalesLine."Unit Price" = 0) then
                Error(Txt1009);

        Until SalesLine.Next = 0;
    End;

    [EventSubscriber(ObjectType::codeunit, 80, 'OnAfterPostSalesDoc', '', false, false)]
    local procedure OnBeforeInsertSalesInvoice(VAR SalesHeader : Record "Sales Header";VAR GenJnlPostLine : Codeunit "Gen. Jnl.-Post Line";SalesShptHdrNo : Code[20];RetRcpHdrNo : Code[20];SalesInvHdrNo : Code[20];SalesCrMemoHdrNo : Code[20]);
    var
        rSalesInoiceheader:Record "Sales Invoice Header";
        rSalesInvoiceLine:record "Sales Invoice Line";
        rSalesOrderLine: Record "Sales Line";
        EDISetup:Record EDI_Setup;
        EDIMgt: Codeunit EDI_Mgt;
        InitDate:date;
    begin
        If SalesHeader."EDI Order" Then begin
            EDISetup.get;
            
            if SalesInvHdrNo <> '' then begin
                rSalesInoiceheader.Get(SalesInvHdrNo);
                rSalesInoiceheader."EDI Order" := true;
                rSalesInoiceheader."Edi Order-ID" := SalesHeader."Edi Order-ID";
                rSalesInoiceheader."EDI Created" := InitDate;
                rSalesInoiceheader.Modify;
                
                If EDISetup."Automatic EDI Invoice" then
                   EDIMgt.SendEDIInvoice(rSalesInoiceheader,False);
            End;
        end;
    End;

    var
        Txt1001:Label 'EAN nummer mangler for angitt vare. Kun frakt kan registreres uten EAN.';
        Txt1002:Label 'Linje er koblet til edi ordre og kan ikke endres';
        Txt1003:Label 'Kun frakt kan legge til en eksisterende Edi ordre. Vare %1, linje %2';
        Txt1004:Label 'Edi fakturanr må fylles ut.';
        Txt1005:Label 'Ean finnes ikke for vare %1, linjenr %2. Kun Frakt kan registreres uten EAN';
        Txt1006:Label 'Varenr %1 stemmer ikke overens med varenummer %2 på Ediordrde. Line %3';
        Txt1007:label 'Varenr %1 stemmer ikke overens med varenummer %2 på Ediordrde. Line %3';
        Txt1008:Label 'Kun frakt kan legges til eksisterende EDI Ordre.';
        Txt1009:Label 'Salgspris kan ikke være 0, benytt 100% linjerabatt i stedet.';

}