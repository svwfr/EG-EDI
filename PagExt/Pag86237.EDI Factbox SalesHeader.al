page 86237 "EDI_FactBox_SalesHeader"
{
    PageType = Cardpart;
    SourceTable = "Sales Header";

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
                {}
                field("EDI Order NOT Confirmed";"EDI Order NOT Confirmed")
                {
                    trigger OnDrillDown();
                    var
                        SalesHeader:Record "Sales Header";
                        EmptyDate:date;
                    begin
                        SalesHeader.setrange("EDI Order",True);
                        SalesHeader.setRange("EDI Created",EmptyDate);
                        Page.run(Page::"Sales Order List",SalesHeader);
                    End;
                }
                field("EDI Order With Error";"EDI Order With Error")
                {}
            }
        }
    }
}