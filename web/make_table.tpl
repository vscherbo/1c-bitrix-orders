%#template to generate a HTML table from a list of tuples (or list of lists, or tuple of tuples or ...)
<br>
<!-- p>Детали:</p -->
<div class="enjoy-css">
<table title="Таблица" border="1">
%for row in rows:
  <tr>
  %for r in row:
    <td>{{r}}</td>
  %end
  </tr>
%end
</table>
</div>