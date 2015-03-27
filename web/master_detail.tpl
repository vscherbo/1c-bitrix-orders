%#template to generate a HTML table from a list of tuples (or list of lists, or tuple of tuples or ...)
<DOCTYPE HTML>
<html>
 <head>
  <meta charset="utf-8">
  <title>Заказы с сайта</title>
  <!-- link rel="stylesheet" href="static/bxorders.css" -->
  <link rel="stylesheet" type="text/css" href="{{ get_url('static', filename='bxorders.css') }}" >

<script type="text/javascript" language="javascript">
function swapBG(el, BG1, BG2) {

    var rows = document.getElementById("bx_orders_cell").tBodies[0].getElementsByTagName("tr");
    for (var i = 0; i < rows.length; i++) {
        rows[i].style.backgroundColor = 'white';
    }
    el.style.backgroundColor = (el.style.backgroundColor == BG1) ? BG2 : BG1;
}

</script>

 </head>
 <body>


<!-- http://stackoverflow.com/questions/9505256/static-files-not-loaded-in-a-bottle-application-when-the-trailing-slash-is-omitt -->

<table border="1" cellpadding="1" cellspacing="1" align="left" width="100%" height="100%">
    <thead> 
      <tr>
        <td>
           <h3><p align="middle">Список заказов </p></h3>
        </td>
        <td>
           <h3><p align="middle">Свойства заказа</p></h3>
        </td>
      </tr>
    </thead>
    <tbody>
        <tr>
            <td valign="top" width="50%" style="overflow:auto;">

            <!-- table class="enjoy-css" border="1" -->
            <table border="1" width="100%" id="bx_orders_cell">
            <tr> <! -- строка заголовков таблицы заказов -->
            %for h in headers:
                   <td><b>{{h}}</b></td>
            %end
            </tr>
            %for master in rows:
              <tr onclick="swapBG(this,'grey', 'white');" >
              %for m in master:
                <td>{{m}}</td>
              %end
              <td> <!-- style="width: 500px;" -->
                  <form action="" method="GET">
                    <input type="hidden" name="master_id" value="{{master[0]}}" />
                    <input type="button" value=" Состав " 
                     onclick="
document.getElementById('bx_order_items_iframe').src='http://localhost:8080/bx_order_items?master_id='+form.master_id.value ;
document.getElementById('bx_order_features_iframe').src='http://localhost:8080/bx_order_features?master_id='+form.master_id.value;
"
                    />
                  </form>
              </td>
              </tr>
            %end
            </table>

            </td>
            <td valign="top" align="left">
               <div id='outerdiv' style="width:100%; height:100%; overflow-x:hidden;">
                   <iframe runat="server" width="100%" height="100%" frameBorder=0 marginHeight=0 marginWidth=0 name=bx_order_features scrolling=auto
                   src=""
                   id=bx_order_features_iframe></iframe>
               </div>
            </td>
        </tr>
       
        <tr>
           <td valign="top" align="left">
               <div id='outerdiv'> <!-- style="width:100%; overflow-x:hidden;" -->
               <h3><p>Состав заказа</p></h3>
                    <iframe title="Состав заказа" runat="server" frameBorder=0 marginHeight=0 marginWidth=0 name=bx_order_items scrolling=auto
                             src="" width="100%" height=60% id=bx_order_items_iframe></iframe>
               </div>
           </td>
        </tr>

    </tbody>

</table>


 </body>
</html>
