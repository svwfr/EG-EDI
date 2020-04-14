pageextension 86245 EDI_Customer_Card extends "Customer Card"
{
    layout
    {
        addafter("Address & Contact")
        {
            group("EDI Adress")
            {
                field("Edi Customer Name";"Edi Customer Name")
                {
                    ApplicationArea = All;
                }
                field("Edi Address";"Edi Address")
                {
                    ApplicationArea = All;
                }
                field("Edi City";"Edi City")
                {
                    ApplicationArea = All;
                }
                field("Edi Post Code";"Edi Post Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}