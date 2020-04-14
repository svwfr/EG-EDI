tableextension 86241 EDI_Customer extends Customer
{
    fields
    {
        field(86230;"Edi Customer Name";Text[50])
        {    
            Caption = 'Edi Customer Name';                  
        }
        field(86231;"Edi Address";Text[50])
        {                      
            Caption = 'Edi Address';
        }
        field(86232;"Edi City";Text[50])
        {                      
            Caption = 'Edi City';
        }
        field(86233;"Edi Post Code";Text[50])
        {                      
            Caption = 'Edi Post Code';
        }
    }
 }
