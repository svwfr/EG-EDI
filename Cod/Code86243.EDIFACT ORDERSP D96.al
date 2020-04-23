codeunit 86243 "Edifact ORDERSP D96"
{
    TableNo = "Sales Header";

    trigger OnRun();
    begin
        SalesHeader.copy(Rec);
        
        CreateOrderconfirmation();
    End;


    procedure CreateOrderconfirmation();
    var
        ChangeStatus:code[10];
        RestOrder:Boolean;
        DocumentLogg:Record EDI_Document_Logg;

    begin
        EDIMgt.FindExportEDIConnection(SalesHeader."Sell-to Customer No.", EDIConnection,True,'O');
        EDIHeader.Get(SalesHeader."Edi Order-ID");
        Customer.get(SalesHeader."Sell-to Customer No.");
        CompanyInformation.GET();

        If EDIHeader."GLN SU" = '' then
            EDIHeader."GLN SU" := CompanyInformation.GLN;

        EDIHeader.Testfield("GLN SU");
        
        CreateFile(); 

        RefNo := '1';
        Fnutt := 39;
        TmpSalesLine.DELETEALL;
        EDIMgt.CheckEDIChanges(EDIHeader,SalesHeader,TmpSalesLine,ChangeStatus,Restorder);

        CreateHeader(ChangeStatus);
        CreateLine();

        WriteToStream('UNS+S');
        WriteToStream('CNT+2:' + FORMAT(LineCint,0,'<Integer>'));
        WriteToStream('UNT+' + FORMAT(RecCint-1,0,'<Integer>') + '+' + format(RefNo));
        WriteToStream('UNZ+'+ format(RefNo) + '+' + EDIConnection."Order Counter");


        ExportFile.CLOSE();
        SalesHeader.Get(salesheader."Document Type"::Order,salesHeader."No.");
        SalesHeader."EDI Created" := Today;
        SalesHeader.Modify;

        EDIHeader."Order send" := Today;
        EDIHeader.modify;
        
        DocumentLogg.InsertEntry(EDIHeader,EDIDocumentType,EDIConnection."Order Counter",DocumentLogg."Document Type"::Orderconfirmation,SalesHeader."No.",ExportFileName);
        Commit;
    end;


    procedure CreateHeader(ChangeStatus:text[4])
    Var
        SegmentString: text;
    begin
        //UNA
        WriteToStream('UNA:+.? ');

        //UNB
        IF TestFlagg = TRUE THEN
            SegmentString := '++++0++1';

        WriteToStream('UNB+UNOC:3+' + EDIHeader."GLN SU" + ':14+' + EDIHeader."GLN Owner" + 
            ':14+' + ShortDate(TODAY)+':' + FormatTime(TIME)+ '+' + EDIConnection."Order Counter" + SegmentString);

        //UNH
        EDIDocumentType := 'ORDRSP:D:96A:UN:SPORTA';
        WriteToStream('UNH+' + Format(RefNo) + '+' + EDIDocumentType);  

        //BGM   
        WriteToStream('BGM+231+' + SalesHeader."No." + '+' + ChangeStatus);

        //DTM
        SetDTM(137);

        //RFF
        WriteToStream('RFF+ON:' + EDIHeader."Customer Order No.");

        //DTM Ved adhock skal ikke ordredato fylles ut
        If Not (EDIConnection."Empty Order Date when Adhock" and EDIHeader."Adhock Order") Then
            SetDTM(171);

        //NAD
        SETNAD('BY');
        SetNAD('DP');
        setNad('SU');

        //RFF
        WriteToStream('RFF+VA:' + Delchr(CompanyInformation."VAT Registration No.",'=',Delchr(CompanyInformation."VAT Registration No.",'=','0123456789')));

        //CUX
        IF SalesHeader."Currency Code" = '' THEN
            SegmentString := 'NOK'
        ELSE
            SegmentString := SalesHeader."Currency Code";

        WriteToStream('CUX+2:' + SegmentString + ':9');

        //TOD
        IF SalesHeader."Shipment Method Code" <> '' then
            WriteToStream('TOD+6++'+ SalesHeader."Shipment Method Code"); 
    End;

    Procedure CreateLine()
    var
        ActionRequest:text[4];
        SegmentString: text;
    begin
        TmpSalesLine.Setrange(type,TmpSalesLine.type::Item);
        TmpSalesLine.Setrange("EDI Item (Charge)",False);
        
        If TmpSalesLine.FindSet then
        repeat
            If Not EDIOrderLine.Get(SalesHeader."Edi Order-ID",TmpSalesLine."EDI Order Line") then 
                Clear(EDIOrderLine);

            GetLineInfo(ActionRequest);
           
            LineCint := LineCint + 1;
    
            //LIN
            SegmentString := 'LIN+'+FORMAT(LineCint,0,'<integer>');
            If TmpSalesLine."Cross-Reference No." <> '' then
                SegmentString := SegmentString + '+' +FORMAT(ActionRequest)+ '+' + TmpSalesLine."Cross-Reference No." + ':EN';

            WriteToStream(SegmentString);   

            //PIA
            WriteToStream('PIA+1+' + TmpSalesLine."No." + ':SA');
            //IMD
            WriteToStream('IMD+F++:::' + Delchr(Delchr(TmpSalesLine.Description,'=',Fnutt),'=',':+?'));
            //QTY
            WriteToStream('QTY+' + '21' + ':' + FormatNumber(EDIOrderLine."PO Quantity") + ':' + TmpSalesLine."Unit of Measure Code");
            WriteToStream('QTY+' + '131' + ':' + FormatNumber(TmpSalesLine.Quantity) + ':' + TmpSalesLine."Unit of Measure Code");

            SetDTM(69);
  
            //PRI
            WriteToStream('PRI+' + 'AAB' + ':' + FormatNumber(TmpSalesLine."Unit Price"));
            //RFF
            WriteToStream('RFF+ACD::' + Format(EDIOrderLine."PO Line No.",0,'<Integer>'));
  
            WriteToStream('ALC+A++++DI');

            WriteToStream('PCD+1:' + FormatNumber(TmpSalesLine."Line Discount %"));
 
        Until TmpSalesLine.Next = 0;
    End;


    procedure SetDTM(Qualifier : Integer);
    Var 
        DTMString:Text;
    Begin
        DTMString := 'DTM';
        CASE Qualifier OF
        4 : DTMString := DTMString + '+' + '4' + ':' + ConvertOutDate(SalesHeader."Order Date");                 // Order date
        8 : DTMString := DTMString + '+' + '8' + ':' + ConvertOutDate(SalesHeader."Order Date");                 // Order received
        9 : DTMString := DTMString + '+' + '9' + ':' + ConvertOutDate(TODAY);                                    // Order received
        10 : BEGIN                                                                                                // Shipment requested
                SalesHeader.TESTFIELD("Requested Delivery Date");
                IF SalesHeader."Requested Delivery Date" = 0D THEN
                EXIT;
                DTMString := DTMString + '+' + '10';
                DTMString := DTMString + ':' + ConvertOutDate(SalesHeader."Requested Delivery Date");
            END;
        11 : BEGIN                                                                                                // Shipment promised
            SalesHeader.TESTFIELD("Shipment Date");
                IF SalesHeader."Shipment Date" = 0D THEN EXIT;
                DTMString := DTMString + '+' + '11';
                DTMString := DTMString + ':' + ConvertOutDate(SalesHeader."Shipment Date");
            END;
        13 : BEGIN                                                                                                // Payment due date
                SalesHeader.TESTFIELD("Due Date"); //Must have value
                IF SalesHeader."Due Date" = 0D THEN EXIT;
                DTMString := DTMString + '+' + '13';
                DTMString := DTMString + ':' + ConvertOutDate(SalesHeader."Due Date");
            END;
        17 : BEGIN                                                                                                // Shipment date
                SalesHeader.TESTFIELD("Shipment Date");
                IF SalesHeader."Shipment Date" = 0D THEN
                EXIT;
                DTMString := DTMString + '+' + '17';
                DTMString := DTMString + ':' + ConvertOutDate(SalesHeader."Shipment Date");
            END;
        137: BEGIN
                DTMString := DTMString + '+' + '137';
                DTMString := DTMString + ':' + ConvertOutDate(TODAY);
            END;
        171: BEGIN
                DTMString := DTMString + '+' + '171';
                DTMString := DTMString + ':' + ConvertOutDate(EDIHeader."Order Date");

            END;
        2 : BEGIN
                tmpSalesLine.TESTFIELD("Requested Delivery Date");
                DTMString := DTMString + '+' + '2' + ':' + ConvertOutDate(tmpSalesLine."Requested Delivery Date"); // Requested Delivery Date
            END;
        69 : BEGIN
                SalesHeader.TESTFIELD("Shipment Date");
                DTMString := DTMString + '+' + '69' + ':' + ConvertOutDate(tmpSalesLine."Shipment Date");
            END;
        76 : BEGIN
                SalesHeader.TESTFIELD("Shipment Date");
                DTMString := DTMString + '+' + '76' + ':' + ConvertOutDate(tmpSalesLine."Planned Delivery Date");
            END;
        ELSE
            EXIT;
        END;

        DTMString := DTMString + ':' + '102';
        WriteToStream(DTMString);
    End;

    Procedure SetNAD(PartyQualifier: Text[3]);
    var
        ShiptoAddresses:Record "Ship-to Address";
        NADString:text;
    begin
        NADString := 'NAD';
        
        CASE PartyQualifier OF
            'BY' : BEGIN                                                                                              // Buyer
                NADString := NADString + '+' + 'BY';
                NADString := NADString + '+' + EDIHeader."GLN BY" + '::9';
                WriteToStream(NADString);         
            END;
            'DP' : BEGIN   
                If EDIHeader."GLN DP" <> '' Then Begin
                    NADString := NADString + '+' + 'DP';
                    NADString := NADString + '+' + EDIHeader."GLN DP" + '::9';                  

                    //NADString := NADString + '++' + SalesHeader."Ship-to Name";
                    //NADString := NADString + '+' + SalesHeader."Ship-to Address";
                    //NADString := NADString + '+' + SalesHeader."Ship-to City";
                    //NADString := NADString + '++' + SalesHeader."Ship-to Post Code";
                    //IF SalesHeader."Ship-to Country/Region Code" <> '' THEN
                    //    NADString := NADString + '+' + SalesHeader."Ship-to Country/Region Code";

                    WriteToStream(NADString); 
                End;        
            END;
            'SU' : BEGIN                                                                                              // Supplier
                NADString := NADString + '+' + 'SU';
                NADString := NADString + '+' + EDIHeader."GLN SU" + '::9';
                NADString := NADString;
                WriteToStream(NADString);        
            End
            ELSE
                EXIT;
        End;
    End;        

    Procedure GetLineInfo(Var ActionRequest:text[3]);
    Var 
        ItemCrossRef:Record "Item Cross Reference";
    begin
        ActionRequest := '5';

        If SalesHeader."Edi Adhock Order"  then begin
            EDIOrderLine."PO Quantity" := TmpSalesLine.Quantity;
            ActionRequest := '3';
        end;

        If TmpSalesLine.Quantity <> EDIOrderLine."PO Quantity" then 
            ActionRequest := '3';
    end;

    procedure CreateFile();
    var
        FileName: Text;
        FilePath: Text;
    begin
        EdiMgt.GetFileNameOut(EDIConnection,'O',False,FilePath,FileName);
        FileName := FilePath + '\' + StrSubstNo(FileName,SalesHeader."No.",EDIConnection."Owner GLN",CurrentDateTime);
        
        exportFile.CREATE(Filename);
        exportFile.CREATEOUTSTREAM(exportStream);

        ExportFileName := filemgt.GetFileName(filename);
    end;

    procedure WriteToStream(vString : Text[1024]);
    begin
        vString := delchr(vString,'=',Fnutt)+ FORMAT(fnutt);

        exportStream.WRITETEXT(vString);
        //IF WriteCRToFile THEN
        //    exportStream.WRITETEXT();  

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
            TextAmount:= FORMAT(Dec); //,0,'<Sign><Integer><Decimals>');
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
        EDIHeader: record "EDI Header";
        EDIOrderLine: record "EDI Lines";
        SalesHeader: record "Sales Header";
        TmpSalesLine: record "Sales Line" temporary;
        EDIConnection: Record EDI_Connection;
        Customer: record Customer;
        EdiSetup: record EDI_Setup;
        CompanyInformation:record "Company Information";
        EDIMgt: codeunit "EDI_Mgt";
        FileMgt: Codeunit "File Management";
        ExportFile: file;
        ExportStream: OutStream;
        ExportFileName:text[250];
        WriteCrToFile: Boolean;
        RecCint: Integer;
        LineCint: Integer;
        RefNo: Text[20];
        Fnutt: char;
        TestFlagg:Boolean;
        EDIDocumentType:code[30];

}