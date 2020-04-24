table 86231 "EDI Header"
 {

    DataClassification = ToBeClassified;
    Caption = 'Edi Header';
    LookupPageId = "EDI Order";
    DrillDownPageId = "EDI Order";
   

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Message Ref."; Code[20])
        {
            Caption = 'Message Ref.';
        }
        field(3; "Message Date"; Text[50])
        {
            Caption = 'Message date';
        }
        field(4; "Customer Order No."; Text[30])
        {
            Caption = 'Customer Order No.';
        }
        field(5; "Order Date" ; Date)
        {
            Caption = 'Order Date';
        }
        field(6; "Delivery Date" ; Date)
        {
            Caption = 'Delivery Date';
        }
        field(7; "Test Order";Boolean)
        {
            Caption = 'Test order';
        }
        field(10; "Order Type";Code[20])
        {
            Caption = 'Order Type';
        }   
        field(11; "Order Instruction";Text[30])
        {
            Caption = 'Order Instruction';
        }                         
        field(12; "Payment Terms Code";Code[20])
        {
            Caption = 'Payment Terms Code';
        }  
        field(13; "Shipment Method Code";Code[20])
        {
            Caption = 'Shipment Method Code';
        }
        field(14; "Currency Code";Code[20])
        {
            Caption = 'Currency Code';
        }  
        field(19; "GLN Owner";Code[30])
        {
            Caption = 'GLN Sender';
        }
        field(20; "GLN SU";Code[30])
        {
            Caption = 'GLN SU';
        }
        field(21; "GLN BY";Code[30])
        {
            Caption = 'GLN BY';
        }
        field(22; "GLN DP";Code[30])
        {
            Caption = 'GLN DP';
        }
        field(23; "GLN IV";Code[30])
        {
            Caption = 'GLN IV';
        }
        field(50; "SO Order No.";Code[20])
        {
            Caption = 'Sales Order No.';
        }
        field(51; "Sell-to Customer No.";Code[20])
        {
            Caption = 'Sell-to Customer No.';
        }  
        field(52; "Bill-to Customer No.";Code[20])
        {
            Caption = 'Bill-to Customer No.';
        }       
        field(53; "Ship-to Code";Code[20])
        {
            Caption = 'Ship-to Code';
        }    
        field(54; "Sell-to Customer Name";text[50])
        {
            Caption = 'Sell-to Customer Name';
            CalcFormula = lookup(customer.Name Where ("No."= field("Sell-to Customer No.")));
            FieldClass = FlowField; 
        }
        field(55;"Adhock Order";Boolean)
        {
            Caption = 'Adhock Order';
        }
        field(56;"Document Type";Option)
        {
            Caption = 'Document Type';
            OptionMembers = "Orders",,,"Cr.Memo"; 
        }
        field(57;"Credited Invoice No.";Code[20])
        {
            Caption = 'Credited Invoice No.';
        }
        field(58;"Applies-to ID";Code[20])
        {
            Caption = 'Applies-to ID';
        }
        field(60; "Order send";Date)
        {
            Caption = 'Order Send';
        }
         field(61; "Shipment send";Date)
        {
            Caption = 'Shipment Send';
        }
        field(62; "Invoice send";date)
        {
            Caption = 'Invoice Send';
        }
        field(90; "Import Error";Boolean)
        {
            Caption = 'Import Error';
        }
        field(91; "Import Message";Text[250])
        {
            Caption = 'Import Message';
        }    
        field(100;"EDI message Type";text[30]) 
        {
            Caption = 'Edi Message Type';
        }   
        field(101;"EDI File Name";text[80]) 
        {
            Caption = 'Edi File Name';
        }   
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }


    fieldgroups
    {
    }
   

    trigger OnInsert();
    begin
    end;

    trigger OnModify();
    begin
    end;

    trigger OnDelete();
    Var
        EDILine: Record "EDI Lines";
    begin
        EDILine.SetRange("Entry No.","Entry No.");
        EDILine.Deleteall(true);
    end;

    trigger OnRename();
    begin
    end;

}