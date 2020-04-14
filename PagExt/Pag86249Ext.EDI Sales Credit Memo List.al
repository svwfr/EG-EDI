pageextension 86249 EDI_SalesCrMemo_List extends "Sales Credit Memos"
{

   
    layout
    {
       addafter("Status") 
       {
           field("EDI Order";"EDI Order")
           {}
           field("EDI Created";"EDI Created")
           {}
       }

    }

}