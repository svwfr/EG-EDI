pageextension 86242 EDI_Sales_Line extends "Sales Order Subform"
{

   
    layout
    {
        addafter("Line No.")
        {
            field("Edi Order ID";"Edi Order ID")
            {
                ApplicationArea = All;
            }
            field("EDI Order Line";"EDI Order Line")
            {
                ApplicationArea = All;
            }
            field("EDI Item (Charge)";"EDI Item (Charge)")
            {}
        }


    }

}