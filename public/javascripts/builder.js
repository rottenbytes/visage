window.addEvent('domready', function () {
        $("#sortable").sortable({
            placeholder: 'ui-state-highlight'
        });
        $("#sortable").disableSelection();
        
        $("#metric").live('dblclick' , function() {
            $(this).remove();
            false;
        });

        $('#btnAdd').click(function() {
           var $sortable = $("#sortable");
           
           var to_add = $('#Hosts').val() +" / " + $('#Metrics').val()

           $sortable.children().eq(0).clone().text( to_add ).appendTo($sortable);
        });

        $('#btnSave').click(function() {
            var $list = $("li");
            var metrics = new Hash();
            
            
            $list.each(function(index) {            
                txt = $(this).text();
                data=txt.split(" / ");
                if (metrics.has(data[0]) == false) {
                    metrics.set(data[0], []);
                }
                t=metrics.get(data[0]);
                t.include(data[1]);
                metrics.set(data[0],t);
            });
            
            $.post("/builder/save", metrics.toQueryString());
        });
});
