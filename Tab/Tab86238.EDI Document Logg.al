table 86238 EDI_Document_Logg
{
    DataClassification = ToBeClassified;
    Caption = 'Edi Document Log';

    fields
    {
        field(1;"Entry No.";Integer)
        {
            Caption = 'Entry No.';
        }
        field(2;"Customer Order No.";Code[30]) 
        {
            Caption = 'Customer Order No.';
        }
        field(4;"Edi Message ID";Code[10])
        {
            Caption = 'Edi Message ID';
        }
        field(5;"Created Date-Time";datetime)
        {
            caption = 'Created Date-Time';
        }
        field(6;"Document Type";Option)
        {
            Caption = 'Document Type';
            OptionMembers = "Order", "Orderconfirmation", "Ship", "Invoice", "Crmemo", "PriCat", InvReport;
        }
        field(7;"Document No.";code[20])
        {
            Caption = 'Document No.';
        }
        field(8;"Source Type";Option)
        {
            Caption = 'Source Type';
            OptionMembers = "Customer", "Vendor";
        }
        field(9;"Source No.";code[20])
        {
            Caption = 'Source No.';
        }
        field(10;"Partner GLN";code[20])
        {
            Caption = 'Sender Gln';
        }
        field(11;"EDI Order entry No.";integer)
        {
            Caption = 'EDI Order Entry No.';
        }
        field(12;"Customer Name";text[30])
        {
            Caption = 'Customer Name';
            CalcFormula = lookup(customer.Name Where ("No."= field("Source No.")));
            FieldClass = FlowField;
        }
        field(13;"EDI message Type";Code[30]) 
        {
            caption = 'EDI Message Type';
        }
        field(14;"Sending ID";code[20])
        {
            Caption = 'Sending ID'; 
        }
        field(50;Filename;text[250])
        {
            Caption = 'File Name';
        }
        field(60;"User ID";code[20])
        {
            Caption = 'User Id';
        }
       
    }

    keys
    {
        key(Key1; "Entry NO.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure InsertEntry(Var EdiHeader:Record "EDI Header";EdiMessageType:Code[30];Id:code[20];DocumentType:Integer;DocumentNo:code[20];tFileName:text[250])
    var
        EdiLogg:Record EDI_Document_Logg;

    Begin
        If EdiLogg.FindLast then
            EdiLogg."Entry NO." := EdiLogg."Entry NO." + 1
        else
            Edilogg."Entry NO." := 1;

        EdiLogg.Init;
        EdiLogg."Customer Order No." := EdiHeader."Customer Order No.";
        Edilogg."Partner GLN" := EdiHeader."GLN Owner";
        EdiLogg."Edi Message Type" := EdiMessageType;
        EdiLogg."Edi Message ID" := EdiHeader."Message Ref.";
        EdiLogg."Source Type":= ediLogg."Source Type"::Customer;
        EdiLogg."Source No." := EdiHeader."Sell-to Customer No.";
        EdiLogg."EDI Order entry No." := EdiHeader."Entry No.";

        EdiLogg."Created Date-Time" := CurrentDateTime;
        EdiLogg."Document Type" := DocumentType;
        EdiLogg."Document No." := DocumentNo;
        EdiLogg."EDI message Type" := EdiMessageType;
        EdiLogg.Filename := tFilename;
        EdiLogg."User ID" := UserID;
        EdiLogg."Sending ID" := ID;
        EdiLogg.Insert;
    end;

    procedure UpdateOrderEntry(Var EdiHeader:Record "EDI Header")
    var
        ediLogg:Record EDI_Document_Logg;

    begin
        ediLogg.setrange("EDI Order entry No.",EdiHeader."Entry No.");
        ediLogg.SetRange("Source No.",'');
        if ediLogg.findfirst Then Begin
           ediLogg."Document No." := EdiHeader."SO Order No.";
           EdiLogg."Source No." := EdiHeader."Sell-to Customer No.";
           ediLogg.Modify;
        end;
    end;

}