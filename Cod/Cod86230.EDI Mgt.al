codeunit 86230 "EDI_Mgt"
{
    trigger OnRun();
    begin
        ImportOrders();
        CreateOrders();
    End;

    Procedure ImportOrders();
    Var
        EDI_Connection: Record 86230;
        EDI_Types: record 86233;

    Begin
        EDI_Connection.Setrange("GLN Type", EDI_Connection."GLN Type"::Agreement);
        EDI_Connection.SetRange(Active,true);
        If EDI_Connection.FindSet then
            repeat
                If EDI_Types.get(EDI_Connection."EDI Type") Then
                    If EDI_Types."CU Import Orders" <> 0 Then
                        Codeunit.run(EDI_Types."CU Import Orders", EDI_Connection);
            Until EDI_Connection.Next = 0;
    End;

    procedure CreateOrders();
    var
        EDI_Orders: Record 86231;

    Begin
        EDI_Orders.SETRANGE("SO Order No.", '');
        EDI_Orders.SetRange("Import Error",false);
        If EDI_Orders.FindSet then Begin
            repeat
                CreateOneOrder(EDI_Orders);
                Commit;
            Until EDI_Orders.Next = 0;
        End;
    End;

    procedure CreateOneOrder(Var EDIOrder: Record 86231);
    var
        EDI_Order: Record 86231;
        EDI_OrderLines: Record 86232;
        SalesHeader: Record 36;
        EDI_Logg: record EDI_Document_Logg;

    begin
        EDI_Order.Get(EDIOrder."Entry No.");
        IF CheckEDIOrder("EDI_Order") then
            If CreateSalesHeader(SalesHeader, "EDI_Order") Then Begin
                CreateSalesLine(SalesHeader, "EDI_Order");
                EDI_Order."SO Order No." := SalesHeader."No.";
            End;
        EDI_Order.Modify;
        EdiOrder := EDI_Order;
        EDI_Logg.UpdateOrderEntry(EDIOrder);
    end;

    procedure CheckOrders();
    var
        EDI_Orders: Record 86231;
    Begin
        EDI_Orders.SETRANGE("SO Order No.", '');
        If EDI_Orders.FindSet then Begin
            repeat
                CheckEDIOrder("EDI_Orders");
                EDI_Orders.Modify;
            Until EDI_Orders.Next = 0;
        End;
    End;

    procedure CheckEDIOrder(Var EDI_Order: Record 86231): Boolean;
    Var
        EDI_Connection: Record EDI_Connection;
        EDI_Agreement: Record EDI_Connection;
        EDI_Orderline: Record 86232;
        EDI_Order2: Record "EDI Header";
        Item: Record item;
        ItemUnit: Record "Item Unit of Measure";
        ItemCrossref: Record "Item Cross Reference";
        Customer: record customer;
        ShipToAddr: record "Ship-to Address";
        MissingConnection: array[10] of Boolean;
        CustExist: Boolean;
        CustBlocked: Boolean;
        ItemExists: boolean;
        LineError: Boolean;
        ShipToAddrExist: Boolean;
        TestItem: text[30];

    Begin
        CustExist := False;
        CustBlocked := False;
        ShipToAddrExist := false;

        EDI_Order2.setrange("GLN Owner", EDI_Order."GLN Owner");
        EDI_Order2.setrange("Customer Order No.", EDI_Order."Customer Order No.");
        EDI_Order2.Setfilter("Entry No.", '<%1', EDI_Order."Entry No.");
        If EDI_Order2.FindFirst then begin
            EDI_Order."SO Order No." := Txt1011;
            EDI_Order."Import Message" := Txt1012;
            Exit(false);
        End;

        EDi_Connection.Setrange("GLN Type", EDi_Connection."GLN Type"::By);
        EDi_Connection.Setrange(GLN, EDI_Order."GLN BY");
        If EDi_Connection.Findfirst then begin
            EDI_Agreement.Setrange(Code, EDI_Connection.code);
            EDI_Agreement.setrange("GLN Type", EDI_Connection."GLN Type"::Agreement);
            If Not EDI_Agreement.FindFirst Then begin
                EDI_Order."Import Error" := True;
                EDI_Order."Import Message" := StrSubstNo(Txt1013, EDI_Connection.code);
                Exit(false);
            End;
        End
        else begin
            EDI_Order."Import Error" := True;
            EDI_Order."Import Message" := StrSubstNo(Txt1014, EDI_Order."GLN BY");
            Exit(false);
        End;

        If EDI_Agreement."Gln Customer" = EDI_Agreement."Gln Customer"::BY Then Begin
            //Salg til kunde er BY
            EDi_Connection.Setrange("GLN Type", EDi_Connection."GLN Type"::By);
            EDi_Connection.Setrange(GLN, EDI_Order."GLN BY");
            If EDi_Connection.Findfirst then Begin
                EDI_Order."Sell-to Customer No." := EDi_Connection."Customer No.";
                Custexist := Customer.Get(EDI_Order."Sell-to Customer No.");
                CustBlocked := customer.Blocked <> customer.Blocked::" ";

                If EDI_Order."GLN Owner" = '' then begin
                    EDI_Agreement.get(EDI_Connection.code, '', EDI_Connection."GLN Type"::Agreement, '');
                    EDI_Order."GLN Owner" := EDI_Agreement."Owner GLN";
                End;
            End
            Else
                MissingConnection[1] := True;
        End
        Else
            If EDI_Agreement."Gln Customer" = EDI_Agreement."Gln Customer"::DP Then Begin
                //Salg til Kunde er DP
                EDi_Connection.Setrange("GLN Type", EDi_Connection."GLN Type"::By);
                EDi_Connection.Setrange(GLN, EDI_Order."GLN DP");
                If EDi_Connection.Findfirst then Begin
                    EDI_Order."Sell-to Customer No." := EDi_Connection."Customer No.";
                    Custexist := Customer.Get(EDI_Order."Sell-to Customer No.");
                    CustBlocked := customer.Blocked <> customer.Blocked::" ";
                end
                else
                    if EDI_Agreement."Validate GLN" then
                        MissingConnection[1] := True;
            end;


        If EDI_Agreement."Gln Invoice" = EDI_Agreement."Gln Invoice"::IV Then Begin
            //Betal til Kunde er IV
            EDi_Connection.Setrange("GLN Type", EDi_Connection."GLN Type"::IV);
            EDi_Connection.Setrange(GLN, EDI_Order."GLN IV");
            If EDi_Connection.Findfirst then
                EDI_Order."Bill-to Customer No." := EDi_Connection."No."
            else
                if EDI_Agreement."Validate GLN" then
                    MissingConnection[3] := True;
        End
        else
            If EDI_Agreement."Gln Invoice" = EDI_Agreement."Gln Invoice"::BY Then Begin
                //Betal til Kunde er BY
                EDi_Connection.Setrange("GLN Type", EDi_Connection."GLN Type"::By);
                EDi_Connection.Setrange(GLN, EDI_Order."GLN BY");
                If EDi_Connection.Findfirst then
                    EDI_Order."Bill-to Customer No." := EDi_Connection."No."
                else
                    if EDI_Agreement."Validate GLN" then
                        MissingConnection[3] := True;
            End;


        ShipToAddrExist := True;
        If EDI_Agreement."Gln Shipment" = EDI_Agreement."Gln Shipment"::DP Then Begin
            ShipToAddrExist := True;

            EDi_Connection.Setrange("GLN Type", EDi_Connection."GLN Type"::DP);
            EDi_Connection.Setrange(GLN, EDI_Order."GLN DP");
            IF EDi_Connection.FindFirst then Begin
                IF EDI_Connection."No." <> '' Then Begin
                    If ShipToAddr.Get(EDI_Order."Sell-to Customer No.", EDI_Connection."No.") then
                        EDI_Order."Ship-to Code" := EDi_Connection."NO."
                    Else
                        ShipToAddrExist := false;
                End;
            End
            Else
                If EDI_Agreement."Validate GLN" then
                    MissingConnection[2] := True;
        End
        Else begin
            //Hvis DP ikke er angitt skal DP være lik Salg til Kunde GLN
            //If (EDI_Order."GLN DP" <> '') and (EDI_Order."GLN BY" <> EDI_Order."GLN DP") Then
            //   MissingConnection[2] := True;
        End;


        LineError := False;
        EDI_Orderline.SetRange("Entry No.", EDI_Order."Entry No.");
        EDI_Orderline.SetRange(ItemAction, EDI_Orderline.ItemAction::" ");
        If EDI_Orderline.findfirst then
            repeat
                ItemExists := True;
                EDI_Orderline.Message := '';
                case EDI_Orderline."PO Item Type" of
                    EDI_Orderline."PO Item Type"::EN:
                        begin
                            ItemCrossref.setrange("Cross-Reference Type", ItemCrossref."Cross-Reference Type"::"Bar Code");
                            ItemCrossref.setrange("Cross-Reference No.", EDI_Orderline."PO Item No.");
                            If ItemCrossref.FindFirst Then begin
                                EDI_Orderline."SO Item No." := ItemCrossref."Item No.";
                                EDI_Orderline."SO Unit of Measure" := ItemCrossref."Unit of Measure";
                                EDI_Orderline."SO Variant Code" := ItemCrossref."Variant Code";
                            End
                            Else begin
                                testItem := DelChr(EDI_Orderline."PO Item No.", '<>', ' ');
                                If strlen(TestItem) < 13 then begin
                                    TestItem := padstr('', 13 - strlen(TestItem), '0') + TestItem;
                                End;
                                ItemCrossref.setrange("Cross-Reference Type", ItemCrossref."Cross-Reference Type"::"Bar Code");
                                ItemCrossref.setrange("Cross-Reference No.", TestItem);
                                If ItemCrossref.FindFirst Then begin
                                    EDI_Orderline."SO Item No." := ItemCrossref."Item No.";
                                    EDI_Orderline."SO Unit of Measure" := ItemCrossref."Unit of Measure";
                                    EDI_Orderline."SO Variant Code" := ItemCrossref."Variant Code";
                                End
                                Else
                                    ItemExists := False;
                            End;
                        end;
                    EDI_Orderline."PO Item Type"::GTIN:
                        begin
                            Item.SetRange(GTIN, EDI_Orderline."PO Item No.");
                            if Item.FindFirst() then
                                EDI_Orderline."SO Item No." := Item."No.";
                        end;
                    else begin
                            Item.SetRange("No.", EDI_Orderline."PO Item No.");
                            if Item.FindFirst() then
                                EDI_Orderline."SO Item No." := Item."No.";
                        end;
                end;


                If Item.Get(EDI_Orderline."SO Item No.") Then Begin
                    If EDI_Orderline."SO Unit of Measure" = '' then
                        EDI_Orderline."SO Unit of Measure" := Item."Sales Unit of Measure";
                End
                Else
                    ItemExists := False;

                If Not ItemExists then
                    EDI_Orderline.Message := Txt1015;
                If item.Blocked then
                    EDI_Orderline.Message := Txt1016;

                IF NOT ItemUnit.get(EDI_Orderline."SO Item No.", item."Sales Unit of Measure") then
                    EDI_Orderline.Message := EDI_Orderline.Message + Txt1017;

                IF NOT ItemUnit.get(EDI_Orderline."SO Item No.", EDI_Orderline."SO Unit Of Measure") then
                    EDI_Orderline.Message := EDI_Orderline.Message + Txt1018;

                EDI_Orderline.Message := CopyStr(EDI_Orderline.Message, 2);

                If EDI_Orderline.Message <> '' then
                    LineError := True;

                EDI_Orderline.modify;
            Until EDI_Orderline.next = 0;


        EDI_Order."Import Error" := False;
        EDI_Order."Import Message" := '';

        If Not CustExist then
            EDI_Order."Import Message" := Txt1019;

        If not ShipToAddrExist Then
            EDI_Order."Import Message" := EDI_Order."Import Message" + Txt1020;

        If MissingConnection[1] then
            EDI_Order."Import Message" := EDI_Order."Import Message" + Txt1021;
        If MissingConnection[2] then Begin
            EDI_Order."Import Message" := EDI_Order."Import Message" + Txt1022;
        End;
        If MissingConnection[3] then
            EDI_Order."Import Message" := EDI_Order."Import Message" + Txt1023;
        If EDI_Order."Import Message" <> '' then
            EDI_Order."Import Message" := Txt1024 + CopyStr(EDI_Order."Import Message", 2);

        If CustBlocked Then
            EDI_Order."Import Message" := Txt1025 + EDI_Order."Import Message";


        If LineError then
            If EDI_Order."Import Message" = '' then
                EDI_Order."Import Message" := EDI_Order."Import Message" + Txt1026
            else
                EDI_Order."Import Message" := EDI_Order."Import Message" + Txt1026;

        EDI_Order."Import Error" := EDI_Order."Import Message" <> '';
        OnAfterCheckEDIOrder(EDI_Order);
        Exit(Not EDI_Order."Import Error");
    End;

    procedure CreateSalesHeader(Var SalesHeader: Record 36; Var
                                                                EDI_Order: Record 86231): Boolean;
    Begin
        Clear(SalesHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader.Insert(true);

        SalesHeader.SetHideValidationDialog(True);
        SalesHeader.Validate("Sell-to Customer No.", EDI_Order."Sell-to Customer No.");
        SalesHeader.Validate("Ship-to Code", EDI_Order."Ship-to Code");
        If (SalesHeader."Bill-to Customer No." <> EDI_Order."Bill-to Customer No.") and (EDI_Order."Bill-to Customer No." <> '') then
            SalesHeader.Validate("Bill-to Customer No.", EDI_Order."Bill-to Customer No.");

        SalesHeader."External Document No." := EDI_Order."Customer Order No.";
        SalesHeader."Your Reference" := EDI_Order."Customer Order No.";
        SalesHeader."Edi Order-ID" := EDI_Order."Entry No.";
        SalesHeader."EDI Order" := True;
        SalesHeader.validate("Order Date", EDI_Order."Order Date");
        SalesHeader.Validate("Requested Delivery Date", EDI_Order."Delivery Date");
        SalesHeader.Validate("Shipment Date", EDI_Order."Delivery Date");

        If (EDI_Order."Currency Code" <> '') and (EDI_Order."Currency Code" <> 'NOK') then
            SalesHeader.Validate("Currency Code", EDI_Order."Currency Code");

        OnAfterInsertSalesHeader(SalesHeader, EDI_Order);
        SalesHeader.Modify(true);
        Exit(true);
    End;

    procedure CreateSalesLine(Var SalesHeader: Record 36; Var EDI_Order: Record 86231);
    var
        EDI_OrderLines: record 86232;
        SalesOrderLine: REcord 37;
        LineNo: Integer;

    Begin
        EDI_OrderLines.SETRANGE("Entry No.", EDI_Order."Entry No.");
        EDI_Orderlines.Setrange(ItemAction, EDI_OrderLines.ItemAction::" ");
        If EDI_OrderLines.FindSet then
            Repeat
                LineNo := LineNo + 10000;
                SalesOrderLine.Init;
                SalesOrderLine."Document Type" := SalesHeader."Document Type";
                SalesOrderLine."Document No." := SalesHeader."No.";
                SalesOrderLine."Line No." := LineNo;
                SalesOrderLine.Insert(True);

                EDI_OrderLines."SO Order No." := SalesOrderLine."Document No.";
                EDI_OrderLines."SO Line No." := SalesOrderLine."Line No.";
                EDI_OrderLines.Modify;

                SalesOrderLine.SetHideValidationDialog(true);
                SalesOrderLine.Type := SalesOrderLine.Type::Item;
                SalesOrderLine.Validate("No.", EDI_OrderLines."SO Item No.");
                SalesOrderLine.Validate("Unit of Measure Code", EDI_OrderLines."So Unit Of Measure");
                SalesOrderLine.Validate(Quantity, EDI_OrderLines."PO Quantity");
                SalesOrderLine."Edi Order ID" := EDI_Order."Entry No.";
                SalesOrderLine."EDI Order Line" := EDI_OrderLines."Line No.";

                If EDI_OrderLines."PO Sales Price" <> 0 then begin
                    SalesOrderLine.validate("Unit price", EDI_OrderLines."PO Sales Price");
                    SalesOrderLine.validate("Line Discount %", EDI_OrderLines."PO Line Discount");
                End;
                OnAfterInsertSalesLine(SalesHeader, SalesOrderLine, EDI_Order, EDI_OrderLines);
                SalesOrderLine.Modify(true);

            Until EDI_OrderLines.Next = 0;
    End;

    Procedure CreateINVRPT(Var EDI_Connection: Record 86230);
    Var
        EDI_Types: record 86233;
    Begin
        If EDI_Connection.INVRPT Then Begin
            If EDI_Types.get(EDI_Connection."EDI Type") Then
                If EDI_Types."CU Export INVRPT" <> 0 Then
                    Codeunit.run(EDI_Types."CU Export INVRPT", EDI_Connection);
        end;
    End;

    Procedure SendEDIOrdercomfirmation(Var SalesHeader: Record "Sales Header");
    Var
        EDIConnection: Record EDI_Connection;
        EDITypes: Record EDI_Types;
        EDIHeader: Record "EDI Header";
        InitDate: Date;
    begin

        IF NOt SalesHeader."Edi Order" THEN
            ERROR(Txt1001);

        CASE CheckSendDocument(SalesHeader."Sell-to Customer No.", 'O') OF
            1:
                ERROR(Txt1008);
            2:
                ERROR(StrSubstNo(Txt1006, Salesheader."Sell-to Customer No."));
        END;

        IF SalesHeader."EDI created" <> InitDate THEN Begin
            IF NOT CONFIRM(Txt1002) THEN
                EXIT;
        End
        Else
            IF NOT CONFIRM(Txt1004) THEN
                EXIT;
        EDIHeader.Get(SalesHeader."Edi Order-ID");

        If NOt FindExportEDIConnection(SalesHeader."Sell-to Customer No.", EDIConnection, False, 'O') Then
            Error(StrSubstNo(Txt1006, SalesHeader."Sell-to Customer No."));

        If EDITypes.get(EDIConnection."EDI Type") Then
            If EDITypes."CU Export Orders" <> 0 Then Begin
                Codeunit.run(EDITypes."CU Export Orders", SalesHeader);
                Exit;
            End;

        Error(StrSubstNo(Txt1007, SalesHeader."Sell-to Customer No."));
    End;

    Procedure SendEDIInvoice(Var SalesInvHeader: Record "Sales Invoice Header"; ShowDialog: Boolean);
    Var
        EDIConnection: Record EDI_Connection;
        EDITypes: Record EDI_Types;
        EDIHeader: Record "EDI Header";
        Salesheader: Record "Sales Header";
        InitDate: Date;
    begin

        IF NoT SalesInvHeader."Edi Order" THEN
            ERROR(Txt1001);

        CASE CheckSendDocument(SalesInvHeader."Bill-to Customer No.", 'I') OF
            1:
                ERROR(Txt1009);
            2:
                ERROR(StrSubstNo(Txt1006, SalesInvHeader."Sell-to Customer No."));
        END;

        If ShowDialog Then begin
            IF SalesInvHeader."EDI Created" <> InitDate THEN Begin
                IF NOT CONFIRM(Txt1003) THEN
                    EXIT;
            End
            Else
                IF NOT CONFIRM(Txt1005) THEN
                    EXIT;
        End;

        EDIHeader.Get(SalesInvHeader."Edi Order-ID");

        If NOt FindExportEDIConnection(SalesInvHeader."Bill-to Customer No.", EDIConnection, False, 'I') Then
            Error(StrSubstNo(Txt1006, SalesInvHeader."Sell-to Customer No."));

        If EDITypes.get(EDIConnection."EDI Type") Then
            If EDITypes."CU Export Invoice" <> 0 Then Begin
                Codeunit.run(EDITypes."CU Export Invoice", SalesInvHeader);
                Exit;
            End;

        Error(StrSubstNo(Txt1007, SalesInvHeader."Sell-to Customer No."));
    End;

    Procedure SendEDICrMemo(Var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; ShowDialog: Boolean);
    Var
        EDIConnection: Record EDI_Connection;
        EDITypes: Record EDI_Types;
        EDIHeader: Record "EDI Header";
        Salesheader: Record "Sales Header";
        InitDate: Date;
    begin

        IF NoT SalesCrMemoHeader."Edi Order" THEN
            ERROR(Txt1001);

        CASE CheckSendDocument(SalesCrMemoHeader."Bill-to Customer No.", 'I') OF
            1:
                ERROR(Txt1009);
            2:
                ERROR(StrSubstNo(Txt1006, SalesCrMemoHeader."Sell-to Customer No."));
        END;

        If ShowDialog Then begin
            IF SalesCrMemoHeader."EDI Created" <> InitDate THEN Begin
                IF NOT CONFIRM(Txt1003) THEN
                    EXIT;
            End
            Else
                IF NOT CONFIRM(Txt1005) THEN
                    EXIT;
        End;

        EDIHeader.Get(SalesCrMemoHeader."Edi Order-ID");

        If NOt FindExportEDIConnection(SalesCrMemoHeader."Bill-to Customer No.", EDIConnection, False, 'I') Then
            Error(StrSubstNo(Txt1006, SalesCrMemoHeader."Sell-to Customer No."));

        If EDITypes.get(EDIConnection."EDI Type") Then
            If EDITypes."CU Export CrMemo" <> 0 Then Begin
                Codeunit.run(EDITypes."CU Export CrMemo", SalesCrMemoHeader);
                Exit;
            End;

        Error(StrSubstNo(Txt1007, SalesCrMemoHeader."Sell-to Customer No."));
    End;

    procedure FindExportEDIConnection(CustNo: code[20]; Var EDIConnection: Record EDI_Connection; Update: Boolean; Doctype: Code[3]): Boolean;
    begin
        If Not GetParnerConnection(CustNo, EDIConnection) then
            Exit(false);

        If update then begin
            If Doctype = 'O' Then begin
                IF EDIConnection."Order Counter" = '' THEN
                    EDIConnection."Order Counter" := '000001'
                ELSE
                    EDIConnection."Order Counter" := INCSTR(EDIConnection."Order Counter");
            end;

            If Doctype = 'I' Then begin
                IF EDIConnection."Invoice Counter" = '' THEN
                    EDIConnection."Invoice Counter" := '000001'
                Else
                    EDIConnection."Invoice Counter" := INCSTR(EDIConnection."Invoice Counter");
            End;
            EDIConnection.MODIFY;
        End;
        Exit(true);
    End;

    procedure CheckSendDocument(Var CustomerNo: code[20]; DocType: Code[1]): Integer;
    Var
        EDIConnection: Record 86230;

    Begin

        If Not GetParnerConnection(CustomerNo, EDIConnection) then
            Exit(2);

        IF (DocType = 'O') AND (NOT EDIConnection.Order) THEN
            EXIT(1); //SKal ikke ha utskrift
        IF (DocType = 'P') AND (NOT EDIConnection.Shipment) THEN
            EXIT(1); //SKal ikke ha utskrift
        IF (DocType = 'I') AND (NOT EDIConnection.Invoice) THEN
            EXIT(1); //SKal ikke ha utskrift

        EXIT(0);
    end;

    procedure CheckEDIChanges(Var EDIOrder: record 86231; SalesHeader: Record "Sales Header"; Var TmpSalesLine: Record "Sales line" temporary; Var ChangeStatus: Code[10]; Var RestOrder: boolean);
    var
        SalesLine: Record "Sales Line";
        EDIOrderLine: Record 86232;
        EDIConnection: Record EDI_Connection;
        ItemCrossRef: Record "Item Cross Reference";
        NextLineNo: Integer;
        NextEDILineNo: Integer;
        Changed: Boolean;

    begin
        ChangeStatus := '29';
        NextLineNo := 0;

        EDIOrderLine.SETRANGE("SO Order No.", SalesHeader."No.");
        If EDIOrderLine.FindLast then
            NextEDILineNo := EDIOrderLine."Line No."
        Else
            NextEDILineNo := 0;

        If NOt GetParnerConnection(SalesHeader."Sell-to Customer No.", EDIConnection) Then
            Error(StrSubstNo(Txt1006, SalesHeader."Sell-to Customer No."));

        //Henter eksisterende ordre
        SalesLine.SETRANGE("Document Type", SalesHeader."Document Type");
        SalesLine.SETRANGE("Document No.", SalesHeader."No.");
        IF SalesLine.FINDFIRST THEN
            REPEAT
                TmpSalesLine.TRANSFERFIELDS(SalesLine);
                EDIOrderLine.SETRANGE("So line No.", TmpSalesLine."Line No.");
                EDIOrderLine.SETRANGE("SO Order No.", TmpSalesLine."Document No.");
                IF EDIOrderLine.FINDFIRST THEN BEGIN
                    TmpSalesLine."Edi Order ID" := EDIOrderLine."Entry No.";
                    TmpSalesLine."EDI Order Line" := EDIOrderLine."Line No.";
                    TmpSalesLine."Cross-Reference No." := EDIOrderLine."PO Item No.";

                    If TmpSalesLine."No." <> EDIOrderLine."SO Item No." then
                        Error(StrSubstNo(Txt1027, TmpSalesLine."No.", EDIOrderLine."PO Item No.", TmpSalesLine."Line No."));
                    If TmpSalesLine."Unit of Measure Code" <> EDIOrderLine."SO Unit of Measure" then
                        Error(StrSubstNo(Txt1027, TmpSalesLine."No.", EDIOrderLine."PO Item No.", TmpSalesLine."Line No."));

                    TmpSalesLine.INSERT;
                End
                Else
                    If Not TmpSalesLine."EDI Item (Charge)" then begin
                        If Not SalesHeader."Edi Adhock Order" then
                            Error(StrSubstNo(Txt1028, TmpSalesLine."No.", TmpSalesLine."Line No."));

                        NextEDILineNo := NextEDILineNo + 1;

                        ItemCrossref.setrange("Item No.", TmpSalesLine."No.");
                        ItemCrossref.SetRange("Cross-Reference Type No.", 'GTINF');
                        ItemCrossRef.setrange("Cross-Reference Type", ItemCrossRef."Cross-Reference Type"::"Bar Code");
                        ItemCrossRef.Setrange("Unit of Measure", TmpSalesLine."Unit of Measure Code");
                        If ItemCrossRef.FindFirst then
                            TmpSalesLine."Cross-Reference No." := ItemCrossRef."Cross-Reference No."
                        Else
                            If Not TmpSalesLine."EDI Item (Charge)" then
                                Error(StrSubstNo(Txt1029, TmpSalesLine."No.", TmpSalesLine."Unit of Measure Code", TmpSalesLine."Line No."));

                        TmpSalesLine."Edi Order ID" := EDIOrderLine."Entry No.";
                        TmpSalesLine."EDI Order Line" := NextEDILineNo;
                        TmpSalesLine.INSERT;
                    End;

                NextLineNo := SalesLine."Line No.";
            UNTIL SalesLine.NEXT = 0;

        //Henter linjer fra EDI-Ordre som ikke ligger i eksisterende ordre
        EDIOrderLine.reset;
        EDIOrderLine.SETRANGE("Entry No.", EDIOrder."Entry No.");
        IF EDIOrderLine.FIND('-') THEN
            REPEAT
                TmpSalesLine.SETRANGE("Document Type", SalesHeader."Document Type");
                TmpSalesLine.SETRANGE("Document No.", EDIOrderLine."SO Order No.");
                TmpSalesLine.SETRANGE("Line No.", EDIOrderLine."SO Line No.");
                IF Not TmpSalesLine.FINDFIRST THEN BEGIN

                    NextLineNo := NextLineNo + 10000;

                    TmpSalesLine.INIT;
                    TmpSalesLine."Document Type" := SalesHeader."Document Type";
                    TmpSalesLine."Document No." := SalesHeader."No.";
                    TmpSalesLine."Line No." := NextLineNo;

                    TmpSalesLine.Type := SalesLine.Type::Item;
                    TmpSalesLine."No." := EDIOrderLine."SO Item No.";
                    TmpSalesLine.Description := Copystr(EDIOrderLine."PO Description", 1, 50);
                    TmpSalesLine."Unit of Measure Code" := EDIOrderLine."SO Unit of Measure";
                    TmpSalesLine."Variant Code" := EDIOrderLine."SO Variant Code";
                    TmpSalesLine."Cross-Reference No." := EDIOrderLine."PO Item No.";
                    TmpSalesLine.Quantity := 0;

                    TmpSalesLine."Edi Order ID" := EDIOrderLine."Entry No.";
                    TmpSalesLine."EDI Order Line" := EDIOrderLine."Line No.";
                    TmpSalesLine."Shipment Date" := SalesHeader."Shipment Date";

                    TmpSalesLine.INSERT;
                END;
            UNTIL EDIOrderLine.NEXT = 0;

        //Sammenlikner salgsordre mot edi-ordre
        TmpSalesLine.RESET;
        TmpSalesLine.SETRANGE("Document Type", SalesHeader."Document Type");
        TmpSalesLine.SETRANGE("Document No.", SalesHeader."No.");
        IF TmpSalesLine.FINDFIRST THEN
            REPEAT
                Changed := FALSE;
                EDIOrderLine.SETRANGE("So line No.", TmpSalesLine."Line No.");
                EDIOrderLine.SETRANGE("SO Order No.", TmpSalesLine."Document No.");
                IF EDIOrderLine.FINDFIRST THEN BEGIN
                    IF TmpSalesLine.Quantity <> EDIOrderLine."PO Quantity" THEN
                        Changed := TRUE;

                    IF TmpSalesLine."No." <> EDIOrderLine."SO Item No." THEN
                        Changed := TRUE;
                END
                ELSE BEGIN
                    Changed := TRUE;
                END;

                IF Changed THEN
                    ChangeStatus := '4';

                TmpSalesLine."EDI Order Line Changed" := ChangeStatus;
                TmpSalesLine.MODIFY;

            UNTIL TmpSalesLine.NEXT = 0;
    End;

    Procedure UpdateAdhockOrder(Var SalesHeader: record "Sales Header");
    Var
        EdiSetup: record EDI_Setup;
        EdiHeader: Record "EDI Header";
        EdiHeader2: Record "EDI Header";
        BYConnection: Record EDI_Connection;
        IVConnection: Record EDI_Connection;
        DPConnection: Record EDI_Connection;
        EDIConnection: record EDI_Connection;
        SalesInvHeader: record "Sales Invoice Header";
        CompanyInfo: Record "Company Information";

    Begin
        If Not SalesHeader."Edi Adhock Order" then
            Exit;

        If SalesHeader."Edi Order-ID" <> 0 then Begin
            EdiHeader.SetRange("Entry No.", SalesHeader."Edi Order-ID");
            If Not EdiHeader.FindFirst Then
                SalesHeader."Edi Order-ID" := 0;
        End;

        If SalesHeader."Edi Order-ID" = 0 then begin
            EdiHeader.reset;
            EdiHeader.LockTable;
            If Not EdiHeader.FindLast then
                EdiHeader."Entry No." := 0;

            EdiHeader.Init;
            EdiHeader."Entry No." := ediheader."Entry No." + 1;
            EdiHeader."SO Order No." := SalesHeader."No.";
            EdiHeader."Order Date" := Workdate;
            EdiHeader."Adhock Order" := True;

            EdiHeader.Insert;

            SalesHeader."Edi Order-ID" := EdiHeader."Entry No.";
        End;

        EdiSetup.get;
        If EdiSetup."UseLastOrderConnection(Adhock)" Then begin
            EdiHeader2.setrange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
            EdiHeader2.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
            If EdiHeader2.FindLast Then begin
                EdiHeader."GLN BY" := EdiHeader2."GLN BY";
                EdiHeader."GLN DP" := EdiHeader2."GLN DP";
                EdiHeader."GLN IV" := EdiHeader2."GLN IV";
                EdiHeader."GLN Owner" := EdiHeader2."GLN Owner";
            end
            else
                error(Txt1030);
        End
        Else begin
            BYConnection.setrange("GLN Type", EdiConnection."GLN Type"::By);
            ByConnection.setrange("No.", SalesHeader."Sell-to Customer No.");
            If Not ByConnection.findfirst then
                Error(Txt1031);

            IVConnection.setrange("GLN Type", EdiConnection."GLN Type"::IV);
            IVConnection.setrange("No.", SalesHeader."Bill-to Customer No.");
            If Not IVConnection.findfirst then
                Error(Txt1032);

            EDIConnection.setrange(Code, BYConnection.code);
            EDIConnection.setrange("GLN Type", EDIConnection."GLN Type"::Agreement);
            If Not EdiConnection.findfirst then
                Error(Txt1033);

            If EDIConnection."Gln Shipment" = EDIConnection."Gln Shipment"::DP Then begin
                DPConnection.SetRange("GLN Type", DPConnection."GLN Type"::DP);
                DPConnection.SetRange("Customer No.", SalesHeader."Sell-to Customer No.");
                DPConnection.setrange("No.", SalesHeader."Ship-to Code");
                If not DPConnection.Findfirst then
                    Error(Txt1035);
            end;


            If (Not EDIConnection."Allow Edi AdHock") and (SalesHeader."Document Type" <> SalesHeader."Document Type"::"Credit Memo") then
                Error(Txt1034);

            IF EDIConnection."Gln Customer" = EDIConnection."Gln Customer"::BY then
                EdiHeader."GLN BY" := BYConnection.GLN
            ELSE
                EdiHeader."GLN DP" := BYConnection.GLN;

            if EDIConnection."Gln Invoice" = EDIConnection."Gln Invoice"::BY then
                EdiHeader."GLN BY" := IVConnection.GLN
            else
                EdiHeader."GLN IV" := IVConnection.GLN;

            If EDIConnection."Gln Shipment" = EDIConnection."Gln Shipment"::DP Then
                EdiHeader."GLN DP" := DPConnection.GLN
            else
                EdiHeader."GLN DP" := BYConnection.GLN;


        End;

        CompanyInfo.Get;

        EdiHeader."GLN SU" := CompanyInfo.GLN;
        EdiHeader."GLN Owner" := EDIConnection."Owner GLN";
        EdiHeader."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        EdiHeader."Sell-to Customer Name" := SalesHeader."Sell-to Customer Name";
        EdiHeader."Bill-to Customer No." := SalesHeader."Bill-to Customer No.";
        EdiHeader."Customer Order No." := SalesHeader."Your Reference";
        EdiHeader."Delivery Date" := SalesHeader."Shipment Date";
        EdiHeader."Credited Invoice No." := SalesHeader."Edi Invoice No.";

        If SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" Then
            EdiHeader."Document Type" := EdiHeader."Document Type"::"Cr.Memo";

        If (EDIConnection."Empty Order Date when Adhock" and EDIHeader."Adhock Order") Then
            EdiHeader."Customer Order No." := '-1';



        EdiHeader.modify;
    End;

    procedure GetParnerConnection(CustNo: code[20]; Var EDIConnection: Record EDI_Connection): Boolean;
    begin
        EDIConnection.Setrange("Customer No.", CustNo);
        If Not EDIConnection.Findfirst then
            Exit(False);

        EDIConnection.SETRANGE("Customer No.");
        EDIConnection.SETRANGE(Code, EDIConnection.code);
        EDIConnection.SETRANGE("GLN Type", EDIConnection."GLN Type"::Agreement);
        If Not EDIConnection.findfirst then
            EXIT(False);

        Exit(true);
    End;

    Procedure CheckChargeItem(CustumerNo: Code[20]; ItemNo: Code[20]): Boolean;
    var
        EDIConnection: Record EDI_Connection;
        EdiSetup: Record EDI_Setup;
    begin
        If GetParnerConnection(CustumerNo, EDIConnection) then begin
            If EDIConnection."Item (Charge)" <> '' then
                Exit(ItemNo = EDIConnection."Item (Charge)")
            else begin
                EdiSetup.get;
                Exit(EdiSetup."Item (Charge)" = ItemNo)
            End;
        End
        Else
            Error(Txt1010);
    End;

    procedure CheckEAN(ItemNo: code[20]; Var UnitOfMeasure: Code[20]; Var EAN: Code[30]; CheckInsert: Boolean): Boolean;
    var
        ItemCrossRef: Record "Item Cross Reference";
    begin
        ItemCrossref.setrange("Item No.", ItemNo);
        ItemCrossref.SetRange("Cross-Reference Type No.", 'GTINF');
        ItemCrossRef.setrange("Cross-Reference Type", ItemCrossRef."Cross-Reference Type"::"Bar Code");
        If Not CheckInsert then
            ItemCrossRef.Setrange("Unit of Measure", UnitOfMeasure);

        If ItemCrossRef.FindFirst then begin
            EAN := ItemCrossRef."Cross-Reference No.";
            UnitOfMeasure := ItemCrossRef."Unit of Measure";
            Exit(True);
        End;
        Exit(false);
    End;

    procedure GetFileNameIn(EdiConnection: Record EDI_Connection; Archive: Boolean): text[250];
    var
        EdiSetup: Record EDI_Setup;
    begin
        EdiSetup.get;

        If Archive then begin
            if EdiConnection."File Path Archive Inn" = '' then
                exit(edisetup."File Path Archive Inn")
            Else
                Exit(EdiConnection."File Path Archive Inn")
        End
        Else begin
            if EdiConnection."File Path in" = '' then
                exit(edisetup."File Path In")
            Else
                Exit(EdiConnection."File Path In")
        End;
    End;

    procedure GetFileNameOut(EdiConnection: Record EDI_Connection; Type: Text[10]; Archive: Boolean; Var FilePath: text[250]; Var Filename: Text[250]);
    var
        EdiSetup: Record EDI_Setup;
    begin
        EdiSetup.get;

        If Archive then begin
            if EdiConnection."File Path Archive Out" <> '' then
                FilePath := DelChr(EdiConnection."File Path Archive Out", '>', '\')
            Else
                FilePath := DelChr(edisetup."File Path Archive Out", '>', '\');
        End
        Else begin
            if EdiConnection."File Path Out" <> '' then
                FilePath := DelChr(EdiConnection."File Path Out", '>', '\')
            Else
                FilePath := DelChr(edisetup."File Path Out", '>', '\')
        End;

        Case type of
            'O':
                If EdiConnection."File Name Orders" <> '' Then
                    Filename := EdiConnection."File Name Orders"
                else
                    Filename := EdiSetup."File Name Orders";
            'SH':
                If EdiConnection."File Name Shipment" <> '' then
                    Filename := EdiConnection."File Name Shipment"
                else
                    Filename := EdiSetup."File Name Shipment";
            'IV':
                If EdiConnection."File Name Invoice" <> '' then
                    Filename := EdiConnection."File Name Invoice"
                else
                    Filename := EdiSetup."File Name Invoice";
            'CR':
                If EdiConnection."File Name Credit Memo" <> '' then
                    Filename := EdiConnection."File Name Credit Memo"
                else
                    FileName := EdiSetup."File Name Credit Memo";
            'INV':
                If EdiConnection."File Name INVRPT" <> '' then
                    Filename := EdiConnection."File Name INVRPT"
                else
                    Filename := EdiSetup."File Name INVRPT";
        End;
    End;

    Procedure UpdateSalesLine()
    var
        EDIHeader: record "EDI Header";
        EDILines: record "EDI Lines";
        SalesHeader: record "Sales Header";
        SalesLine: record "Sales Line";
        SalesInvHeader: record "Sales Invoice Header";
        SalesInvLine: record "Sales Invoice Line";
        EDIMgt: Codeunit EDI_Mgt;

    begin
        SalesLine.Modifyall("Edi Order ID", 0);
        SalesLine.modifyall("EDI Order Line", 0);
        SalesHeader.ModifyAll("Edi Adhock Order", False);
        SalesHeader.ModifyAll("Edi Order-ID", 0);
        SalesHeader.ModifyAll("EDI Order", False);

        If EDIHeader.Findset then
            repeat
                If salesheader.get(SalesHeader."Document Type"::Order, EDIHeader."SO Order No.") then begin
                    SalesHeader."EDI Order" := True;
                    SalesHeader."Edi Order-ID" := EDIHeader."Entry No.";
                    SalesHeader."Edi Adhock Order" := EDIHeader."Adhock Order";
                    SalesHeader.Modify;
                End;
                EDILines.Setrange("Entry No.", EDIHeader."Entry No.");
                EDILines.ModifyAll("SO Order No.", EDIHeader."SO Order No.");
            Until EDIHeader.next = 0;

        EDILines.Reset;
        EDILines.SetFilter("SO Line No.", '>0');
        If EdiLines.Findset Then
            repeat
                If SalesLine.Get(SalesLine."Document Type"::Order, EDILines."SO Order No.", EDILines."SO Line No.") Then begin
                    SalesLine."Edi Order ID" := EDILines."Entry No.";
                    Salesline."EDI Order Line" := EDILines."Line No.";
                    SalesLine.Modify;
                end;
            Until EDILines.Next = 0;

        Salesheader.setrange("EDI Order", True);
        If SalesHeader.Findset Then
            repeat
                SalesLine.setrange("Document Type", SalesHeader."Document Type");
                SalesLine.SetRange("Document No.", SalesHeader."No.");
                SalesLine.Setrange("EDI Order Line", 0);
                If SalesLine.Findset then
                    repeat
                        If EDIMgt.CheckChargeitem(SalesLine."Sell-to Customer No.", salesline."No.") then begin
                            SalesLine."EDI Item (Charge)" := True;
                            SalesLine.Modify;
                        End;
                    Until SalesLine.Next = 0;
            until SalesHeader.next = 0;

        SalesInvheader.setrange("EDI Order", True);
        If SalesHeader.Findset Then
            repeat
                SalesInvLine.SetRange("Document No.", SalesHeader."No.");
                SalesInvLine.Setrange("EDI Order Line", 0);
                If SalesInvLine.Findset then
                    repeat
                        If EDIMgt.CheckChargeitem(SalesInvLine."Sell-to Customer No.", SalesInvline."No.") then begin
                            SalesInvLine."EDI Item (Charge)" := True;
                            SalesInvLine.Modify;
                        End;
                    Until SalesInvLine.Next = 0;
            until SalesInvHeader.next = 0;
    end;

    Procedure FixSalesLine()
    var
        EDIHeader: Record "EDI Header";
        EDIHeader2: Record "EDI Header";
        EDILine: Record "EDI Lines";
        EDILine2: Record "EDI Lines";
        SalesLine: record "Sales Line";
        SalesHeader: record "Sales Header";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        Released: Boolean;
        UpdateOrder: Boolean;

    Begin
        EDIHeader.Setrange("SO Order No.", Txt1011);
        If EDIHeader.Findset then
            repeat
                EDIHeader2.Setrange("Customer Order No.", EDIHeader."Customer Order No.");
                EDIHeader2.Setfilter("SO Order No.", '<>%1', Txt1011);
                If EDIHeader2.FindLast then begin

                    UpdateOrder := false;
                    Released := False;
                    If SalesHeader.Get(SalesHeader."Document Type"::Order, EDIHeader2."SO Order No.") then Begin
                        If SalesHeader.Status <> SalesHeader.Status::Open then begin
                            ReleaseSalesDoc.PerformManualReopen(SalesHeader);
                            released := true;
                        End;
                        UpdateOrder := True;
                    end;

                    EDILine.SetRange("Entry No.", EDIHeader."Entry No.");
                    If EDILine.findset then
                        repeat
                            EDILine2.SetRange("Entry No.", EDIHeader2."Entry No.");
                            EDILine2.setrange("PO Line No.", EDILine."PO Line No.");
                            If EdiLine2.FindFirst Then begin
                                EDILine2."PO Line Discount" := EDILine."PO Line Discount";
                                EdiLine2.Modify;

                                If UpdateOrder Then
                                    If SalesLine.Get(SalesLine."Document Type"::Order, EDILine2."SO Order No.", EDILine2."SO Line No.") then begin
                                        salesline.Validate("Line Discount %", EDILine2."PO Line Discount");
                                        SalesLine.modify;
                                    End;
                            end;
                        Until EDILine.next = 0;

                    If Released then
                        ReleaseSalesDoc.PerformManualRelease(SalesHeader);
                End;
            Until EDIHeader.Next = 0;
    End;

    Procedure FixItemChargeInvLine();
    Var
        SalesLine: record "Sales Line";
        SalesInvLine: record "Sales Invoice Line";
    Begin
        SalesInvLine.Setrange(type, SalesInvLine.Type::item);
        SalesinvLine.Setfilter("No.", '70000|70001');
        If SalesInvLine.findSet then
            repeat
                If (SalesInvLine."No." = '70000') or (SalesInvLine."No." = '70001') then begin
                    SalesInvLine."EDI Item (Charge)" := True;
                    SalesInvLine.Modify;
                end;
            Until SalesInvLine.Next = 0;
    end;

    Procedure UpdateEDICustAddress();
    Var
        Cust: Record Customer;
    begin
        cust.SetFilter("Edi Customer Name", '<>%1', '');
        If cust.FindSet then
            repeat
                Cust."Edi Address" := Cust."Address 2";
                Cust."Edi City" := Cust.City;
                cust."Edi Post Code" := Cust."Post Code";
                Cust.Modify;
            Until Cust.Next = 0;
    End;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckEDIOrder(var EDI_Order: Record "EDI Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertSalesHeader(var salesheader: Record "Sales Header"; var EDI_Order: Record "EDI Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertSalesLine(var salesheader: Record "Sales Header"; var salesline: record "Sales Line"; var EDI_Order: Record "EDI Header"; var EDI_OrderLines: Record "EDI Lines")
    begin
    end;

    var
        Txt1001: Label 'Salgsordre er ikke en EDI-Ordre';
        Txt1002: Label 'Edi ordrebekreftelse er sendt. Skal denne sendes på ny?';
        Txt1003: Label 'Edi faktura er sendt. Skal denne sendes på ny?';
        Txt1004: label 'Skal EDI Ordrebrekrefteles sendes?';
        Txt1005: label 'Skal EDI faktura sendes?';
        Txt1006: label 'Finner ikke edikobling for kunde %1';
        Txt1007: label 'Edifact format mangler i oppsett for kunde %1';
        Txt1008: Label 'Kunde skal ikke ha Edi Ordre';
        Txt1009: Label 'Kunde skal ikke ha Edi faktura';
        Txt1010: Label 'Gln for kunde/partner mangler for kundenr.';
        Txt1011: label 'DELETED';
        Txt1012: Label 'Order exitst';
        Txt1013: Label 'Partner (%1) finnes ikke.';
        Txt1014: label 'By (%1) finnes ikke ';
        Txt1015: label ',Item Missing';
        Txt1016: label ',Item Blocked';
        Txt1017: label ',Sales Unit of Measure Error';
        Txt1018: label ',Unit of Measure Missing';
        Txt1019: label ',Customer no.';
        Txt1020: label ',Ship-to Code';
        Txt1021: Label ',BY';
        Txt1022: Label ',DP';
        Txt1023: label ',IV';
        Txt1024: label 'Missing ';
        Txt1025: Label 'Customer Blocked. ';
        Txt1026: Label 'Line Error';
        Txt1027: Label 'Varenr %1 stemmer ikke overens med varenummer %2 på Ediordrde, linje %3';
        Txt1028: Label 'Det kan kun legges til frakt på Ediordre. Varenr %1, linje %2';
        Txt1029: label 'Ean finnes ikke for varenr %1, enhet %2. Linjenr %2';
        Txt1030: label 'No EDi Order for this customer exists. Clear setup field "Use Last EDI Order (adhock) to create EDI Order';
        Txt1031: label 'Edi Connection for By not exist';
        Txt1032: label 'Edi Connection for IV not exist';
        Txt1033: Label 'Edi Connection for Partner not exist';
        Txt1034: Label 'Det er ikke tillatt å opprette ny Edi ordre for denne kunden.';
        Txt1035: Label 'Edi Connection for DP not exist.';

}