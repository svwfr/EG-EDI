tableextension 86242 EDI_salesCrMemoHeader extends "Sales Cr.Memo Header"
{
    fields
    {
        field(86230;"Edi Order-ID";integer)
        {  
            Caption = 'Edi Order ID';                    
        }
        field(86232;"EDI Created";Date)
        {
            Caption = 'Edi Created';
        }        
        field(86233;"EDI Order";Boolean)
        {
            Caption = 'Edi Order';
        }     
        field(86234;"EDI Filcounter";Code[10])
        {
            Caption = 'Edi Filcounter';
        }
        field(86235;"Edi Adhock Order";Boolean)
        {
            Caption = 'Edi Adhock Order';
        }
        field(86236;"EDI Order NOT Invoiced";Integer)
        {
            Caption = 'Edi Order Not Invoiced';
            CalcFormula = Count("sales Invoice header" Where ("EDI Order" = Const(true),"EDI Created" = filter('')));

            FieldClass = FlowField;
        }
        field(86237;"Edi Order Respons";Option)
        {
            Caption = 'Edi Order Respons';
            OptionMembers = " ","Received", "Accepted", "Not Accepted" ;
        }
        field(86238;"Edi Invoice No.";Code[20])
        {
            Caption = 'Edi Invoice No.';
        }
    }
 }