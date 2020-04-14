tableextension 86243 EDI_salesCrMemoLine extends "Sales Cr.Memo Line"
{
    fields
    {
        field(86230;"Edi Order ID";integer)
        {     
            Caption = 'Edi Order ID';                 
        }
        field(86231;"EDI Order Line";Integer)
        {
            Caption = 'EDI Order Line';
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