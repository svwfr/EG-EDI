page 86234 "EDI Types"
{
    Caption = 'Edi Types';
    PageType = List;
    SourceTable = 86233;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                 field("ID";"ID")
                {
                    ApplicationArea = All;
                }
                field("Descrition";"Description")
                {
                    ApplicationArea = All;
                }
                field("CU Import Orders";"CU Import Orders")
                {
                    ApplicationArea = All;
                }
                field("CU Export Orders";"CU Export Orders")
                {
                    ApplicationArea = All;
                }
                field("CU Export Invoice";"CU Export Invoice")
                {
                    ApplicationArea = All;
                }
                field("CU Export CrMemo";"CU Export CrMemo")
                {
                }
                field("CU Export PRICAT";"CU Export PRICAT")
                {
                }
                field("CU Export INVRPT";"CU Export INVRPT")
                {
                }
                field("Report Export INVRPT";"Report Export INVRPT")
                {
                }
            }
        }
    }
}
