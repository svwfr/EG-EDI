table 86240 EDI_Setup
{
    DataClassification = ToBeClassified;
    Caption = 'EDI Setup';
    


    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption ='Code';
        }

        field(3; "Item (Charge)"; Code[20])
        {
            Caption = 'Item (Charge)';
            TableRelation = Item;
        }      
        field(4;"Automatic EDI Shipment";Boolean) 
        {
            Caption = 'Automatic EDI Shipment';
        }
        field(5;"Automatic EDI Invoice";Boolean) 
        {
            Caption = 'Automatic EDI Invoice';
        }
        field(6;"UseLastOrderConnection(Adhock)";Boolean)
        {
            Caption = 'Use Last Order Connection (Adhock)';
        }
        field(40; "File Path in"; Text[250])
        {
            Caption = 'File Path In';
        }
        field(41; "File Path Out"; Text[250])
        {
            Caption = 'File Path Out';
        }
        field(42; "File Path Archive Inn"; Text[250])
        {
            Caption = 'File Path Archive In';
        }
        field(43; "File Path Archive Out"; Text[250])
        {
            Caption = 'File Path Archive Out';
        }
        field(50; "Filter Incomming Orders"; Text[250])
        {
            Caption = 'Filter Incoming Orders';
        }
        field(51; "File Name Orders"; Text[250])
        {
            Caption = 'File Name Orders';
        }
        field(52; "File Name Shipment"; Text[250])
        {
            Caption = 'File Name Shipment';
        }
        field(53; "File Name Invoice"; Text[250])
        {
            Caption = 'File Name Invoice';
        }
        field(54; "File Name Credit Memo"; Text[250])
        {
            Caption = 'File Name Cr. Memo';
        }
        field(55; "File Name INVRPT"; Text[250])
        {
            Caption = 'File Name InvRpt';
        }
        field(56; "File Name Pricat"; Text[250])
        {
            Caption = 'File Name Pricat';
        }
    }

    keys
    {
        key(Key1; "Code")
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
    begin
    end;

    trigger OnRename();
    begin
    end;

}