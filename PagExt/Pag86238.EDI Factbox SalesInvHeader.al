page 86238 "EDI_FactBox_SalesInvHeader"
{
    PageType = Cardpart;
    SourceTable = "Sales Invoice Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                field("EDI Order";"EDI Order")
                {
                    trigger OnDrillDown();
                    var
                        EdiOrder:Record "EDI Header";
                    begin
                        If "EDI Order" then begin
                            EdiOrder.setrange("Entry No.","Edi Order-ID");
                            Page.run(Page::"EDI Order",Ediorder);
                        End;
                    end;
                }
                field("Edi Adhock Order";"Edi Adhock Order")
                {
                }
                field("EDI Created";"EDI Created")
                {
                }
                field("EDI Order NOT Invoiced";"EDI Order NOT Invoiced")
                {}
             }
        }
    }
}