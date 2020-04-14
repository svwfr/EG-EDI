pageextension 86246 EDI_Sales_CrMemo_Header extends "Sales Credit Memo"
{

   
    layout
    {
        addafter("E-Invoice")
        {
            field("EDI Order";"EDI Order")
            {
                ApplicationArea = All;
            }
            field("Edi Invoice No.";"Edi Invoice No.")
            {
            }
        }

        //addfirst(FactBoxes)
        //{
        //    part(EDIFactbox;"EDI_FactBox_SalesHeader")
        //    {    
        //        SubPageLink = "No."=FIELD("No."); 
        //    }
        //}

    }

 
}