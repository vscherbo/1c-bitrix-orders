%#template to generate a HTML table from a list of tuples (or list of lists, or tuple of tuples or ...)
<!DOCTYPE HTML>
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

<p>Список заказов за сегодня:</p>

<!-- http://stackoverflow.com/questions/9505256/static-files-not-loaded-in-a-bottle-application-when-the-trailing-slash-is-omitt -->

<table border="0" cellpadding="1" cellspacing="1" align="left" style="width: 100%;">
    <tbody>
        <tr>
            <td valign="top" style="width: 400px;">

            <!-- table class="enjoy-css" border="1" -->
            <table border="1" id="bx_orders_cell" >
            <tr>
            %for h in headers:
                   <td>{{h}}</td>
            %end
            </tr>
            %for master in masters:
              <tr onclick="swapBG(this,'grey', 'white');" >
              %for m in master:
                <td>{{m}}</td>
              %end
              <td style="width: 500px;">
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
            <td align="left">
               <div id='outerdiv'> <!-- style="width:100%; overflow-x:hidden;" -->
                   <p>Реквизиты заказа:</p>
                   <iframe runat="server" frameBorder=0 marginHeight=0 marginWidth=0 name=bx_order_features scrolling=auto
                   src="" width="100%" height=600 
                   id=bx_order_features_iframe></iframe>
               </div>
            </td>
        </tr>
    </tbody>

</table>


<p>Состав заказа:</p>
<iframe title="Состав заказа" runat="server" frameBorder=0 marginHeight=0 marginWidth=0 name=bx_order_items scrolling=auto
 src="" width="100%" height=60%
id=bx_order_items_iframe></iframe>

 </body>
</html>
