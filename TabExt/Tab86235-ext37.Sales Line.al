tableextension 86235 EDI_salesLine extends "Sales Line"
{
    fields
    {
        field(86230;"Edi Order ID";integer)
        {   
            Caption = 'Edi Order ID';                   
        }
        field(86231;"EDI Order Line";Integer)
        {
            Caption = 'Edi Order Line';
        }
        field(86232;"EDI Order Line Changed";text[4])
        {
            Caption = 'Edi Order Line Changed';
        }                  
        field(86233;"EDI Item (Charge)";Boolean)
        {
            Caption = 'Edi Item (Charge)';
        }            
    }
 }