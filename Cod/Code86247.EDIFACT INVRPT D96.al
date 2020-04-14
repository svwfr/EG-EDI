codeunit 86247 "Edifact INVRPT D96"
{
    TableNo = EDI_Connection;

    trigger OnRun();
    begin
        EDIConnection := rec;
        CreateINVRPTP();
    End;

    procedure CreateINVRPTP()
    var
        Item:record item;
        ItemL:Record "Item Ledger Entry";
        ItemCrossref:Record "Item Cross Reference";
        PurchOrderLine:Record "Purchase Line";
        WarehouseActivityLine:record "Warehouse Activity Line";
        SegmetString:text;
        SeasonCode:text[30];
        CatalogNo:text[30];
        Startingdate:date;
        Endingdate:Date;
        TermsOfDelivery:text[10];
        NotificationCode:text[1];
        LineNo:integer;
        SendingNo:Code[20];
        QtyOnPurchOrder:Decimal;

    begin

        If EDIConnection."InvRPT Counter" = '' then
            EDIConnection."InvRPT Counter" := '000001'
        Else
            EDIConnection."InvRPT Counter" := Incstr(EDIConnection."InvRPT Counter");
        EDIConnection.Modify;

        Customer.get(EDIConnection.code);
        CompanyInformation.GET();
        CreateFile(); 

        Fnutt := 39;

        WriteToStream('UNA:+.? ');
        WriteToStream('UNB+UNOC:3+'+ CompanyInformation.gln + ':14+' + EDIConnection."Owner GLN" + ':14' +
           '+' + ShortDate(TODAY)+':' + FormatTime(TIME) +
            '+' + EDIConnection."InvRPT Counter");

        WriteToStream('UNH+1+INVRPT:D:96A');
        WriteToStream('BGM+35+' + EDIConnection."InvRPT Counter" + '+9');
        WriteToStream('DTM+137:'+ConvertOutDate(TODAY) + ':102');
        WriteToStream('NAD+BY+'+EDIConnection.GLN+'::9');
        WriteToStream('NAD+SU+' + CompanyInformation.GLN + '::9');
        WriteToStream('RFF+VA:NO' + delchr(CompanyInformation."VAT Registration No.",'=',delchr(CompanyInformation."VAT Registration No.",'=','0123456789'))+'MVA');

        If Item.Findset Then 
        Repeat
            ItemCrossref.setrange("Item No.",Item."No.");
            ItemCrossref.SetRange("Cross-Reference Type No.",'GTINF');
            If ItemCrossref.FindSet then
            repeat
                If strlen(DelChr(ItemCrossref."Cross-Reference No.",'<>',' ')) = 13 then Begin

                    Item.setfilter("Location Filter",EDIConnection."INVRPT Location Filter");
                    Item.CalcFields(Inventory);
        
                    WarehouseActivityLine.SETRANGE("Activity Type",WarehouseActivityLine."Activity Type"::"Invt. Pick");
                    WarehouseActivityLine.SETRANGE("Item No.", ItemCrossref."Item No.");
                    WarehouseActivityLine.SetFilter("Location Code",EDIConnection."INVRPT Location Filter");
                    IF WarehouseActivityLine.FINDSET THEN REPEAT
                        Item.Inventory -= WarehouseActivityLine."Qty. Outstanding (Base)";
                    UNTIL WarehouseActivityLine.NEXT = 0;

                    If item.Inventory < 0 Then
                        Item.Inventory := 0;
                        
                    PurchOrderLine.setrange("Document Type",PurchOrderLine."Document Type"::Order);
                    PurchOrderLine.SetRange(Type,PurchOrderLine.Type::Item);
                    PurchOrderLine.SetRange("No.",ItemCrossref."Item No.");
                    PurchOrderLine.SetFilter("Location Code",EDIConnection."INVRPT Location Filter");
                    PurchOrderLine.CalcSums("Outstanding Qty. (Base)");

                    QtyOnPurchOrder := PurchOrderLine."Outstanding Qty. (Base)";
                    If QtyOnPurchOrder < 0 then
                        QtyOnPurchOrder := 0;
                        
                    If Not PurchOrderLine.FindFirst then
                        Clear(PurchOrderLine."Expected Receipt Date");
                    

                    LineNo := LineNo + 1;
                    WriteToStream('LIN+' + format(LineNo) + '+' + '1' + '+' + ItemCrossref."Cross-Reference No." + ':EN');
                    WriteToStream('QTY+145:' + Format(Round(Item.Inventory,1),0,'<Integer>')+':PCE');

                    If QtyOnPurchOrder > 0 then begin
                        WriteToStream('QTY+198:' + Format(Round(QtyOnPurchOrder,1),0,'<Integer>')+':PCE');

                        If PurchOrderLine."Expected Receipt Date" <> EmptyDate then
                            WriteToStream('DTM+44:'+ConvertOutDate(PurchOrderLine."Expected Receipt Date")+':102');
                    End;
                End;
            Until ItemCrossref.next = 0;
        Until Item.next = 0;

        WriteToStream('UNT+' + format(RecCint-1) + '+' + '1');
        WriteToStream('UNZ+1+' + EDIConnection."InvRPT Counter");
        ExportFile.CLOSE();

        Commit;
    end;

    procedure CreateFile();
    var
        FileName: Text;
        FilePath: Text;
    begin
       
        EdiMgt.GetFileNameOut(EDIConnection,'INV',False,FilePath,FileName);
        FileName := FilePath + '\' + StrSubstNo(FileName,EDIConnection."Owner GLN",CurrentDateTime);
    
        exportFile.CREATE(FileName);
        exportFile.CREATEOUTSTREAM(exportStream);
    end;

    procedure WriteToStream(vString : Text[1024]);
    begin
        vString := vString + fnutt;

        exportStream.WRITETEXT(vString);
        IF WriteCRToFile THEN
            exportStream.WRITETEXT();  

        RecCint := RecCint + 1;
    end;

    Procedure FormatNumber(DEC:Decimal): text[30];
    var
        TextAmount:text[30];
        Len:Integer;
        Pos:Integer;
    begin
        IF Dec = 0 THEN
            TextAmount:= '0,00'
        ELSE BEGIN
            TextAmount:= FORMAT(Dec);
            Len:=STRLEN(TextAmount);
            Pos:= STRPOS(TextAmount,',');
            IF Pos = 0 THEN
               TextAmount:= TextAmount + ',00'
            ELSE BEGIN
                IF Len = Pos THEN TextAmount:= TextAmount + '00';
                IF Len - Pos = 1 THEN TextAmount:= TextAmount + '0';
                IF Len - Pos >= 2 THEN TextAmount:= COPYSTR(TextAmount,1,Pos+2);
            END;
        END;

        IF ABS(Dec) >= 1000 THEN BEGIN
            Len:= STRLEN(TextAmount);
            TextAmount:= COPYSTR(TextAmount,1,Len-7) + COPYSTR(TextAmount,Len-5,6);
            IF ABS(Dec) >= 1000000 THEN BEGIN
                Len:= STRLEN(TextAmount);
                TextAmount:= COPYSTR(TextAmount,1,Len-10) + COPYSTR(TextAmount,Len-8,9);
            END;
        END;
        TextAmount:= CONVERTSTR(TextAmount,',','.');
        EXIT(TextAmount);
    end;

    Procedure ShortDate(Impdate : Date) : Text[30];
    var
        RetDat: text[20];
        Year : Text[4];
        Mon : Text[2];
        Day : text[2];
    begin
        IF Impdate <> 0D THEN BEGIN
            RetDat:= FORMAT(Impdate);
            Year:= COPYSTR(RetDat,7,2);
            mon:= COPYSTR(RetDat,4,2);
            day:= COPYSTR(RetDat,1,2);
            RetDat:= Year+mon+day;
            EXIT(RetDat);
        END;    
    End;

    Procedure FormatTime(Time : Time) : Text[30];
    Var
        RetTime: text[20];
        Hour: text[2];
        Minute: Text[2];
        Sec: text[2];

    Begin
        IF Time <> 0T THEN BEGIN
            RetTime:= FORMAT(Time);
            Hour:= COPYSTR(RetTime,1,2);
            Minute:= COPYSTR(RetTime,4,2);
            Sec:= COPYSTR(RetTime,7,2);
            //   RetTime:= Hour + Minu + Sec;
            RetTime:= Hour + Minute;
            IF (RetTime[1] < '1') OR (RetTime[1] > '2') THEN RetTime[1]:= '0';
            EXIT(RetTime);
        END;
    End;

    procedure ConvertOutDate(InDate : Date) OutDate : Text[8];
    var
        Month: text[2];
        Day:text[2];

    begin
        IF InDate = 0D THEN ERROR('ingen dato');
        OutDate := FORMAT(DATE2DMY(InDate, 3));
        Month := FORMAT(DATE2DMY(InDate, 2));
        IF STRLEN(Month) = 1 THEN
            Month := '0' + Month;
        OutDate := OutDate + Month;
        Day := FORMAT(DATE2DMY(InDate, 1));
        IF STRLEN(Day) = 1 THEN
            Day := '0' + Day;
        OutDate := OutDate + Day;
    End;

    var
        EDIConnection: Record EDI_Connection;
        Customer: record Customer;
        CompanyInformation:record "Company Information";
        EDIMgt: codeunit "EDI_Mgt";
        ExportFile: file;
        ExportStream: OutStream;
        WriteCrToFile: Boolean;
        Fnutt: char;
        RecCint:integer;
        EmptyDate:Date;
}