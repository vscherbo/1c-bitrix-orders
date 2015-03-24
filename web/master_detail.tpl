%#template to generate a HTML table from a list of tuples (or list of lists, or tuple of tuples or ...)
<p>Список заказов за сегодня:</p>
<table border="1">
%for master in masters:
  <tr>
  %for m in master:
    <td>{{m}}</td>
  %end
  <!-- <td><p><input name="btn_details" type="button" value="Состав"></td> -->
  <td>
      <!--
      <form action="bx_order_items">
        <input type="hidden" name="master_id" value="{{master[0]}}" />
        <button type="submit">Состав</button>
      </form>
      -->
      <form action="" method="GET">
        <input type="hidden" name="master_id" value="{{master[0]}}" />
        <input type="button" value=" Состав " onclick="document.getElementById('bx_order_items_iframe').src='http://localhost:8080/bx_order_items?master_id='+form.master_id.value+'';"/>
      </form>

  </td>
  </tr>
%end
</table>

<table border="1">

<iframe runat="server" frameBorder=0 marginHeight=0 marginWidth=0 name=login scrolling=auto
 src="" width="100%" height=425
id=bx_order_items_iframe></iframe>

</table>

