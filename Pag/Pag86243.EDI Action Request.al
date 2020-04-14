page 86243 "EDI Action Request"
{
    PageType = List;
    SourceTable = 86239;
    //UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                 field("ID";"Code")
                {
                    ApplicationArea = All;
                }
                field("Descrition";"Description")
                {
                    ApplicationArea = All;
                }
   
            }
        }
    }
}
