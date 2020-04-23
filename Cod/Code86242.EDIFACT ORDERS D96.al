codeunit 86242 "Edifact ORDERS D96"
{
    TableNo = 86230;

    trigger OnRun();
    begin
        ImportOrders(REC);
    End;
    
    Procedure ImportOrders(Var EDI_Connection: Record EDI_Connection );
    Var
        FileList: record "Name/Value Buffer";
        EdiMgt:Codeunit EDI_Mgt;

    Begin
        FileMgt.GetServerDirectoryFilesList(Filelist, edimgt.GetFileNameIn(EDI_Connection,false));
        If Filelist.FindSet Then 
            repeat
                If ImportOneFile(FileList.Name, EDI_Connection) then begin
                    MoveFile(FileList.Name, EDI_Connection);
                    Commit;
                End;
            Until FileList.Next = 0;
    End;

    Procedure ImportOneFile(FileName: Text[250];Var EDI_Connection : Record EDI_Connection):Boolean;
    Var
        EdiHeader2: Record "EDI Header";
        LineNo: Integer;
        EntryNo: Integer;
        CurrentRec: Text;
        LineCnt: integer;
        LineCntMax: integer;
        i: integer;

    Begin
        //w.UPDATE(2,i);
        impFile.TEXTMODE(TRUE);
        impFile.WRITEMODE(TRUE);
        IF NOT impFile.OPEN(FileName) THEN 
            Exit(False);

        LineCnt := 1;   
        Fnutt := 39;
        ImportFilename := filemgt.GetFileName(filename);

        impFile.CREATEINSTREAM(TxtInStream);
        While NOT TxtInStream.EOS DO
        Begin
          TxtInStream.READTEXT(impData[LineCnt],1024);
          LineCnt := LineCnt + 1; 
        End;
        impFile.CLOSE;

        If (StrPos(impData[1],'CONTRL') > 0) and (StrPos(impData[1],'EAN002') > 0) and (StrPos(impData[1],'INVOIC:D:96A:UN:SPORTA') > 0)then
           ImportInvoiceResponce(LineCnt)

        Else If StrPos(impData[1],'ORDERS:D:96A') = 0 Then
           Exit(True);

        i := 1;
        LineCntMax := LineCnt;
        For LineCnt := 1 To LineCntMax Do Begin
            Repeat
                i := STRPOS(impData[LineCnt],FORMAT(fnutt));
                IF i > 0 THEN BEGIN
                    CurrentRec := COPYSTR(impData[LineCnt],1,i-1);
                    IF LineCnt > 1 THEN BEGIN
                        IF STRLEN(impData[LineCnt-1]) <> 0 then begin
                            CurrentRec := impData[LineCnt-1] + CurrentRec;
                            impData[LineCnt-1] := '';
                        End;
                    END;
            
                    CASE COPYSTR(CurrentRec,1,3) OF
                        'UNA' : GetUNA;
                        'UNB' : GetUNB(CurrentRec);
                        'UNH' : GetMessageHeader(CurrentRec);
                        'BGM' : GetBeginningOfMessage(CurrentRec);
                        'DTM' : GetDateTimePeriod(CurrentRec);
                        'FTX' : GetTextSubjectQualifier(CurrentRec);
                        'CUX' : GetCurrency(CurrentRec);
                        'TOD' : GetTermOfDelivery(CurrentRec);
                        'NAD' : GetNameAndAddress(CurrentRec);
                        'CTA' : GetContact(CurrentRec); 
                        'TDT' : GetTransportDetails(CurrentRec);
                        'LIN' : GetLineItem(CurrentRec);
                        'PIA' : GetAdditionalProductId(CurrentRec);
                        'IMD' : GetItemDescription(CurrentRec);
                        'QTY' : GetQuantity(CurrentRec);
                        'PRI' : GetPriceDetails(CurrentRec);
                        'PCD' : GetPCD(CurrentRec);
                        'RFF' : GetReference(CurrentRec);
                    END;
                END;
                impData[LineCnt] := COPYSTR(impData[LineCnt],i+1);
            Until i = 0;
        End; 
        exit(true);
    End;

    Procedure GetUNA();
    begin
    end;

    procedure GetUNB(InputString : Text[250]);
    begin
        CLEAR(plusString);
        CLEAR(colonString);
        SplitStringPlus(InputString);
        SplitStringColon(plusString[2]);

        SenderGLN := COPYSTR(plusString[3],1,STRPOS(plusString[3],':')-1);
    End;

    Procedure GetMessageHeader(InputString : Text[250]);
    Begin
        Clear(EDIHeader);
        EDIHeaderInsert := False;    

        // Deparse input
        CLEAR(plusString);
        CLEAR(colonString);
        SplitStringPlus(InputString);
        SplitStringColon(plusString[3]);

        EDIHeader."Message Ref." := plusString[2];
        EDIHeader."EDI message Type" := colonString[1] + ':' + colonString[2] + ':' + colonString[3];
        EDIHeader."EDI File Name" := ImportFilename;
    End;

    procedure GetBeginningOfMessage(InputString : Text[250]);
    begin
        CLEAR(plusString);
        SplitStringPlus(InputString);

        EDIHeader."Customer Order No." := plusString[3];

        IF COPYSTR(plusString[2],1,3) in ['220','224'] then
            EDIHeader."Order Type" := COPYSTR(plusString[2],1,3);
        
    End;

    Procedure GetDateTimePeriod(InputString : Text[250]);
    var
        Orderdate: date;

    begin
        CLEAR(plusString);
        CLEAR(colonString);
        SplitStringPlus(InputString);
        SplitStringColon(plusString[2]);

        orderdate := ConvertInDate(colonString[2]);
        CASE colonString[1] OF
            '2'     : EDIHeader."Delivery Date" := orderdate;
            '137'   : EDIHeader."Order Date" := orderdate;
         END;
    End;

    procedure GetTextSubjectQualifier(InputString:text[1024]);
    begin
        CLEAR(plusString);
        CLEAR(colonString);
        SplitStringPlus(InputString);

        IF plusString[2] = 'ORI' then
          EDIHeader."Order Instruction" := plusString[5];
          
    End;

    Procedure GetNameAndAddress(InputString : Text[250])
    begin
        CLEAR(plusString);
        CLEAR(colonString);
        SplitStringPlus(InputString);
        SplitStringColon(plusString[3]);

        IF plusString[2] = 'BY' THEN BEGIN
            IF colonString[3] = '9' THEN 
                EDIHeader."GLN BY" := colonString[1];
        END 
        ELSE IF plusString[2] = 'SU' THEN BEGIN
            IF colonString[3] = '9' THEN 
                EDIHeader."GLN SU" := colonString[1];
        End
        else IF plusString[2] = 'IV' THEN BEGIN  //Fakturakonto
            IF colonString[3] = '9' THEN 
                EDIHeader."GLN IV" := colonString[1];
        End 
        ELSE IF plusString[2] = 'DP' THEN BEGIN
            IF colonString[3] = '9' THEN 
                EDIHeader."GLN DP" := colonString[1];
        END;
    End;

    procedure GetContact(InputString : Text[250]);
    begin

    end;

    Procedure GetCurrency(InputString : Text[250]);
    begin
        CLEAR(plusString);
        CLEAR(colonString);
        SplitStringPlus(InputString);
        SplitStringColon(plusString[2]);

        IF colonString[2] <> 'NOK' THEN
           EDIHeader."Currency Code" := colonString[2];
    end;

    Procedure GetTermOfDelivery(InputString : Text[250]);
    begin
        CLEAR(plusString);
        CLEAR(colonString);
        SplitStringPlus(InputString);
        SplitStringColon(plusString[2]);

        IF plusString[2] = '6' THEN 
            IF plusString[4] <> '' THEN 
                EDIHeader."Shipment Method Code" := plusString[4];
    
    end;

    procedure GetTransportDetails(InputString : Text[250]);
    begin
    End;

    procedure  GetLineItem(InputString : Text[250]);
    var
        EDIHeader2: record "EDI Header";
        EdiLogg:record EDI_Document_Logg;

    begin
        If NOT EDIHeaderInsert then begin
            If EDIHeader2.Findlast then 
                EDIHeader."Entry No." := EDIHeader2."Entry No." + 1
            else
                EDIHeader."Entry No." := 1; 

            If EDIHeader."Delivery Date" = EmptyDate Then
                EDIHeader."Delivery Date" := EDIHeader."Order Date";
                
            EDIHeader."GLN Owner" := SenderGLN;
            EDIHeader.Insert;
            EDIHeaderInsert := True;

           EdiLogg.InsertEntry(EDIHeader,EDIHeader."EDI message Type",'',EdiLogg."Document Type"::Order,EdiLogg."Document No.",Importfilename);

        End;
        
        EDILine.SetRange("Entry No.",EDIHeader."Entry No.");
        If EDILine.findlast then
            Ediline."Line No." := Ediline."Line No." + 1
        else begin
            EDILine."Entry No." := EDIHeader."Entry No.";
            Ediline."Line No." := 1;
        end;
        EDILine.Init;

        CLEAR(plusString);
        CLEAR(colonString);
        SplitStringPlus(InputString);
        SplitStringColon(plusString[4]);

        IF EVALUATE(EDILine."PO Line No.", plusString[2]) THEN;

        IF colonString[2] = 'EN' THEN BEGIN
            EDILine."PO Item Type" := EDILine."PO Item Type"::EN;
            EDILine."PO Item No." := colonString[1];
        End 
        else IF colonString[2] = 'GTIN' THEN BEGIN
            EDILine."PO Item Type" := EDILine."PO Item Type"::GTIN;
            EDILine."PO Item No." := colonString[1];
        end;

        EDILine.Insert;
    end;

    procedure GetAdditionalProductId(InputString : Text[250]);
    begin
        If (EDILine."PO Item Type" <> EDILine."PO Item Type"::" ") and (EDILine."PO Item No." <> '') Then 
            Exit;

        CLEAR(plusString);
        CLEAR(colonString);
        SplitStringPlus(InputString);
        SplitStringColon(plusString[3]);

        If (colonString[1] <> '') then
            EDILine."Suppliers Model Number" := colonString[1];
    end;

    Procedure GetItemDescription(InputString : Text[250]);
    begin
        CLEAR(plusString);
        CLEAR(colonString);
        SplitStringPlus(InputString);
        SplitStringColon(plusString[4]);

        EDILine."PO Description" := Copystr(colonString[4],1,30);
        If strlen(colonString[4]) > 30 then
           EDILine."PO Description 2" := Copystr(colonString[4],31,30);
        end;

    Procedure GetQuantity(InputString : Text[250]);
    begin
        CLEAR(plusString);
        CLEAR(colonString);
        SplitStringPlus(InputString);
        SplitStringColon(plusString[2]);

        IF  STRPOS(colonString[2],'.') <> 0 THEN
            colonString[2] := CONVERTSTR(colonString[2],'.',',');

        IF  colonString[1] = '21' THEN BEGIN
            EVALUATE(EDILine."PO Quantity",colonString[2]);
        END;
        Ediline.Modify;
    end;

    Procedure GetPriceDetails(InputString : Text[250]);
    Begin
        // Deparse input
        CLEAR(plusString);
        CLEAR(colonString);
        SplitStringPlus(InputString);
        SplitStringColon(plusString[2]);

        IF  STRPOS(colonString[2],'.') <> 0 THEN
            colonString[2] := CONVERTSTR(colonString[2],'.',',');

        If EVALUATE(EDILine."PO Sales Price",colonString[2]) then;

        Ediline.Modify;
    END;

    Procedure GetPCD(InputString : Text[250]);
    begin
        // Deparse input
        CLEAR(plusString);
        CLEAR(colonString);
        SplitStringPlus(InputString);
        SplitStringColon(plusString[2]);

        IF  STRPOS(colonString[2],'.') <> 0 THEN
            colonString[2] := CONVERTSTR(colonString[2],'.',',');
            
        If colonString[1] In ['1','3'] then
            If EVALUATE(EDILine."PO Line Discount",colonString[2]) then;

        Ediline.Modify;
    End;
    
    Procedure GetReference(InputString : Text[250]);
    begin
        CLEAR(plusString);
        CLEAR(colonString);
        SplitStringPlus(InputString);
        SplitStringColon(plusString[2]);

        If copystr(plusString[2],1,2) = 'CT' then begin
            //Kontraktnummer
        end
        Else If copystr(plusString[2],1,2) = 'CR' then  begin
            EDILine."PO Referance" := colonString[2];
            Ediline.Modify;
        end;
     
    end;

    procedure GetPaymentTerms(InputString : Text[250]);
    begin
        CLEAR(plusString);
        CLEAR(colonString);
        SplitStringPlus(InputString);
        SplitStringColon(plusString[2]);
    end;

    Procedure GetUNS();
    begin
    End;

    procedure GetUNZ();
    begin
    end;

    Procedure SplitStringPlus(InputString : Text[250]);
    var
        i:integer;
        index:integer;

    Begin
        i := 1;
        index := 1;
        REPEAT
        i := STRPOS(InputString,FORMAT('+'));
        IF i > 0 THEN BEGIN
            plusString[index] := COPYSTR(InputString,1,i-1);
            index := index + 1;
        END ELSE BEGIN
            plusString[index] := COPYSTR(InputString,1);
        END;
        InputString := COPYSTR(InputString,i+1);
        UNTIL i = 0;
    End;


    procedure SplitStringColon(InputString : Text[250]);
    var
        i:integer;
        index:integer;
    Begin
        i := 1;
        index := 1;
        REPEAT
        i := STRPOS(InputString,FORMAT(':'));
        IF i > 0 THEN BEGIN
            colonString[index] := COPYSTR(InputString,1,i-1);
            index := index + 1;
        END ELSE BEGIN
            colonString[index] := COPYSTR(InputString,1);
        END;
        InputString := COPYSTR(InputString,i+1);
        UNTIL i = 0;
    End;

    Procedure ConvertInDate(InString : Text[12]) OutDate : Date;
    var
        InDate:text[12];

    begin
        InDate := COPYSTR(InString,7,2) + COPYSTR(InString,5,2) + COPYSTR(InString,1,4);
        If EVALUATE(OutDate, InDate) then;
    End;

    Procedure MoveFile(FileName: Text[250];Var EDI_Connection : Record EDI_Connection);
    var
        EdiMgt:Codeunit EDI_Mgt;
        NewFileName:text;
    begin
        NewFileName := EdiMgt.GetFileNameIn(EDI_Connection,True);
        If  NewFileName <> '' then begin
          NewFileName := delchr(NewFileName,'>','\') + '\' + FileMgt.GetFileName(FileName);
          FileMgt.CopyServerFile(FileName,NewFileName,True);
        end;
        FileMgt.DeleteServerFile(FileName);
    end;

    Procedure ImportInvoiceResponce(LineCntMax:integer): Boolean;
    var
        i:Integer;
        LineCnt:integer;
        CurrentRec: Text;
        ByerGLN:Text[50];

    begin
        i := 1;
        For LineCnt := 1 To LineCntMax Do Begin
            Repeat
                i := STRPOS(impData[LineCnt],FORMAT(fnutt));
                IF i > 0 THEN BEGIN
                    CurrentRec := COPYSTR(impData[LineCnt],1,i-1);
                    IF LineCnt > 1 THEN BEGIN
                        IF STRLEN(impData[LineCnt-1]) <> 0 then begin
                            CurrentRec := impData[LineCnt-1] + CurrentRec;
                            impData[LineCnt-1] := '';
                        End;
                    END;
            
                    CASE COPYSTR(CurrentRec,1,3) OF
                        'UCI' : GetUCI_InvResponce(CurrentRec,ByerGLN);
                        'UCM' : GetUCM_InvResponce(CurrentRec);  
                    END;
                END;
                impData[LineCnt] := COPYSTR(impData[LineCnt],i+1);
            Until i = 0;
        End; 
        exit(true);
    end;

    Procedure GetUCI_InvResponce(InputString : Text[250];ByerGLN:text[50]);
    begin
        CLEAR(plusString);

        SplitStringPlus(InputString);
        SplitStringColon(plusString[3]);
        ByerGLN := Colonstring[1];
            
    end;

    Procedure GetUCM_InvResponce(InputString : Text[250]):text[50];
    var
        SalesInvHeader:Record "Sales Invoice Header";
        InvoiceNo:text[20];
        Status :Text[10];

    begin
        CLEAR(plusString);

        SplitStringPlus(InputString);
        InvoiceNo := plusString[2];
        Status := plusString[4];  

        If SalesInvHeader.Get(InvoiceNo) Then begin
           SalesInvHeader."Edi Order Respons" := SalesInvHeader."Edi Order Respons"::Received;
           SalesInvHeader.Modify;
        end;
    end;

    Var
        EDIHeader: Record "EDI Header";
        EDILine: Record "EDI Lines";
        FileMgt: Codeunit "File Management";
        impFile: File;
        TxtInStream: Instream;
        ImpData: array[150] of text[1024];
        Colonstring: array[20] of text[1024];
        plusString: array[20] of text[1024];
        Fnutt: Char;
        EDIHeaderInsert: Boolean;
        SenderGLN:Code[20];
        ImportFileName:text[250];
        EmptyDate:Date;
}


    







    



